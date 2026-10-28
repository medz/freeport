# Freeport

[![pub package](https://img.shields.io/pub/v/freeport.svg)](https://pub.dev/packages/freeport)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/medz/freeport/blob/main/LICENSE)
[![Tests](https://github.com/medz/freeport/actions/workflows/test.yml/badge.svg)](https://github.com/medz/freeport/actions/workflows/test.yml)

A small Dart library for finding available TCP ports. Two functions, no runtime
dependencies. Requires Dart 3.5 or later and a platform that supports `dart:io`.

## Installation

```sh
dart pub add freeport
```

Or add the dependency to `pubspec.yaml`:

```yaml
dependencies:
  freeport: ^1.0.1
```

## Usage

```dart
import 'package:freeport/freeport.dart';

Future<void> main() async {
  final port = await freePort();
  print('Available port: $port');

  final preferred = await freePort(
    preferred: [8080, 8081],
    hostname: 'localhost',
  );
  print('Preferred or system-assigned port: $preferred');

  if (await isAvailablePort(8080, hostname: '127.0.0.1')) {
    print('Port 8080 is available on IPv4 loopback');
  }
}
```

## API

```dart
Future<int> freePort({Iterable<int>? preferred, Object? hostname})
Future<bool> isAvailablePort(int port, {Object? hostname})
```

`freePort` tries candidates in iteration order and returns the first available
port. Each probe is closed before the next begins. It skips zero entries in
`preferred`; if the iterable is absent, empty, or has no available candidate,
the operating system assigns a port by binding to `0`.

`isAvailablePort` binds and closes a TCP socket to check availability. Passing
`0` checks whether the system can assign a port on the requested address. It
does not identify a particular port.

Ports must be between `0` and `65535`. An out-of-range port encountered during
probing throws `ArgumentError`. `isAvailablePort` returns `false` for a bind or
name-resolution `SocketException`; other errors propagate. `freePort` skips
candidates whose bind fails and throws if its final system-assigned bind fails.

### Addresses

Both functions accept a String hostname or IP address, or an `InternetAddress`:

```dart
await freePort(hostname: '127.0.0.1');
await freePort(hostname: '::1');
await freePort(hostname: 'localhost');
```

String names are resolved by Dart's
[`ServerSocket.bind`](https://api.dart.dev/dart-io/ServerSocket/bind.html), which
uses the first resolved address. The address must belong to the local machine;
this library does not scan ports on remote hosts. An invalid hostname is not
silently replaced with loopback. Unsupported argument types throw `ArgumentError`.

The address is selected in this order:

1. The explicit `hostname` argument.
2. The process environment variable `HOST`.
3. The compile-time `HOST` value supplied with `-DHOST=...`.
4. IPv4 loopback, `127.0.0.1`.

```sh
HOST=127.0.0.1 dart run example/main.dart
```

### Availability is not a reservation

Both functions close their probe before returning. Another process can take the
port between the check and your own bind. Use the same address for probing and
binding, and handle bind failures.

If you control the server, let the operating system assign its port directly
and keep the socket open:

```dart
import 'dart:io';

Future<void> main() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  try {
    print('Listening on ${server.port}');
    // Handle connections here while the socket stays open.
  } finally {
    await server.close();
  }
}
```

## Development

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings .
dart test
```

CI tests stable Dart on Linux, macOS, and Windows, plus Dart 3.5 on Linux.
Formatting and static analysis run once on stable Linux.

## License

[MIT](https://github.com/medz/freeport/blob/main/LICENSE)
