import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:dart_fix_hints/diagnostics.dart' as diagnostics;
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print('Usage: dart dart_fix_hints.dart <flags> [arguments]');
  print(argParser.usage);
}

void main(List<String> arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      io.stdout.writeln('dart_fix_hints version: $version');
      return;
    }

    // Load the diagnostics table from the embedded YAML file
    final table = diagnostics.DiagnosticsTable.load();

    MCPDiagnosticsServer(
      stdioChannel(input: io.stdin, output: io.stdout),
      table,
    );
  } on FormatException catch (e) {
    io.stderr.writeln(e.message);
    io.stderr.writeln('');
    printUsage(argParser);
  }
}

base class MCPDiagnosticsServer extends MCPServer with ToolsSupport {
  final diagnostics.DiagnosticsTable table;

  MCPDiagnosticsServer(super.channel, this.table)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: 'dart_fix_hints',
          title:
              'Provides common fixes for Dart/Flutter lint errors '
              "that can not be automatically fixed by 'dart fix' command.",
          version: version,
        ),
      ) {
    registerTool(describeDiagnosticTool, _describeDiagnostic);
  }

  final Tool describeDiagnosticTool = Tool(
    name: 'describe_diagnostic',
    description:
        'Returns common fixes for given lint error IDs, such as '
        "'discarded_futures' and 'comment_references'. "
        "The error IDs can be obtained from a Dart analyzer or 'dart analyze' command.",
    inputSchema: Schema.object(
      properties: {
        'id': Schema.string(description: "Error id, e.g. 'discarded_future'"),
        'ids': Schema.list(
          description: 'Multiple error ids',
          items: Schema.string(),
        ),
      },
    ),
  );

  Future<CallToolResult> _describeDiagnostic(CallToolRequest request) async {
    final args = request.arguments ?? const {};
    if (args.containsKey('ids')) {
      final raw = args['ids'];
      if (raw is! List) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'Field `ids` must be a list of strings')],
        );
      }
      final ids = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (ids.isEmpty) {
        return CallToolResult(
          isError: true,
          content: [TextContent(text: 'No error ids provided')],
        );
      }
      final entries = ids.map(table.lookup).toList();
      final contents = <Content>[];
      for (var i = 0; i < ids.length; i++) {
        final id = ids[i];
        final entry = entries[i];
        if (entry == null) {
          contents.add(TextContent(text: '$id: <unknown>'));
        } else {
          contents.add(TextContent(text: '$id:\n${entry.format()}'));
        }
      }
      return CallToolResult(content: contents);
    }

    if (!args.containsKey('id')) {
      return CallToolResult(
        isError: true,
        content: [TextContent(text: 'Missing required field: `id` or `ids`')],
      );
    }

    final String id = (args['id'] as String).trim();
    final diagnostics.DiagnosticEntry? entry = table.lookup(id);
    return CallToolResult(
      isError: entry == null,
      content: [
        TextContent(text: entry?.format() ?? 'Unknown diagnostic id: $id')
      ],
    );
  }
}
