function [data, metadata] = readtoml(filename, options)
% READTOML Read TOML file and return MATLAB struct
%
%   data = readtoml(filename) reads a TOML file and returns a struct.
%
%   [data, metadata] = readtoml(filename) also returns metadata including
%   key ordering information for round-trip support.
%
%   [data, metadata] = readtoml(filename, Name=Value) specifies options:
%       DatetimeType - How to represent dates ('datetime' | 'string')
%                      Default: 'datetime'
%
% Examples:
%   Read as struct
%       config = readtoml('config.toml');
%       dbServer = config.database.server;
%
%   Read with metadata for round-trip
%       [config, meta] = readtoml('config.toml');
%       writetoml('output.toml', config, 'Metadata', meta);

    arguments
        filename (1,1) string {mustBeFile}
        options.DatetimeType (1,1) string ...
            {mustBeMember(options.DatetimeType, ["datetime", "string"])} = "datetime"
    end

    % Read file contents
    fileContent = readFileAsString(filename);

    % Parse TOML content
    [data, metadata] = parseToml(fileContent, options.DatetimeType);
end

function content = readFileAsString(filename)
% Read file and return as string array (one element per line)
    fid = fopen(filename, 'r', 'n', 'UTF-8');
    if fid == -1
        error('readtoml:FileOpenError', 'Cannot open file: %s', filename);
    end

    try
        content = string(fread(fid, '*char')');
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    fclose(fid);
end

function [data, metadata] = parseToml(content, datetimeType)
% Parse TOML content string and return struct with metadata

    % Initialize root struct and metadata
    data = struct();
    metadata = configureDictionary("string", "cell");
    currentTable = data;
    currentTablePath = "";

    % Split into lines
    lines = splitlines(content);

    % Track array of tables
    arrayOfTables = dictionary();

    for i = 1:numel(lines)
        line = strtrim(lines(i));

        % Skip empty lines and comments
        if strlength(line) == 0 || startsWith(line, "#")
            continue;
        end

        % Check for table headers
        if startsWith(line, "[[") && endsWith(line, "]]")
            % Array of tables
            tableName = extractBetween(line, 3, strlength(line) - 2);
            tableName = strtrim(tableName);
            [data, currentTable, currentTablePath, metadata] = handleArrayOfTables(data, tableName, arrayOfTables, metadata);

        elseif startsWith(line, "[") && endsWith(line, "]")
            % Standard table
            tableName = extractBetween(line, 2, strlength(line) - 1);
            tableName = strtrim(tableName);
            [data, currentTable, currentTablePath, metadata] = handleTable(data, tableName, metadata);

        else
            % Key-value pair
            [data, currentTable, metadata] = parseKeyValue(data, currentTable, currentTablePath, line, datetimeType, metadata);
        end
    end
end

function [rootData, tableRef, tablePath, metadata] = handleTable(rootData, tableName, metadata)
% Handle [table] syntax

    keys = split(tableName, ".");
    tablePath = tableName;

    % Build the nested structure
    [rootData, metadata] = ensureStructPath(rootData, keys, "", metadata);

    % Get reference to the table
    tableRef = getStructPath(rootData, tablePath);
end

function [s, metadata] = ensureStructPath(s, pathKeys, currentPath, metadata)
% Ensure a struct path exists, creating it if necessary
    if isempty(pathKeys)
        return;
    end

    key = strtrim(pathKeys(1));
    fieldName = matlab.lang.makeValidName(key);

    if ~isfield(s, fieldName)
        metadata = trackKeyOrder(metadata, currentPath, key);
        s.(fieldName) = struct();
    end

    % Build new current path
    if strlength(currentPath) == 0
        newPath = key;
    else
        newPath = currentPath + "." + key;
    end

    % Recursively ensure rest of path
    if numel(pathKeys) > 1
        [s.(fieldName), metadata] = ensureStructPath(s.(fieldName), pathKeys(2:end), newPath, metadata);
    end
end

function [rootData, tableRef, tablePath, metadata] = handleArrayOfTables(rootData, tableName, arrayOfTables, metadata)
% Handle [[array.of.tables]] syntax

    keys = split(tableName, ".");
    tablePath = tableName;

    % Ensure parent path exists
    if numel(keys) > 1
        [rootData, metadata] = ensureStructPath(rootData, keys(1:end-1), "", metadata);
    end

    % Get parent struct
    if numel(keys) > 1
        parentPath = join(keys(1:end-1), ".");
        parentStruct = getStructPath(rootData, parentPath);
        currentPath = parentPath;
    else
        parentStruct = rootData;
        currentPath = "";
    end

    % Handle array element
    lastKey = strtrim(keys(end));
    fieldName = matlab.lang.makeValidName(lastKey);

    if ~isfield(parentStruct, fieldName)
        % Create new array with first element
        newStruct = struct();
        parentStruct.(fieldName) = newStruct;
        metadata = trackKeyOrder(metadata, currentPath, lastKey);
        arrayOfTables(tableName) = 1;
        tableRef = newStruct;
    else
        % Check if this is an array of tables
        if isKey(arrayOfTables, tableName)
            % Append new struct to array
            currentArray = parentStruct.(fieldName);
            newStruct = struct();
            if isstruct(currentArray)
                parentStruct.(fieldName) = [currentArray, newStruct];
            else
                error('readtoml:InvalidArrayOfTables', ...
                    'Key "%s" is not a struct array', lastKey);
            end
            arrayOfTables(tableName) = arrayOfTables(tableName) + 1;
            tableRef = newStruct;
        else
            error('readtoml:InvalidArrayOfTables', ...
                'Key "%s" already exists and is not an array of tables', lastKey);
        end
    end

    % Update root with modified parent
    if numel(keys) > 1
        rootData = updateStructPath(rootData, keys(1:end-1), parentStruct, 0);
    else
        rootData = parentStruct;
    end
end

function [rootData, tableRef, metadata] = parseKeyValue(rootData, tableRef, tablePath, line, datetimeType, metadata)
% Parse key = value line

    % Find first '=' not in quotes
    eqPos = findUnquotedChar(line, '=');

    if eqPos == 0
        error('readtoml:InvalidSyntax', 'Invalid key-value syntax: %s', line);
    end

    keyPart = strtrim(extractBefore(line, eqPos));
    valuePart = strtrim(extractAfter(line, eqPos));

    % Remove quotes from key if present
    key = cleanKey(keyPart);

    % Parse value
    value = parseValue(valuePart, datetimeType);

    % Handle dotted keys (e.g., a.b.c = value)
    if contains(keyPart, ".")
        keys = split(keyPart, ".");
        currentStruct = tableRef;
        currentPath = tablePath;

        for i = 1:numel(keys) - 1
            k = cleanKey(strtrim(keys(i)));
            fieldName = matlab.lang.makeValidName(k);

            if ~isfield(currentStruct, fieldName)
                metadata = trackKeyOrder(metadata, currentPath, k);
                currentStruct.(fieldName) = struct();
            end
            currentStruct = currentStruct.(fieldName);

            % Update path
            if strlength(currentPath) == 0
                currentPath = k;
            else
                currentPath = currentPath + "." + k;
            end
        end

        finalKey = cleanKey(strtrim(keys(end)));
        fieldName = matlab.lang.makeValidName(finalKey);
        metadata = trackKeyOrder(metadata, currentPath, finalKey);
        currentStruct.(fieldName) = value;

        % Update tableRef in rootData
        if strlength(tablePath) == 0
            rootData = updateStructPath(rootData, split(keyPart, "."), currentStruct, numel(keys) - 1);
        else
            rootData = updateStructPath(rootData, [split(tablePath, "."); split(keyPart, ".")], currentStruct, numel(keys) - 1);
        end
        tableRef = getStructPath(rootData, tablePath);
    else
        fieldName = matlab.lang.makeValidName(key);
        metadata = trackKeyOrder(metadata, tablePath, key);
        tableRef.(fieldName) = value;

        % Update in rootData
        if strlength(tablePath) == 0
            rootData = tableRef;
        else
            pathKeys = split(tablePath, ".");
            rootData = setStructPath(rootData, pathKeys, tableRef);
        end
    end
end

function s = setStructPath(s, pathKeys, value)
% Set a value at a specific path in a struct
    if numel(pathKeys) == 1
        fieldName = matlab.lang.makeValidName(pathKeys(1));
        s.(fieldName) = value;
    else
        fieldName = matlab.lang.makeValidName(pathKeys(1));
        if isfield(s, fieldName)
            s.(fieldName) = setStructPath(s.(fieldName), pathKeys(2:end), value);
        else
            s.(fieldName) = setStructPath(struct(), pathKeys(2:end), value);
        end
    end
end

function metadata = trackKeyOrder(metadata, path, key)
% Track key order in metadata
    if isKey(metadata, path)
        currentOrder = metadata{path};
        metadata{path} = {[currentOrder{1}, key]};
    else
        metadata{path} = {string(key)};
    end
end

function s = updateStructPath(s, pathKeys, value, levelsFromEnd)
% Update struct at given path
    if levelsFromEnd == 0
        s = value;
        return;
    end

    fieldName = matlab.lang.makeValidName(pathKeys(1));
    if numel(pathKeys) == 1
        s.(fieldName) = value;
    else
        if isfield(s, fieldName)
            s.(fieldName) = updateStructPath(s.(fieldName), pathKeys(2:end), value, levelsFromEnd - 1);
        else
            s.(fieldName) = updateStructPath(struct(), pathKeys(2:end), value, levelsFromEnd - 1);
        end
    end
end

function tableRef = getStructPath(s, tablePath)
% Get struct reference at given path
    if strlength(tablePath) == 0
        tableRef = s;
        return;
    end

    keys = split(tablePath, ".");
    tableRef = s;

    for i = 1:numel(keys)
        fieldName = matlab.lang.makeValidName(keys(i));
        tableRef = tableRef.(fieldName);
    end
end

function pos = findUnquotedChar(str, char)
% Find position of character not inside quotes

    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(str)
        c = extractBetween(str, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
        elseif c == char && ~inQuotes
            pos = i;
            return;
        end
    end

    pos = 0;
end

function key = cleanKey(keyStr)
% Remove quotes from key if present

    keyStr = strtrim(keyStr);

    if (startsWith(keyStr, '"') && endsWith(keyStr, '"')) || ...
       (startsWith(keyStr, "'") && endsWith(keyStr, "'"))
        key = extractBetween(keyStr, 2, strlength(keyStr) - 1);
    else
        key = keyStr;
    end
end

function value = parseValue(valueStr, datetimeType)
% Parse TOML value from string

    valueStr = strtrim(valueStr);

    % Remove inline comments
    valueStr = removeInlineComment(valueStr);

    % Arrays
    if startsWith(valueStr, "[")
        value = parseArray(valueStr, datetimeType);

    % Inline tables
    elseif startsWith(valueStr, "{")
        value = parseInlineTable(valueStr, datetimeType);

    % Strings
    elseif startsWith(valueStr, '"') || startsWith(valueStr, "'")
        value = parseString(valueStr);

    % Booleans
    elseif valueStr == "true"
        value = true;
    elseif valueStr == "false"
        value = false;

    % DateTime
    elseif isDateTime(valueStr)
        if datetimeType == "datetime"
            value = parseDatetime(valueStr);
        else
            value = valueStr;
        end

    % Numbers
    else
        value = parseNumber(valueStr);
    end
end

function valueStr = removeInlineComment(valueStr)
% Remove inline comments from value string

    % Find # not in quotes
    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(valueStr)
        c = extractBetween(valueStr, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
        elseif c == "#" && ~inQuotes
            valueStr = extractBefore(valueStr, i);
            return;
        end
    end
end

function arr = parseArray(arrayStr, datetimeType)
% Parse TOML array

    arrayStr = strtrim(arrayStr);

    % Remove [ and ]
    if ~startsWith(arrayStr, "[") || ~endsWith(arrayStr, "]")
        error('readtoml:InvalidArray', 'Invalid array syntax');
    end

    content = extractBetween(arrayStr, 2, strlength(arrayStr) - 1);
    content = strtrim(content);

    if strlength(content) == 0
        arr = [];
        return;
    end

    % Split by commas (respecting nesting)
    elements = splitArrayElements(content);

    % Parse each element
    parsedElements = cell(size(elements));
    for i = 1:numel(elements)
        parsedElements{i} = parseValue(elements(i), datetimeType);
    end

    % Check type homogeneity
    if numel(parsedElements) > 0
        firstType = class(parsedElements{1});
        for i = 2:numel(parsedElements)
            if ~strcmp(class(parsedElements{i}), firstType)
                error('readtoml:MixedTypeArray', ...
                    'Arrays must contain homogeneous types. Found %s and %s.', ...
                    firstType, class(parsedElements{i}));
            end
        end

        % Convert to array
        arr = [parsedElements{:}];
    else
        arr = [];
    end
end

function elements = splitArrayElements(content)
% Split array content by commas, respecting nesting

    elements = string.empty;
    currentElement = "";
    depth = 0;
    inQuotes = false;
    quoteChar = '';

    for i = 1:strlength(content)
        c = extractBetween(content, i, i);

        if (c == '"' || c == "'") && ~inQuotes
            inQuotes = true;
            quoteChar = c;
            currentElement = currentElement + c;
        elseif c == quoteChar && inQuotes
            inQuotes = false;
            currentElement = currentElement + c;
        elseif ~inQuotes && (c == "[" || c == "{")
            depth = depth + 1;
            currentElement = currentElement + c;
        elseif ~inQuotes && (c == "]" || c == "}")
            depth = depth - 1;
            currentElement = currentElement + c;
        elseif c == "," && depth == 0 && ~inQuotes
            elements = [elements, strtrim(currentElement)];
            currentElement = "";
        else
            currentElement = currentElement + c;
        end
    end

    if strlength(currentElement) > 0
        elements = [elements, strtrim(currentElement)];
    end
end

function tbl = parseInlineTable(tableStr, datetimeType)
% Parse inline table {key = value, ...}

    tableStr = strtrim(tableStr);

    if ~startsWith(tableStr, "{") || ~endsWith(tableStr, "}")
        error('readtoml:InvalidInlineTable', 'Invalid inline table syntax');
    end

    content = extractBetween(tableStr, 2, strlength(tableStr) - 1);
    content = strtrim(content);

    tbl = struct();

    if strlength(content) == 0
        return;
    end

    % Split by commas
    pairs = splitArrayElements(content);

    for i = 1:numel(pairs)
        pair = pairs(i);
        eqPos = findUnquotedChar(pair, '=');

        if eqPos == 0
            error('readtoml:InvalidInlineTable', 'Invalid key-value pair in inline table');
        end

        key = cleanKey(strtrim(extractBefore(pair, eqPos)));
        valuePart = strtrim(extractAfter(pair, eqPos));
        value = parseValue(valuePart, datetimeType);

        fieldName = matlab.lang.makeValidName(key);
        tbl.(fieldName) = value;
    end
end

function str = parseString(strValue)
% Parse TOML string

    strValue = strtrim(strValue);

    % Multi-line strings
    if startsWith(strValue, '"""') || startsWith(strValue, "'''")
        error('readtoml:NotImplemented', 'Multi-line strings not yet implemented');
    end

    % Regular strings
    if startsWith(strValue, '"') && endsWith(strValue, '"')
        str = extractBetween(strValue, 2, strlength(strValue) - 1);
        str = unescapeString(str);
    elseif startsWith(strValue, "'") && endsWith(strValue, "'")
        % Literal string (no escaping)
        str = extractBetween(strValue, 2, strlength(strValue) - 1);
    else
        error('readtoml:InvalidString', 'Invalid string syntax');
    end
end

function str = unescapeString(str)
% Unescape string escape sequences

    str = strrep(str, '\"', '"');
    str = strrep(str, '\\', '\');
    str = strrep(str, '\n', newline);
    str = strrep(str, '\t', sprintf('\t'));
    str = strrep(str, '\r', sprintf('\r'));
end

function tf = isDateTime(str)
% Check if string is a datetime value

    % Simple check for ISO 8601 format
    pattern = '\d{4}-\d{2}-\d{2}';
    tf = ~isempty(regexp(str, pattern, 'once'));
end

function dt = parseDatetime(str)
% Parse datetime string

    try
        dt = datetime(str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssXXX', 'TimeZone', 'UTC');
    catch
        try
            dt = datetime(str, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
        catch
            try
                dt = datetime(str, 'InputFormat', 'yyyy-MM-dd');
            catch
                try
                    dt = datetime(str, 'InputFormat', 'HH:mm:ss');
                catch
                    error('readtoml:InvalidDatetime', 'Cannot parse datetime: %s', str);
                end
            end
        end
    end
end

function num = parseNumber(numStr)
% Parse TOML number (integer or float)

    numStr = strtrim(numStr);

    % Remove underscores (TOML allows _ in numbers)
    numStr = strrep(numStr, '_', '');

    % Hex, octal, binary
    if startsWith(numStr, '0x')
        num = hex2dec(extractAfter(numStr, 2));
    elseif startsWith(numStr, '0o')
        num = base2dec(extractAfter(numStr, 2), 8);
    elseif startsWith(numStr, '0b')
        num = bin2dec(extractAfter(numStr, 2));
    else
        % Regular number
        num = str2double(numStr);

        if isnan(num)
            error('readtoml:InvalidNumber', 'Invalid number: %s', numStr);
        end
    end
end
