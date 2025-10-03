import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:fix_me_mcp/diagnostics.dart' as diagnostics;

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
  print('Usage: dart fix_me_mcp.dart <flags> [arguments]');
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
      io.stdout.writeln('fix_me_mcp version: $version');
      return;
    }

    MCPDiagnosticsServer(stdioChannel(input: io.stdin, output: io.stdout));
  } on FormatException catch (e) {
    io.stderr.writeln(e.message);
    io.stderr.writeln('');
    printUsage(argParser);
  }
}

base class MCPDiagnosticsServer extends MCPServer with ToolsSupport {
  MCPDiagnosticsServer(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: 'fix_me_mcp diagnostics server',
          version: version,
        ),
        instructions: 'Call tools to get diagnostic descriptions by id.',
      ) {
    registerTool(describeDiagnosticTool, _describeDiagnostic);
  }

  final Tool describeDiagnosticTool = Tool(
    name: 'describe_diagnostic',
    description: 'Return the description for a diagnostic error id',
    inputSchema: Schema.object(
      properties: {
        'id': Schema.string(
          description: 'Diagnostic id, e.g. \'discarded_result\'',
        ),
        'ids': Schema.list(
          description: 'Multiple diagnostic ids',
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
          content: [TextContent(text: 'No diagnostic ids provided')],
        );
      }
      final descriptions = ids.map(diagnostics.lookupDescription).toList();
      final contents = <Content>[];
      for (var i = 0; i < ids.length; i++) {
        final id = ids[i];
        final desc = descriptions[i];
        contents.add(
          TextContent(text: desc == null ? '$id: <unknown>' : '$id: $desc'),
        );
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
    final String? description = diagnostics.lookupDescription(id);
    return CallToolResult(
      isError: description == null,
      content: [TextContent(text: description ?? 'Unknown diagnostic id: $id')],
    );
  }
}
