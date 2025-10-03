import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';

Future<void> main() async {
  stdout.writeln('Starting dart_fix_hints server...');
  final process = await Process.start('dart', [
    'run',
    'bin/dart_fix_hints.dart',
  ]);

  // Tee the server's raw stdio to the console while also feeding the MCP client.
  final serverOut = StreamController<List<int>>(sync: true);
  process.stdout.listen((chunk) {
    stdout.write('srv> ');
    stdout.add(chunk);
    serverOut.add(chunk);
  });
  process.stderr.listen((chunk) {
    stderr.write('srv err> ');
    stderr.add(chunk);
  });

  final client = MCPClient(
    Implementation(name: 'debug client', version: '0.1.0'),
  );
  final server = client.connectServer(
    stdioChannel(input: serverOut.stream, output: process.stdin),
  );
  unawaited(server.done.then((_) => process.kill()));

  await server.initialize(
    InitializeRequest(
      protocolVersion: ProtocolVersion.latestSupported,
      capabilities: client.capabilities,
      clientInfo: client.implementation,
    ),
  );
  server.notifyInitialized();
  stdout.writeln('Connected. Tools available:');
  final tools = await server.listTools(ListToolsRequest());
  for (final t in tools.tools) {
    stdout.writeln('- ${t.name}');
  }

  stdout.writeln('Enter diagnostic id(s) separated by spaces (empty to quit):');
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) break;
    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    try {
      final arguments = parts.length == 1
          ? {'id': parts.first}
          : {'ids': parts};
      final res = await server.callTool(
        CallToolRequest(name: 'describe_diagnostic', arguments: arguments),
      );
      // Print raw response structure for debugging as pretty JSON.
      stdout.writeln('raw:');
      stdout.writeln(getPrettyJSONString(res));
    } catch (e) {
      stderr.writeln('Call failed: $e');
    }
    stdout.writeln(
      'Enter diagnostic id(s) separated by spaces (empty to quit):',
    );
  }

  await client.shutdown();
  process.kill();
}

String getPrettyJSONString(Object? jsonObject) {
  final encoder = const JsonEncoder.withIndent('  ');
  return encoder.convert(jsonObject);
}
