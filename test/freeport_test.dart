import 'dart:io';
import 'package:freeport/freeport.dart';
import 'package:test/test.dart';

void main() {
  group('isAvailablePort', () {
    test('returns true for available port', () async {
      // Get a free port to ensure it's available
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      // Close the socket to make the port available
      await socket.close();

      // Now test if the port is available
      expect(await isAvailablePort(port), isTrue);
    });

    test('returns false for in-use port', () async {
      // Bind to a port
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      // Port should not be available while socket is open
      expect(await isAvailablePort(port), isFalse);

      // Clean up
      await socket.close();
    });

    test('accepts custom hostname', () async {
      // Test with explicit loopback address
      expect(
        await isAvailablePort(0, hostname: InternetAddress.loopbackIPv4),
        isTrue,
      );

      // Test with string address
      expect(
        await isAvailablePort(0, hostname: '127.0.0.1'),
        isTrue,
      );
    });

    test('works with port 0', () async {
      // Port 0 should always return available (system assigns random port)
      expect(await isAvailablePort(0), isTrue);
    });
  });

  group('freePort', () {
    test('returns a valid port', () async {
      final port = await freePort();
      expect(port, greaterThan(0));
      expect(port, lessThan(65536)); // Valid port range

      // Verify the port is actually available
      final socket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      expect(socket.port, equals(port));

      // Clean up
      await socket.close();
    });

    test('honors preferred ports when available', () async {
      const preferredPort = 31456; // Choose an uncommon port that's likely free

      // First make sure the port is actually available
      final isAvailable = await isAvailablePort(preferredPort);
      if (!isAvailable) {
        // Skip test if port is unexpectedly in use
        return;
      }

      final port = await freePort(preferred: [preferredPort]);
      expect(port, equals(preferredPort));
    });

    test('falls back to other ports when preferred not available', () async {
      // Bind to a port to make it unavailable
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final inUsePort = socket.port;

      // Try to get the in-use port as preferred
      final port = await freePort(preferred: [inUsePort]);

      // Should get a different port
      expect(port, isNot(equals(inUsePort)));
      expect(port, greaterThan(0));

      // Clean up
      await socket.close();
    });

    test('tries all preferred ports', () async {
      // Bind to one port to make it unavailable
      final socket1 = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final inUsePort = socket1.port;

      // Choose another port that should be available
      final preferredPort = inUsePort + 1;

      // First make sure the port is actually available
      final isAvailable = await isAvailablePort(preferredPort);
      if (!isAvailable) {
        // Clean up and skip test if port is unexpectedly in use
        await socket1.close();
        return;
      }

      // Try to get ports with first one unavailable
      final port = await freePort(preferred: [inUsePort, preferredPort]);

      // Should get the second port
      expect(port, equals(preferredPort));

      // Clean up
      await socket1.close();
    });

    test('accepts custom hostname', () async {
      final port = await freePort(hostname: '127.0.0.1');
      expect(port, greaterThan(0));

      // Verify we can bind to this port on the specified host
      final socket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      expect(socket.port, equals(port));

      // Clean up
      await socket.close();
    });

    test('parallel checking works correctly', () async {
      // Create several server sockets for testing
      final sockets = <ServerSocket>[];
      final inUsePorts = <int>[];

      // Create 3 server sockets
      for (var i = 0; i < 3; i++) {
        final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        sockets.add(socket);
        inUsePorts.add(socket.port);
      }

      // Find 3 free ports
      final freePorts = <int>[];
      for (var i = 0; i < 3; i++) {
        final freePort = inUsePorts[i] + 1;
        // Ensure the port is actually available
        if (await isAvailablePort(freePort)) {
          freePorts.add(freePort);
        }
      }

      // Skip test if we couldn't find enough free ports
      if (freePorts.length < 3) {
        for (final socket in sockets) {
          await socket.close();
        }
        return;
      }

      // Create a list of preferred ports: first all in-use ports, then free ports
      final preferredPorts = [...inUsePorts, ...freePorts];

      // The function should find the first free port
      final port = await freePort(preferred: preferredPorts);

      // Should match first free port due to parallel checking
      expect(port, equals(freePorts.first));

      // Clean up
      for (final socket in sockets) {
        await socket.close();
      }
    });
  });
}
