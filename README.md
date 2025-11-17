# dart_fix_hints (WIP)

## Overview

`dart_fix_hints` is a minimal Dart MCP server that exposes a tool to describe Dart lint diagnostics by id(s). It uses the official lint rule descriptions from the Dart SDK, providing detailed problem messages, documentation, and additional details for each lint rule. The server communicates over stdio and is intended to be hosted by an AI agent or any MCP-compliant client.

### Current tool

- **name**: `describe_diagnostic`
- **input**: Either `{ "id": string }` or `{ "ids": string[] }`
- **output**:
  - Single id: one TextContent with the diagnostic information including problem message, documentation, and details (error if unknown)
  - Multiple ids: an array of TextContent entries, each formatted as `"id:\n<diagnostic info>"` (unknown as `"id: <unknown>"`)

## Install

```bash
dart pub get
```

## Run

Start the server over stdio:

```bash
dart run bin/dart_fix_hints.dart
```

CLI flags:

- `--help` prints usage
- `--version` prints the server version

## Using the tool

From an MCP client, call `describe_diagnostic` with arguments like:

```json
{"id":"discarded_futures"}
```

Or multiple ids:

```json
{"ids":["discarded_futures","unused_import"]}
```

The server returns TextContent entries with detailed diagnostic information including:
- **Problem**: A description of the issue
- **Documentation**: Detailed explanation with examples (when available)
- **Details**: Additional context or deprecation information (when available)

## Project structure

- `bin/dart_fix_hints.dart`: CLI entrypoint and MCP server wiring. Defines `MCPDiagnosticsServer`, registers tools, and binds stdio.
- `lib/diagnostics.dart`: Diagnostic registry that loads and parses the official Dart lint messages YAML file. Provides `DiagnosticsTable` with `lookup()` method to retrieve diagnostic entries.
- `lib/lint_messages.yaml`: Official lint rule descriptions from the Dart SDK, containing problem messages, documentation, and additional details for all lint rules.
- `pubspec.yaml`: Package dependencies including `dart_mcp`, `args`, and `yaml`.
- `tool/debug_client.dart`: Interactive client for manual debugging; spawns the server, pretty-prints raw responses, and accepts space-separated ids.

## Design notes

- **Separation of concerns**: Tool behavior (server) is isolated from data (diagnostics registry).
- **Transport**: Uses `stdioChannel` to ensure line-delimited JSON over stdio. The server avoids printing to stdout except for explicit CLI output (help/version).
- **MCP integration**: Implements an MCP server via `ToolsSupport`, registers tools with schemas, and returns `CallToolResult` content entries.
- **Data source**: Diagnostics are loaded from the official Dart SDK lint messages YAML file, ensuring comprehensive and up-to-date lint rule information.
- **Extensibility**: Add new tools by defining a `Tool` and registering it in `MCPDiagnosticsServer`.

## Extend

1) Update diagnostics: The lint messages are sourced from the official Dart SDK. To update, download a new version of the `messages.yaml` file from the Dart SDK repository.
2) Add a tool: define a new `Tool`, implement a handler, and register it in the server constructor.

## See also

- [How do I break a string in YAML over multiple lines?](https://stackoverflow.com/a/21699210): A great free content on the internet that explains the YAML's mystrerious syntax of writing multiline strings.
