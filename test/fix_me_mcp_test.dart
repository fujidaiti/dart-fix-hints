import 'dart:async';

import 'package:dart_fix_hints/diagnostics.dart' show DiagnosticsTable;
import 'package:dart_mcp/client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import '../bin/dart_fix_hints.dart' show MCPDiagnosticsServer, version;

final class _TestClient extends MCPClient {
  _TestClient() : super(Implementation(name: 'test client', version: '0.1.0'));
}

void main() {
  late StreamController<String> clientToServer;
  late StreamController<String> serverToClient;
  late StreamChannel<String> clientChannel;
  late StreamChannel<String> serverChannel;
  late MCPDiagnosticsServer server;
  late DiagnosticsTable table;
  late _TestClient client;
  late ServerConnection conn;
  late InitializeResult init;

  setUp(() async {
    clientToServer = StreamController<String>();
    serverToClient = StreamController<String>();

    clientChannel = StreamChannel<String>.withCloseGuarantee(
      serverToClient.stream,
      clientToServer.sink,
    );
    serverChannel = StreamChannel<String>.withCloseGuarantee(
      clientToServer.stream,
      serverToClient.sink,
    );

    table = DiagnosticsTable();
    server = MCPDiagnosticsServer(serverChannel, table);
    client = _TestClient();
    conn = client.connectServer(clientChannel);

    init = await conn.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: client.capabilities,
        clientInfo: client.implementation,
      ),
    );
    conn.notifyInitialized(InitializedNotification());
    await server.initialized;
  });

  tearDown(() async {
    await client.shutdown();
    await server.shutdown();
  });

  test('initializes with expected server info', () async {
    expect(init.serverInfo.name, 'dart_fix_hints diagnostics server');
    expect(init.serverInfo.version, version);
    expect(init.protocolVersion, ProtocolVersion.latestSupported);
  });

  test('lists the diagnostics tool', () async {
    final list = await conn.listTools();
    final toolNames = list.tools.map((t) => t.name).toList();
    expect(toolNames, contains('describe_diagnostic'));
  });

  test('returns description for known id', () async {
    final result = await conn.callTool(
      CallToolRequest(
        name: 'describe_diagnostic',
        arguments: {'id': 'discarded_future'},
      ),
    );
    expect(result.isError ?? false, false);
    expect(result.content.single.isText, true);
    final text = TextContent.fromMap(
      result.content.single as Map<String, Object?>,
    );
    expect(text.text, contains('unawaited'));
  });

  test('errors for unknown id', () async {
    final result = await conn.callTool(
      CallToolRequest(name: 'describe_diagnostic', arguments: {'id': 'nope'}),
    );
    expect(result.isError, true);
    final text = TextContent.fromMap(
      result.content.single as Map<String, Object?>,
    );
    expect(text.text, contains('Unknown diagnostic id'));
  });

  test('handles multiple ids with mixed known/unknown', () async {
    final result = await conn.callTool(
      CallToolRequest(
        name: 'describe_diagnostic',
        arguments: {
          'ids': ['unused_import', 'does_not_exist'],
        },
      ),
    );
    expect(result.isError ?? false, false);
    expect(result.content.length, 2);

    final first = TextContent.fromMap(
      result.content[0] as Map<String, Object?>,
    );
    final second = TextContent.fromMap(
      result.content[1] as Map<String, Object?>,
    );
    expect(first.text, startsWith('unused_import: '));
    expect(second.text, 'does_not_exist: <unknown>');
  });
}
