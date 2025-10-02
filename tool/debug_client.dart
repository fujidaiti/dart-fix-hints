import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';

Future<void> main() async {
  stdout.writeln('Starting fix_me_mcp server...');
  final process = await Process.start('dart', ['run', 'bin/fix_me_mcp.dart']);

  final client = MCPClient(
    Implementation(name: 'debug client', version: '0.1.0'),
  );
  final server = client.connectServer(
    stdioChannel(input: process.stdout, output: process.stdin),
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

  stdout.writeln('Enter diagnostic id (empty to quit):');
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    final id = line.trim();
    if (id.isEmpty) break;
    try {
      final res = await server.callTool(
        CallToolRequest(name: 'describe_diagnostic', arguments: {'id': id}),
      );
      if (res.isError == true) {
        stderr.writeln('Error: ${_stringifyContent(res.content)}');
      } else {
        stdout.writeln(_stringifyContent(res.content));
      }
    } catch (e) {
      stderr.writeln('Call failed: $e');
    }
    stdout.writeln('Enter diagnostic id (empty to quit):');
  }

  await client.shutdown();
  process.kill();
}

String _stringifyContent(List<Content> content) {
  if (content.isEmpty) return '';
  final buffer = StringBuffer();
  for (final c in content) {
    if (c is TextContent) {
      buffer.writeln(c.text);
    } else {
      buffer.writeln('[${c.type}]');
    }
  }
  return buffer.toString().trimRight();
}
