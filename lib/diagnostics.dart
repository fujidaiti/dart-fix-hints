const Map<String, String> kDiagnosticDescriptions = {
  'discarded_result':
      'A value was computed but not used. This often indicates a missing await, an ignored return value, or unintended expression with no effect.',
  'unused_import':
      'An import is never used. Remove the import to keep the codebase minimal and reduce compile-time work.',
  'dead_code':
      'Code is unreachable and will never execute. Remove it or fix the control flow that makes it unreachable.',
  'unawaited_future':
      'A Future is created but not awaited or handled. Await it or explicitly ignore with clear intent to avoid lost errors.',
  'shadowed_variable':
      'A local declaration hides another variable with the same name in an outer scope. Rename to prevent confusion.',
  'nullable_assignment':
      'A nullable value is assigned where a non-null is required. Add a null-check, default, or adjust types.',
  'type_mismatch':
      'Value type is incompatible with the target type. Convert the value or fix the declared types.',
  'unreachable_switch_case':
      'A switch case can never match due to previous exhaustive cases or conditions. Remove it or adjust patterns.',
  'deprecated_api_usage':
      'A deprecated API is used. Migrate to the recommended replacement to ensure forward compatibility.',
  'missing_return':
      'A non-void function may exit without returning a value. Ensure all paths return.',
  'invalid_argument':
      'An argument value violates preconditions. Validate input or adjust the call site.',
  'out_of_range_index':
      'An index access is outside the valid bounds. Check lengths and guard inputs before indexing.',
};

String? lookupDescription(String id) {
  return kDiagnosticDescriptions[id];
}
