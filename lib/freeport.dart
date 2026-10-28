import 'dart:io';

/// Finds an available TCP port on [hostname].
///
/// Tries [preferred] ports in order, closing each probe before continuing.
/// Zero entries are skipped. If no candidate is available, asks the operating
/// system to assign a port. Port values must be between 0 and 65535.
///
/// [hostname] accepts a String hostname or IP address, or an [InternetAddress].
/// Defaults to the HOST environment variable, then the compile-time HOST value,
/// then 127.0.0.1. String names are resolved by [ServerSocket.bind].
/// Literal IP strings are parsed directly. A resolved address reported by a
/// failed bind is reused for the rest of this search.
///
/// Throws an [ArgumentError] for invalid port values or hostname types, and a
/// [SocketException] if the final bind fails.
///
/// The socket is closed before returning. The port is not reserved and another
/// process may claim it before the caller binds it.
///
/// Example:
/// ```dart
/// // Get any free port
/// final port = await freePort();
///
/// // Try preferred ports first
/// final preferredPort = await freePort(preferred: [8080, 8081]);
///
/// // Specify hostname
/// final localPort = await freePort(hostname: 'localhost');
/// ```
Future<int> freePort({Iterable<int>? preferred, Object? hostname}) async {
  var address = _resolveAddress(hostname);
  for (final port in preferred ?? const <int>[]) {
    if (port == 0) continue;
    final ServerSocket socket;
    try {
      socket = await ServerSocket.bind(address, port);
    } on SocketException catch (error) {
      // Native bind failures retain the resolved address, including IPv6 scope.
      address = error.address ?? address;
      continue;
    }
    await socket.close();
    return port;
  }

  final socket = await ServerSocket.bind(address, 0);
  try {
    return socket.port;
  } finally {
    await socket.close();
  }
}

/// Checks whether a TCP socket can bind to [port] on [hostname].
///
/// [hostname] accepts the same values and defaults as [freePort]. Port zero
/// checks whether the system can assign a port on that address.
///
/// Returns false when binding fails with a [SocketException], including address
/// resolution errors. Invalid port values and hostname types throw an
/// [ArgumentError]; other errors propagate.
///
/// The probe is closed before returning. A successful check does not reserve
/// the port.
///
/// Example:
/// ```dart
/// if (await isAvailablePort(8080)) {
///   print('Port 8080 is available');
/// }
/// ```
Future<bool> isAvailablePort(int port, {Object? hostname}) async {
  final address = _resolveAddress(hostname);
  final ServerSocket socket;
  try {
    socket = await ServerSocket.bind(address, port);
  } on SocketException {
    return false;
  }
  await socket.close();
  return true;
}

Object _resolveAddress(Object? hostname) {
  final address = hostname ??
      Platform.environment['HOST'] ??
      const String.fromEnvironment('HOST', defaultValue: '127.0.0.1');
  if (address is String) return InternetAddress.tryParse(address) ?? address;
  if (address is InternetAddress) return address;
  throw ArgumentError.value(
    address,
    'hostname',
    'Must be a String or InternetAddress',
  );
}
