%[text] # TOML Examples Demonstration
%[text] This script demonstrates how to use the TOML toolbox to read and write TOML configuration files.
%[text] Get path to example files. Assume they are in examples folder that lives alongside `readtoml` and `writetoml`.
rtp = fileparts(which("readtoml"));
fp = fullfile(rtp,"examples/");
%%
%[text] ## Example 1: Simple Configuration
%[text] Reading a basic config file with nested tables.
config = readtoml(fp + "simple_config.toml") %[output:821a6e7d]
%%
%[text] Access nested fields:
config.database %[output:4b48c1b0]
config.logging %[output:526512eb]
%%
%[text] ## Example 2: Arrays
%[text] Reading arrays of different types including integers, strings, and nested arrays.
arrays = readtoml(fp + "arrays_demo.toml") %[output:56307e62]
%%
%[text] Access array fields:
arrays.integers %[output:068e5e89]
arrays.strings %[output:75893865]
arrays.network.http_ports %[output:9af34825]
%%
%[text] ## Example 3: Nested Tables
%[text] Reading deeply nested configuration structures.
nested = readtoml(fp + "nested_tables.toml") %[output:10493b05]
%%
%[text] Access deeply nested data:
nested.server.database %[output:6e58778b]
nested.application.settings.security %[output:409753b3]
nested.application.settings.performance %[output:25c73de8]
%%
%[text] ## Example 4: MATLAB Project Configuration
%[text] Reading a MATLAB project configuration file with algorithm settings.
project = readtoml(fp + "matlab_project.toml") %[output:964eceef]
%%
%[text] Access project metadata and algorithm configuration:
project.project %[output:9340383a]
project.algorithm %[output:497fb558]
%%
%[text] ## Example 5: Metadata for Round-Trip Support
%[text] The toolbox can return metadata that preserves key ordering for faithful round-trip operations.
[data, metadata] = readtoml(fp + "simple_config.toml");
data %[output:00a37213]
%%
%[text] Metadata tracks key insertion order at each nesting level:
metadata{""}{1} %[output:874b1510]
metadata{"database"}{1} %[output:7e05b8d5]
%%
%[text] ## Example 6: Write and Round-Trip
%[text] Creating a new TOML file from MATLAB data and reading it back.
newConfig.app_name = "My MATLAB App";
newConfig.version = 3.14;
newConfig.features = ["plotting", "analysis", "export"];
newConfig.settings.theme = "dark";
newConfig.settings.autosave = true;
writetoml(fp + "generated_config.toml", newConfig, "OverWrite", true);
%%
%[text] Read it back to verify:
readBack = readtoml(fp + "generated_config.toml") %[output:6c300c06]
%%
%[text] ## Example 7: Round-Trip with Metadata Preserves Key Order
%[text] Modify data and write back with metadata to preserve original key ordering.
[original, meta] = readtoml(fp + "simple_config.toml");
original.database.port = 3306;
writetoml(fp + "modified_config.toml", original, "Metadata", meta, "OverWrite", true);
%%
%[text] Verify the modified data:
modified = readtoml(fp + "modified_config.toml") %[output:8dd4d174]
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:821a6e7d]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"config","value":"       title: \"My Application\"\n     version: 1\n       debug: 0\n    database: [1×1 struct]\n     logging: [1×1 struct]\n"}}
%---
%[output:4b48c1b0]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"      server: \"192.168.1.1\"\n        port: 5432\n    username: \"admin\"\n     enabled: 1\n"}}
%---
%[output:526512eb]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"       level: \"info\"\n        file: \"\/var\/log\/app.log\"\n    max_size: 10485760\n"}}
%---
%[output:56307e62]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"arrays","value":"         integers: [1 2 3 4 5]\n           floats: [1.1000 2.2000 3.3000]\n          strings: [\"red\"    \"yellow\"    \"green\"]\n         booleans: [1 0 1]\n           nested: [1 2 3 4 5 6]\n            empty: []\n    large_numbers: [1000 2000 3000]\n           colors: [1×1 struct]\n          network: [1×1 struct]\n"}}
%---
%[output:068e5e89]
%   data: {"dataType":"matrix","outputData":{"columns":5,"name":"ans","rows":1,"type":"double","value":[["1","2","3","4","5"]]}}
%---
%[output:75893865]
%   data: {"dataType":"matrix","outputData":{"columns":3,"header":"1×3 string array","name":"ans","rows":1,"type":"string","value":[["red","yellow","green"]]}}
%---
%[output:9af34825]
%   data: {"dataType":"matrix","outputData":{"columns":3,"name":"ans","rows":1,"type":"double","value":[["8080","8081","8082"]]}}
%---
%[output:10493b05]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"nested","value":"          title: \"Nested Configuration Example\"\n         server: [1×1 struct]\n    application: [1×1 struct]\n         client: [1×1 struct]\n"}}
%---
%[output:6e58778b]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"    host: \"localhost\"\n    port: 5432\n    name: \"mydb\"\n"}}
%---
%[output:409753b3]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"              enabled: 1\n           encryption: \"AES256\"\n    key_rotation_days: 90\n"}}
%---
%[output:25c73de8]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"      cache_enabled: 1\n    max_connections: 100\n            timeout: 30\n"}}
%---
%[output:964eceef]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"project","value":"          project: [1×1 struct]\n            build: [1×1 struct]\n          testing: [1×1 struct]\n            paths: [1×1 struct]\n        algorithm: [1×1 struct]\n    visualization: [1×1 struct]\n          logging: [1×1 struct]\n"}}
%---
%[output:9340383a]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"            name: \"Data Analysis Toolkit\"\n         version: \"2.1.0\"\n     description: \"Tools for scientific data analysis\"\n          author: \"Research Team\"\n         license: \"MIT\"\n    requirements: [1×1 struct]\n"}}
%---
%[output:497fb558]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"    max_iterations: 1000\n         tolerance: 1.0000e-06\n     learning_rate: 0.0100\n        batch_size: 32\n     preprocessing: [1×1 struct]\n"}}
%---
%[output:00a37213]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"data","value":"       title: \"My Application\"\n     version: 1\n       debug: 0\n    database: [1×1 struct]\n     logging: [1×1 struct]\n"}}
%---
%[output:874b1510]
%   data: {"dataType":"matrix","outputData":{"columns":5,"header":"1×5 string array","name":"ans","rows":1,"type":"string","value":[["title","version","debug","database","logging"]]}}
%---
%[output:7e05b8d5]
%   data: {"dataType":"matrix","outputData":{"columns":4,"header":"1×4 string array","name":"ans","rows":1,"type":"string","value":[["server","port","username","enabled"]]}}
%---
%[output:6c300c06]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"readBack","value":"    app_name: \"My MATLAB App\"\n     version: 3.1400\n    features: [\"plotting\"    \"analysis\"    \"export\"]\n    settings: [1×1 struct]\n"}}
%---
%[output:8dd4d174]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"modified","value":"       title: \"My Application\"\n     version: 1\n       debug: 0\n    database: [1×1 struct]\n     logging: [1×1 struct]\n"}}
%---
