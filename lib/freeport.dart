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
    // Map preferred ports to futures
    final futures = preferred.map((port) async {
      if (await isAvailablePort(port, hostname: address)) {
        return port;
      }
    });

    // Wait for any future to complete
    if (await Future.any(futures) case final int port) {
      return port;
    }

    // If none of the preferred ports are available, using for loop
    for (final port in preferred) {
      if (await isAvailablePort(port, hostname: address)) {
        return port;
      }
    }
  }

  // Any port
  return ServerSocket.bind(address, 0).then((socket) async {
    try {
      return socket.port;
    } finally {
      await socket.close();
    }
  });
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
  if (port == 0) return true;

  late final ServerSocket? socket;
  try {
    final address = _resolveAddress(hostname);
    socket = await ServerSocket.bind(address, port);
    return socket.port == port;
  } catch (_) {
    socket = null;
    return false;
  } finally {
    await socket?.close();
  }
}

InternetAddress _resolveAddress(Object? hostname) {
  return switch (hostname ??
      Platform.environment['HOST'] ??
      String.fromEnvironment("HOST")) {
    final InternetAddress address => address,
    final String address =>
      InternetAddress.tryParse(address) ?? InternetAddress.loopbackIPv4,
    _ => InternetAddress.loopbackIPv4,
  };
}
