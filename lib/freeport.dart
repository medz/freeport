import 'dart:io';

/// Finds a free port on the given [hostname].
///
/// If [preferred] ports are provided, tries those first in order.
/// If none are available or none provided, finds a random free port.
///
/// The [hostname] parameter can be a String IP address or an [InternetAddress].
/// If not provided, uses HOST environment variable or loopback address.
///
/// Returns a [Future] that completes with the port number.
///
/// Example:
/// ```dart
/// // Get any free port
/// var port = await freePort();
///
/// // Try preferred ports first
/// var port = await freePort(preferred: [8080, 8081]);
///
/// // Specify hostname
/// var port = await freePort(hostname: '127.0.0.1');
/// ```
Future<int> freePort({Iterable<int>? preferred, Object? hostname}) async {
  final address = _resolveAddress(hostname);
  if (preferred != null && preferred.isNotEmpty) {
    for (final port in preferred) {
      if (await isAvailablePort(port, hostname: address)) {
        return port;
      }
    }
  }

  final socket = await ServerSocket.bind(address, 0);
  final port = socket.port;
  await socket.close();

  return port;
}

/// Checks if a specific [port] is available on the given [hostname].
///
/// The [hostname] parameter can be a String IP address or an [InternetAddress].
/// If not provided, uses HOST environment variable or loopback address.
///
/// Returns a [Future] that completes with true if port is available, false otherwise.
///
/// Example:
/// ```dart
/// if (await isAvailablePort(8080)) {
///   print('Port 8080 is available');
/// }
/// ```
Future<bool> isAvailablePort(int port, {Object? hostname}) async {
  try {
    final address = _resolveAddress(hostname);
    await ServerSocket.bind(address, port);
    return true;
  } catch (_) {
    return false;
  }
}

/// Resolves hostname to an [InternetAddress].
///
/// The [hostname] parameter can be:
/// - An [InternetAddress] (returned as-is)
/// - A String IP address (parsed to InternetAddress)
/// - null (uses HOST env var or loopback)
///
/// Returns the resolved [InternetAddress].
InternetAddress _resolveAddress(Object? hostname) {
  hostname ??= Platform.environment['HOST'] ?? String.fromEnvironment("HOST");
  if (hostname is String || hostname is InternetAddress) {
    if (hostname is InternetAddress) return hostname;

    final address = InternetAddress.tryParse(hostname as String);
    if (address != null) return address;
  }

  return InternetAddress.loopbackIPv4;
}
