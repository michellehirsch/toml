function writetoml(filename, data, options)
% WRITETOML Write MATLAB struct to TOML file
%
%   writetoml(filename, data) writes struct data to a TOML file.
%
%   writetoml(filename, data, Name=Value) specifies options:
%       OverWrite - Allow overwriting existing file (true | false)
%                   Default: false
%       Metadata  - Metadata dictionary containing key ordering information
%                   for round-trip support. Default: []
%
% Examples:
%   Write struct to TOML
%       config.title = "My Config";
%       config.database.server = "192.168.1.1";
%       config.database.port = 5432;
%       writetoml('config.toml', config);
%
%   Write with metadata for round-trip
%       [config, meta] = readtoml('input.toml');
%       config.database.port = 3306;  % Modify data
%       writetoml('output.toml', config, 'Metadata', meta, 'OverWrite', true);

    arguments
        filename (1,1) string
        data {mustBeA(data, "struct")}
        options.OverWrite (1,1) logical = false
        options.Metadata = []
    end

    % Check if file exists
    if isfile(filename) && ~options.OverWrite
        error('writetoml:FileExists', ...
            'File already exists: %s. Use OverWrite=true to overwrite.', filename);
    end

    % Validate metadata if provided
    if ~isempty(options.Metadata) && ~isa(options.Metadata, 'dictionary')
        error('writetoml:InvalidMetadata', 'Metadata must be a dictionary');
    end

    % Generate TOML content
    tomlContent = serializeToml(data, options.Metadata);

    % Write to file
    fid = fopen(filename, 'w', 'n', 'UTF-8');
    if fid == -1
        error('writetoml:FileOpenError', 'Cannot open file for writing: %s', filename);
    end

    try
        fprintf(fid, '%s', tomlContent);
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    fclose(fid);
end

function tomlStr = serializeToml(data, metadata)
% Serialize struct to TOML string

    tomlStr = "";

    % Get key order from metadata or use struct field order
    if ~isempty(metadata) && isKey(metadata, "")
        allKeys = metadata{""}{1};
    else
        allKeys = string(fieldnames(data));
    end

    % Separate root key-values from tables
    rootPairs = string.empty;
    tables = string.empty;

    for i = 1:numel(allKeys)
        key = allKeys(i);
        fieldName = matlab.lang.makeValidName(key);

        if ~isfield(data, fieldName)
            continue;  % Skip if key from metadata doesn't exist in data
        end

        value = data.(fieldName);

        if isstruct(value) && numel(value) == 1
            tables = [tables, key];
        else
            rootPairs = [rootPairs, key];
        end
    end

    % Write root key-value pairs first
    for i = 1:numel(rootPairs)
        key = rootPairs(i);
        fieldName = matlab.lang.makeValidName(key);
        value = data.(fieldName);
        tomlStr = tomlStr + serializeKeyValue(key, value) + newline;
    end

    if numel(rootPairs) > 0 && numel(tables) > 0
        tomlStr = tomlStr + newline;
    end

    % Write tables
    for i = 1:numel(tables)
        key = tables(i);
        fieldName = matlab.lang.makeValidName(key);
        value = data.(fieldName);
        tomlStr = tomlStr + serializeTable(key, value, "", metadata);

        if i < numel(tables)
            tomlStr = tomlStr + newline;
        end
    end
end

function tomlStr = serializeTable(tableName, tableData, prefix, metadata)
% Serialize table with given prefix

    tomlStr = "";

    % Build full table name
    if strlength(prefix) > 0
        fullName = prefix + "." + tableName;
    else
        fullName = tableName;
    end

    % Check if this is an array of structs (array of tables)
    if isstruct(tableData) && numel(tableData) > 1
        % Array of tables
        for i = 1:numel(tableData)
            tomlStr = tomlStr + "[[" + fullName + "]]" + newline;
            tomlStr = tomlStr + serializeStruct(tableData(i), fullName, metadata);
            if i < numel(tableData)
                tomlStr = tomlStr + newline;
            end
        end
    elseif isstruct(tableData)
        % Regular table
        % Get key order from metadata or use struct field order
        if ~isempty(metadata) && isKey(metadata, fullName)
            allKeys = metadata{fullName}{1};
        else
            allKeys = string(fieldnames(tableData));
        end

        % Separate key-values from subtables
        pairs = string.empty;
        subtables = string.empty;

        for i = 1:numel(allKeys)
            key = allKeys(i);
            fieldName = matlab.lang.makeValidName(key);

            if ~isfield(tableData, fieldName)
                continue;  % Skip if key from metadata doesn't exist
            end

            value = tableData.(fieldName);

            if isstruct(value)
                subtables = [subtables, key];
            else
                pairs = [pairs, key];
            end
        end

        % Only write table header if there are key-value pairs
        if numel(pairs) > 0
            tomlStr = tomlStr + "[" + fullName + "]" + newline;

            for i = 1:numel(pairs)
                key = pairs(i);
                fieldName = matlab.lang.makeValidName(key);
                value = tableData.(fieldName);
                tomlStr = tomlStr + serializeKeyValue(key, value) + newline;
            end

            if numel(subtables) > 0
                tomlStr = tomlStr + newline;
            end
        end

        % Write subtables
        for i = 1:numel(subtables)
            key = subtables(i);
            fieldName = matlab.lang.makeValidName(key);
            value = tableData.(fieldName);
            tomlStr = tomlStr + serializeTable(key, value, fullName, metadata);

            if i < numel(subtables)
                tomlStr = tomlStr + newline;
            end
        end
    end
