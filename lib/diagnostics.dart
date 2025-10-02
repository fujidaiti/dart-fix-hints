import 'dart:io';

import 'package:yaml/yaml.dart';

Map<String, String>? _cache;

Future<Map<String, String>> _loadDiagnostics() async {
  if (_cache != null) return _cache!;
  final file = File('lib/assets/diagnostics.yaml');
  if (!await file.exists()) {
    _cache = const {};
    return _cache!;
  }
  final yamlText = await file.readAsString();

  final YamlMap doc = loadYaml(yamlText);
  final Object? raw = doc['diagnostics'];
  final Map<String, String> result = {};
  if (raw is Map) {
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is String) {
        result[key] = value;
      }
    }
  }
  _cache = result;
  return _cache!;
}

Future<String?> lookupDescription(String id) async {
  final map = await _loadDiagnostics();
  return map[id];
}
