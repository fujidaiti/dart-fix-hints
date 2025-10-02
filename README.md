## Overview

`fix_me_mcp` is a minimal Dart MCP server that exposes a single tool to describe diagnostics by id. It communicates over stdio and is intended to be hosted by an AI agent or any MCP-compliant client.

### Current tool

- **name**: `describe_diagnostic`
- **input**: `{ "id": string }` (e.g., `"discarded_result"`)
- **output**: textual description or an error if the id is unknown

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

The server returns a single text content item with the description, or an error response if the id is unknown.

## Project structure

- `bin/fix_me_mcp.dart`: CLI entrypoint and MCP server wiring. Defines `MCPDiagnosticsServer`, registers tools, and binds stdio.
- `lib/diagnostics.dart`: Diagnostic registry and lookup API used by the tool implementation.
- `pubspec.yaml`: Declares a local path dependency on the MCP library.
- `ai/pkgs/dart_mcp/`: Local MCP library providing protocol types and stdio channel utilities (examples included in `example/`).

## Design notes

- **Separation of concerns**: Tool behavior (server) is isolated from data (diagnostics registry).
- **Transport**: Uses `stdioChannel` to ensure line-delimited JSON over stdio. The server avoids printing to stdout except for explicit CLI output (help/version).
- **MCP integration**: Implements an MCP server via `ToolsSupport`, registers tools with schemas, and replies with `CallToolResult` content.
- **Extensibility**: Add new diagnostics in `lib/diagnostics.dart`; add new tools by defining a `Tool` and registering it in `MCPDiagnosticsServer`.

## Extend

1) Add a diagnostic: update `lib/diagnostics.dart` map.
2) Add a tool: define a new `Tool`, implement a handler, and register it in the server constructor.
