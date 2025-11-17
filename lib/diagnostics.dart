import 'dart:io' as io;
import 'package:yaml/yaml.dart' as yaml;

/// Represents a diagnostic entry with its associated messages.
class DiagnosticEntry {
  final String id;
  final String? problemMessage;
  final String? documentation;
  final String? deprecatedDetails;

  const DiagnosticEntry({
    required this.id,
    this.problemMessage,
    this.documentation,
    this.deprecatedDetails,
  });

  /// Formats the diagnostic entry as a readable string.
  String format() {
    final buffer = StringBuffer();

    if (problemMessage != null) {
      buffer.writeln('Problem: $problemMessage');
      buffer.writeln();
    }

    if (documentation != null && documentation!.isNotEmpty) {
      buffer.writeln('Documentation:');
      buffer.writeln(documentation);
      buffer.writeln();
    }

    if (deprecatedDetails != null && deprecatedDetails!.isNotEmpty) {
      buffer.writeln('Details:');
      buffer.writeln(deprecatedDetails);
    }

    return buffer.toString().trimRight();
  }

  @override
  String toString() => format();
}

class DiagnosticsTable {
  final Map<String, DiagnosticEntry> _diagnostics;

  DiagnosticsTable._internal(this._diagnostics);

  /// Creates a DiagnosticsTable by loading and parsing the embedded YAML file.
  factory DiagnosticsTable.load() {
    // Load the embedded YAML file
    final file = io.File('lib/lint_messages.yaml');
    if (!file.existsSync()) {
      throw StateError('Lint messages file not found at: ${file.path}');
    }

    final yamlContent = file.readAsStringSync();
    final doc = yaml.loadYaml(yamlContent);

    if (doc is! Map) {
      throw FormatException('YAML file must contain a top-level map');
    }

    final linterCodes = doc['LinterLintCode'];
    if (linterCodes is! Map) {
      throw FormatException('YAML file must contain a LinterLintCode map');
    }

    // Parse all diagnostic entries
    final diagnostics = <String, DiagnosticEntry>{};
    for (final entry in linterCodes.entries) {
      final id = entry.key?.toString();
      if (id == null) continue;

      final value = entry.value;
      if (value is! Map) continue;

      final problemMessage = value['problemMessage']?.toString();
      final documentation = value['documentation']?.toString();
      final deprecatedDetails = value['deprecatedDetails']?.toString();

      diagnostics[id] = DiagnosticEntry(
        id: id,
        problemMessage: problemMessage,
        documentation: documentation,
        deprecatedDetails: deprecatedDetails,
      );
    }

    return DiagnosticsTable._internal(Map.unmodifiable(diagnostics));
  }

  /// Looks up a diagnostic entry by ID.
  /// Returns null if the diagnostic is not found.
  DiagnosticEntry? lookup(String id) {
    return _diagnostics[id];
  }

  /// Returns all available diagnostic IDs.
  Iterable<String> get ids => _diagnostics.keys;

  /// Returns the number of diagnostics in the table.
  int get length => _diagnostics.length;
}
