# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a MATLAB toolbox for reading and writing TOML (Tom's Obvious Minimal Language) configuration files. The toolbox provides two main functions:
- `readtoml()`: Parses TOML files into MATLAB dictionaries or structs
- `writetoml()`: Serializes MATLAB dictionaries or structs to TOML format

## Build and Test Commands

### Run Tests
```matlab
buildtool test
```
Runs all unit tests in `tests/toml_test.m`.

### Run Code Quality Checks
```matlab
buildtool check
```
Runs MATLAB's code analyzer (checkcode) on the toolbox folder.

### Package Toolbox
```matlab
buildtool package
```
Runs checks and tests, then packages the toolbox into an `.mltbx` file in the `release/` folder.

### Run All (Default)
```matlab
buildtool
```
Equivalent to running check, test, and package in sequence.

### Run Single Test
Use MATLAB's test framework to run individual tests:
```matlab
result = runtests('tests/toml_test.m', 'Name', 'testSimpleKeyValue');
```

## Code Architecture

### Core Functions

**`readtoml.m`** (544 lines)
- Main entry point for parsing TOML files
- Uses recursive descent parsing approach
- Returns ordered dictionary by default (preserves key order), optional struct output
- Key internal functions:
  - `parseToml()`: Main parser that processes line-by-line
  - `handleTable()`: Processes `[table]` syntax
  - `handleArrayOfTables()`: Processes `[[array.of.tables]]` syntax
  - `parseKeyValue()`: Parses `key = value` lines
  - `parseValue()`: Dispatches to type-specific parsers
  - `parseArray()`, `parseInlineTable()`, `parseString()`, `parseNumber()`, `parseDatetime()`
  - `dictionaryToStruct()`: Converts dictionary output to struct

**`writetoml.m`** (338 lines)
- Main entry point for writing TOML files
- Serializes dictionaries or structs to TOML format
- Includes overwrite protection (default: error if file exists)
- Key internal functions:
  - `serializeToml()`: Main serialization orchestrator
  - `separateRootAndTables()`: Separates top-level values from nested tables
  - `serializeTable()`: Handles table headers and array of tables
  - `serializeValue()`: Dispatches type-specific serialization
  - `structToDictionary()`: Converts struct input to dictionary for processing

### Parsing Strategy

The parser maintains state through:
- `currentTable`: Reference to the current dictionary being populated
- `currentTablePath`: String tracking the current table's dotted path
- `arrayOfTables`: Dictionary tracking which paths represent arrays of tables

Tables are handled as nested dictionaries. The `[[double bracket]]` syntax creates arrays by appending new dictionaries to an array.

### Type Handling

**Reading:**
- Strings: Supports both basic (`"..."`) and literal (`'...'`) strings with escape sequence processing
- Numbers: Integers, floats, hex (0x), octal (0o), binary (0b), with underscore support
- Booleans: `true`/`false` as MATLAB logical
- Datetimes: Parsed to MATLAB datetime objects (or kept as strings)
- Arrays: Homogeneous arrays enforced (mixed types throw error)
- Inline tables: `{key = value}` syntax parsed to dictionaries

**Writing:**
- Integers: Written without decimal point (heuristic: `value == floor(value)`)
- Floats: Written with decimal representation
- Booleans: Written as `true`/`false`
- Strings: Escaped with `\"`, `\\`, `\n`, `\t`, `\r`
- Arrays: Written as `[elem1, elem2, ...]`
- Nested tables: Written with `[table.path]` headers

### Toolbox Structure

```
toolbox/
  readtoml.m          - TOML reader
  writetoml.m         - TOML writer
  gettingStarted.mlx  - Getting started guide (Live Script)
  examples/           - Example TOML files and demo scripts

tests/
  toml_test.m         - Comprehensive test suite (24 test methods)

buildfile.m           - Build automation (test, check, package)
packageToolbox.m      - Toolbox packaging helper
toolboxOptions.m      - Toolbox metadata and configuration
```

### Key Design Decisions

1. **Dictionary vs Struct**: Default output is dictionary (preserves key ordering), but struct output available via `OutputType='struct'` option
2. **Dotted Keys**: Keys like `a.b.c = value` create nested dictionary structure automatically
3. **Overwrite Protection**: `writetoml()` requires explicit `OverWrite=true` to replace existing files
4. **UTF-8 Encoding**: All file I/O uses UTF-8 encoding
5. **Array Homogeneity**: Enforced per TOML spec - arrays must contain single type

## Testing Notes

- Tests use MATLAB's `matlab.unittest.TestCase` framework
- Each test creates a temporary working folder (cleaned up automatically)
- Tests cover: primitives, arrays, tables, nested tables, inline tables, comments, round-trip serialization
- Error cases tested: mixed-type arrays, overwrite protection
- 24 test methods covering read and write functionality

## MATLAB Version Compatibility

- Dictionary support requires R2022b or later (for ordered dictionaries)
- Toolbox configured to support all platforms (Win64, Glnxa64, Maci64, MATLAB Online)
- No minimum/maximum MATLAB release restrictions currently set
