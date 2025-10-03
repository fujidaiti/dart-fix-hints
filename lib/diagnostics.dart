const Map<String, String> kDiagnosticDescriptions = {
  'discarded_future': '''
Fix this error by awaiting the future or wrapping the future in `unawaited`.
Make sure to import `dart:async` if you use `unawaited`.

```dart
await methodThatReturnsFuture();
// or
import 'dart:async';
unawaited(methodThatReturnsFuture());
''',

  'avoid_classes_with_only_static_members': '''
If you want to define a class that serves as a namespace for static methods,
define the class as "abstract" and add a `const` private constructor.

```dart
abstract class Utils {
  const Utils._();
}
```,
''',

  'comment_references': '''
When mentioning a method or class in a doc-comment but those are not imported in the file,
add `/// @docImport`s at the top of the file as if importing them (but they are not real imports).

```dart
/// @docImport('dart:async');
library;

// And import directives come here.
import 'package:flutter/material.dart';
```
''',
};

String? lookupDescription(String id) {
  return kDiagnosticDescriptions[id];
}
