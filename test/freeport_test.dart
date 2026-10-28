import 'dart:async';
import 'dart:io';

import 'package:freeport/freeport.dart';
import 'package:test/test.dart';

void main() {
  final loopback = InternetAddress.loopbackIPv4;

  group('freePort', () {
    for (final preferred in <Iterable<int>?>[
      null,
      [],
      [0]
    ]) {
      test('returns a usable port for preferred: $preferred', () async {
        final port = await freePort(preferred: preferred, hostname: loopback);
        expect(port, inInclusiveRange(1, 65535));
        await _bind(loopback, port);
      });
    }

    test('skips occupied candidates and zero entries', () async {
      final occupied = await _bind(loopback, 0);
      final available = await _bind(loopback, 0);
      final preferred = available.port;
      await available.close();

      final port = await freePort(
        preferred: [0, occupied.port, preferred],
        hostname: loopback,
      );
      expect(port, preferred);
      await _bind(loopback, port);
    });

    test('falls back when all candidates are occupied', () async {
      final occupied = await _bind(loopback, 0);
      final port = await freePort(
        preferred: [occupied.port],
        hostname: loopback,
      );
      expect(port, isNot(occupied.port));
      await _bind(loopback, port);
    });

    test('waits for the first candidate to close before returning', () async {
      final closing = Completer<void>();
      final release = Completer<void>();
      addTearDown(() {
        if (!release.isCompleted) release.complete();
      });
      final attempts = <int>[];
      final first = _TestSocket(31001, onClose: () async {
        closing.complete();
        await release.future;
      });
      var completed = false;

      final result = IOOverrides.runZoned(
        () => freePort(preferred: [31001, 31002]).then((port) {
          completed = true;
          return port;
        }),
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          attempts.add(port);
          return port == 31001 ? first : _TestSocket(port);
        },
      );

      await closing.future;
      expect(completed, isFalse);
      expect(attempts, [31001]);
      release.complete();
      expect(await result, 31001);
      expect(first.closed, isTrue);
      expect(attempts, [31001]);
    });

    test('probes each candidate once before the final bind', () async {
      final attempts = <int>[];
      final assigned = _TestSocket(45000);
      final port = await IOOverrides.runZoned(
        () => freePort(preferred: [31001, 31002]),
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          attempts.add(port);
          if (port != 0) throw const SocketException('Address in use');
          return assigned;
        },
      );
      expect(port, 45000);
      expect(attempts, [31001, 31002, 0]);
      expect(assigned.closed, isTrue);
    });

    test('stops consuming a lazy iterable after a successful candidate',
        () async {
      Iterable<int> candidates() sync* {
        yield 31001;
        throw StateError('Should not request another candidate');
      }

      final port = await IOOverrides.runZoned(
        () => freePort(preferred: candidates()),
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          return _TestSocket(port);
        },
      );
      expect(port, 31001);
    });
  });

  group('isAvailablePort', () {
    test('releases the checked port', () async {
      final socket = await _bind(loopback, 0);
      final port = socket.port;
      await socket.close();

      expect(await isAvailablePort(port, hostname: loopback), isTrue);
      await _bind(loopback, port);
    });

    test('binds and closes a socket for port zero', () async {
      final socket = _TestSocket(45000);
      final attempts = <int>[];
      final available = await IOOverrides.runZoned(
        () => isAvailablePort(0),
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          attempts.add(port);
          return socket;
        },
      );
      expect(available, isTrue);
      expect(attempts, [0]);
      expect(socket.closed, isTrue);
    });

    for (final port in [0, 31001]) {
      test('returns false for a bind failure on port $port', () async {
        final available = await IOOverrides.runZoned(
          () => isAvailablePort(port, hostname: 'unavailable.invalid'),
          serverSocketBind: (address, port,
              {int backlog = 0,
              bool v6Only = false,
              bool shared = false}) async {
            throw const SocketException('Cannot bind or resolve this address');
          },
        );
        expect(available, isFalse);
      });
    }
  });

  group('addresses', () {
    for (final hostname in <Object>[
      loopback,
      '127.0.0.1',
      'localhost',
      InternetAddress.loopbackIPv6,
      '::1',
    ]) {
      test('finds and checks ports on $hostname', () async {
        final port = await freePort(hostname: hostname);
        final socket = await _bind(hostname, port);
        expect(await isAvailablePort(port, hostname: hostname), isFalse);
        await socket.close();
        expect(await isAvailablePort(port, hostname: hostname), isTrue);
      });
    }

    test('passes hostnames unchanged to the native binder', () async {
      final addresses = <Object>[];
      await IOOverrides.runZoned(
        () async {
          await freePort(hostname: 'local.test');
          await isAvailablePort(31001, hostname: 'local.test');
        },
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          addresses.add(address as Object);
          return _TestSocket(port == 0 ? 45000 : port);
        },
      );
      expect(addresses, ['local.test', 'local.test']);
    });

    test('propagates failure when the final bind cannot resolve the host',
        () async {
      final addresses = <Object>[];
      final result = IOOverrides.runZoned(
        () => freePort(preferred: [31001], hostname: 'unavailable.invalid'),
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          addresses.add(address as Object);
          throw const SocketException('Name resolution failed');
        },
      );
      await expectLater(result, throwsA(isA<SocketException>()));
      expect(addresses, ['unavailable.invalid', 'unavailable.invalid']);
    });
  });

  group('invalid arguments and unexpected errors', () {
    for (final port in [-1, 65536]) {
      test('rejects invalid port $port', () async {
        await expectLater(
          isAvailablePort(port, hostname: loopback),
          throwsArgumentError,
        );
        await expectLater(
          freePort(preferred: [port], hostname: loopback),
          throwsArgumentError,
        );
      });
    }

    test('rejects unsupported hostname types', () async {
      await expectLater(freePort(hostname: 42), throwsArgumentError);
      await expectLater(isAvailablePort(0, hostname: 42), throwsArgumentError);
    });

    test('does not hide unexpected binding errors', () async {
      await IOOverrides.runZoned(
        () async {
          await expectLater(isAvailablePort(31001), throwsStateError);
          await expectLater(freePort(preferred: [31001]), throwsStateError);
        },
        serverSocketBind: (address, port,
            {int backlog = 0, bool v6Only = false, bool shared = false}) async {
          throw StateError('Unexpected failure');
        },
      );
    });
  });

  group('address defaults', () {
    Future<String> probe(
        {String? host, String? define, String? explicit}) async {
      final environment = Map<String, String>.of(Platform.environment)
        ..remove('HOST');
      if (host != null) environment['HOST'] = host;
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          '--packages=${File('.dart_tool/package_config.json').absolute.path}',
          if (define != null) '-DHOST=$define',
          'test/fixtures/hostname.dart',
          if (explicit != null) explicit,
        ],
        environment: environment,
        includeParentEnvironment: false,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      return result.stdout.toString().trim();
    }

    test('defaults to IPv4 loopback', () async {
      expect(await probe(), '127.0.0.1');
    });

    test('uses the process HOST', () async {
      expect(await probe(host: 'runtime.test'), 'runtime.test');
    });

    test('uses the compile-time HOST', () async {
      expect(await probe(define: 'compiled.test'), 'compiled.test');
    });

    test('prefers the process HOST over the compile-time value', () async {
      expect(
        await probe(host: 'runtime.test', define: 'compiled.test'),
        'runtime.test',
      );
    });

    test('prefers an explicit hostname over either HOST value', () async {
      expect(
        await probe(
          host: 'runtime.test',
          define: 'compiled.test',
          explicit: 'explicit.test',
        ),
        'explicit.test',
      );
    });
  });
}

Future<ServerSocket> _bind(Object address, int port) async {
  final socket = await ServerSocket.bind(address, port);
  addTearDown(socket.close);
  return socket;
}

class _TestSocket implements ServerSocket {
  _TestSocket(this.port, {this.onClose});

  @override
  final int port;
  final Future<void> Function()? onClose;
  bool closed = false;

  @override
  Future<ServerSocket> close() async {
    await onClose?.call();
    closed = true;
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
