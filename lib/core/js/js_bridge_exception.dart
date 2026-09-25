// SPDX-License-Identifier: AGPL-3.0-or-later

/// The failure categories for JS bridge operations.
enum JsBridgeExceptionKind {
  load,
  call,
  decode,
  type,
}

/// Exception thrown when a JS bridge evaluation, decoding, or type coercion fails.
final class JsBridgeException implements Exception {
  const JsBridgeException({
    required this.path,
    required this.message,
    required this.kind,
    this.jsStack,
  });

  const JsBridgeException.load({
    required String message,
    String? jsStack,
  }) : this(
          path: '<bundle>',
          message: message,
          kind: JsBridgeExceptionKind.load,
          jsStack: jsStack,
        );

  const JsBridgeException.call({
    required String path,
    required String message,
    String? jsStack,
  }) : this(
          path: path,
          message: message,
          kind: JsBridgeExceptionKind.call,
          jsStack: jsStack,
        );

  const JsBridgeException.decode({
    required String path,
    required String message,
  }) : this(
          path: path,
          message: message,
          kind: JsBridgeExceptionKind.decode,
        );

  const JsBridgeException.type({
    required String path,
    required String message,
  }) : this(
          path: path,
          message: message,
          kind: JsBridgeExceptionKind.type,
        );

  final String path;
  final String message;
  final JsBridgeExceptionKind kind;
  final String? jsStack;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer('JsBridgeException($kind, path: $path): $message');
    if (jsStack != null && jsStack!.isNotEmpty) {
      buf.write('\nJS Stack:\n$jsStack');
    }
    return buf.toString();
  }
}
