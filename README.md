## Overview

`fix_me_mcp` is a minimal Dart MCP server that exposes a tool to describe diagnostics by id(s). It communicates over stdio and is intended to be hosted by an AI agent or any MCP-compliant client.

### Current tool

- **name**: `describe_diagnostic`
- **input**: Either `{ "id": string }` or `{ "ids": string[] }`
- **output**:
  - Single id: one TextContent with the description (error if unknown)
  - Multiple ids: an array of TextContent entries, each `"id: description"` (unknown as `"id: <unknown>"`)

## Install

```bash
dart pub get
```

## Run

Start the server over stdio:

```bash
dart run bin/fix_me_mcp.dart
```

CLI flags:

- `--help` prints usage
- `--version` prints the server version

## Using the tool

From an MCP client, call `describe_diagnostic` with arguments like:

```json
{"id":"discarded_result"}
```

Or multiple ids:

```json
{"ids":["discarded_result","unused_import"]}
```

The server returns TextContent entries as described above.

## Project structure

- `bin/fix_me_mcp.dart`: CLI entrypoint and MCP server wiring. Defines `MCPDiagnosticsServer`, registers tools, and binds stdio.
- `lib/diagnostics.dart`: Diagnostic registry defined as `const Map<String,String> kDiagnosticDescriptions` with a `lookupDescription(String)` helper.
- `pubspec.yaml`: Declares a local path dependency on the MCP library.
- `ai/pkgs/dart_mcp/`: Local MCP library providing protocol types and stdio channel utilities (examples included in `example/`).
- `tool/debug_client.dart`: Interactive client for manual debugging; spawns the server, pretty-prints raw responses, and accepts space-separated ids.

## Design notes

- **Separation of concerns**: Tool behavior (server) is isolated from data (diagnostics registry).
- **Transport**: Uses `stdioChannel` to ensure line-delimited JSON over stdio. The server avoids printing to stdout except for explicit CLI output (help/version).
- **MCP integration**: Implements an MCP server via `ToolsSupport`, registers tools with schemas, and returns `CallToolResult` content entries.
- **Data source**: Diagnostics are embedded in-code as a `const` map for compatibility with compiled executables.
- **Extensibility**: Add/modify diagnostics in `lib/diagnostics.dart`; add new tools by defining a `Tool` and registering it in `MCPDiagnosticsServer`.

## Extend

1) Add a diagnostic: update `kDiagnosticDescriptions` in `lib/diagnostics.dart`.
2) Add a tool: define a new `Tool`, implement a handler, and register it in the server constructor.
