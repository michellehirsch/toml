function opts = toolboxOptions

    toolbox_folder = "toolbox";

    % The following identifier was automatically generated
    % and should remain unchanged for the life of the toolbox.
    identifier = "ec85bc6d-c2fb-4fb6-950f-24901d2266d4";

    opts = matlab.addons.toolbox.ToolboxOptions(toolbox_folder,identifier);

    opts.ToolboxName = "TOML Toolbox";

    % Version number of the toolbox. Use semantic version numbers of the
    % form MAJOR.MINOR.PATCH, such as "2.0.1". Increment the MAJOR version
    % when you make incompatible API changes. Increment the MINOR version
    % when you add functionality in a backward compatible manner. Increment
    % the PATCH version when you make backward compatible bug fixes.

    opts.ToolboxVersion = "1.0.0";

    % Summary and description
    opts.Summary = "Read and write TOML configuration files";
    opts.Description = "A MATLAB toolbox for reading and writing TOML (Tom's Obvious Minimal Language) configuration files. Provides readtoml() and writetoml() functions with support for all TOML data types, nested tables, and round-trip key ordering preservation.";

    % Author information
    opts.AuthorName = "Michelle Hirsch";
    opts.AuthorEmail = "mhirsch@mathworks.com";
    opts.AuthorCompany = "MathWorks";

    % Folders to add to MATLAB path during toolbox installation, specified
    % as a string vector. When specifying ToolboxMatlabPath, include the
    % relative or absolute paths to the folders.

    opts.ToolboxMatlabPath = "toolbox";

    % Path to the toolbox Getting Started Guide, specified as a string. The
    % Getting Started Guide is a MATLAB code file (.m, .mlx) containing a
    % quick start guide for your toolbox. The path can be a relative path
    % or an absolute path.

    opts.ToolboxGettingStartedGuide = fullfile("toolbox", "examples", ...
        "demo_examples.m");

    % Path to the toolbox output file, specified as a string. The path can
    % be a relative path or an absolute path. If the file does not have a
    % .mltbx extension, MATLAB appends the extension automatically when it
    % creates the file.

    opts.OutputFile = fullfile("release", "TOML Toolbox");

    % Earliest MATLAB release that the toolbox is compatible with,
    % specified as a string using the format RXXXXx, for example, "R2020a".
    % Dictionary support required for metadata tracking.

    opts.MinimumMatlabRelease = "R2022b";

    % Latest MATLAB release that the toolbox is compatible with, specified
    % as a string using the format RXXXXx, for example, "R2023a". If there
    % is no maximum restriction, specify MaximumMatlabRelease as empty
    % ("").

    opts.MaximumMatlabRelease = "";

    % Supported platforms

    platforms.Win64        = true;
    platforms.Glnxa64      = true;
    platforms.Mac          = true;
    platforms.MatlabOnline = true;
    opts.SupportedPlatforms = platforms;
end