end

function tomlStr = serializeStruct(data, tablePath, metadata)
% Serialize struct content without table header

    tomlStr = "";

    % Get key order from metadata or use struct field order
    if ~isempty(metadata) && isKey(metadata, tablePath)
        allKeys = metadata{tablePath}{1};
    else
        allKeys = string(fieldnames(data));
    end

    for i = 1:numel(allKeys)
        key = allKeys(i);
        fieldName = matlab.lang.makeValidName(key);

        if ~isfield(data, fieldName)
            continue;  % Skip if key from metadata doesn't exist
        end

        value = data.(fieldName);

        if ~isstruct(value)
            tomlStr = tomlStr + serializeKeyValue(key, value) + newline;
        end
    end

    % Handle nested tables
    for i = 1:numel(allKeys)
        key = allKeys(i);
        fieldName = matlab.lang.makeValidName(key);

        if ~isfield(data, fieldName)
            continue;  % Skip if key from metadata doesn't exist
        end

        value = data.(fieldName);

        if isstruct(value)
            tomlStr = tomlStr + serializeTable(key, value, "", metadata);
        end
    end
end

function str = serializeKeyValue(key, value)
% Serialize a single key-value pair

    % Quote key if necessary
    if needsQuoting(key)
        keyStr = '"' + key + '"';
    else
        keyStr = key;
    end

    valueStr = serializeValue(value);
    str = keyStr + " = " + valueStr;
end

function tf = needsQuoting(key)
% Check if key needs quoting

    % Keys with spaces or special characters need quotes
    if contains(key, " ") || contains(key, ".") || contains(key, "-")
        tf = true;
    else
        tf = false;
    end
end

function str = serializeValue(value)
% Serialize a value to TOML format

    if islogical(value)
        % Boolean
        if value
            str = "true";
        else
            str = "false";
        end

    elseif (isstring(value) || ischar(value)) && isscalar(value)
        % Scalar string
        str = '"' + escapeString(string(value)) + '"';

    elseif isstring(value) && ~isscalar(value)
        % String array
        str = serializeArray(value);

    elseif isdatetime(value)
        % DateTime
        str = string(value, 'yyyy-MM-dd''T''HH:mm:ssXXX');

    elseif isnumeric(value) && isscalar(value)
        % Number - use heuristic for integer vs float
        if value == floor(value) && abs(value) < 2^53
            str = sprintf('%d', value);
        else
            str = sprintf('%.15g', value);
        end

    elseif isnumeric(value) && ~isscalar(value)
        % Numeric array
        str = serializeArray(value);

    elseif isstruct(value) && isscalar(value)
        % Inline table
        str = serializeInlineTable(value);

    else
        error('writetoml:UnsupportedType', ...
            'Cannot serialize value of type: %s', class(value));
    end
end

function str = serializeArray(arr)
% Serialize array to TOML format

    str = "[";

    for i = 1:numel(arr)
        str = str + serializeValue(arr(i));

        if i < numel(arr)
            str = str + ", ";
        end
    end

    str = str + "]";
end

function str = serializeInlineTable(tbl)
% Serialize inline table

    str = "{";
    tableKeys = string(fieldnames(tbl));

    for i = 1:numel(tableKeys)
        fieldName = tableKeys(i);
        value = tbl.(fieldName);

        if needsQuoting(fieldName)
            str = str + '"' + fieldName + '"';
        else
            str = str + fieldName;
        end

        str = str + " = " + serializeValue(value);

        if i < numel(tableKeys)
            str = str + ", ";
        end
    end

    str = str + "}";
end

function str = escapeString(str)
% Escape special characters in string

    str = strrep(str, '\', '\\');
    str = strrep(str, '"', '\"');
    str = strrep(str, newline, '\n');
    str = strrep(str, sprintf('\t'), '\t');
    str = strrep(str, sprintf('\r'), '\r');
end
