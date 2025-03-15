# freeport

A Dart library for finding available network ports. Supports preferred ports, custom hostnames and port availability checking with optimized performance.

[![pub package](https://img.shields.io/pub/v/freeport.svg)](https://pub.dev/packages/freeport)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- Find any available port on a specific host
- Try preferred ports with parallel checking for better performance
- Check if a specific port is available
- Support for custom hostnames/IP addresses
- Environment variable configuration

## Installation

To install `freeport`, run the command:

```bash
dart pub add freeport
```

## Usage

### Finding a free port

```dart
// Get any free port
final port = await freePort();

// Try preferred ports first (with optimized parallel checking)
final port = await freePort(preferred: [8080, 8081, 8082, 8083]);

// Specify hostname
final port = await freePort(hostname: '127.0.0.1');
```

### Checking port availability

```dart
if (await isAvailablePort(8080)) {
  print('Port 8080 is available');
}

// Check on a specific host
if (await isAvailablePort(8080, hostname: '192.168.1.1')) {
  print('Port 8080 is available on 192.168.1.1');
}
```

### Custom hostname

The hostname parameter can be:

- An `InternetAddress` object
- A String IP address
- `null` (uses HOST env var or loopback)

```dart
// Using string IP
final port = await freePort(hostname: '192.168.1.1');

// Using InternetAddress
final address = InternetAddress('127.0.0.1');
final port = await freePort(hostname: address);
```

## Performance Optimization

The `freePort` function uses a two-stage port checking strategy:

1. First attempts parallel checking of all preferred ports for maximum speed
2. Falls back to sequential checking if needed for reliability

This approach significantly improves performance when checking multiple preferred ports.

## Environment Variables

- `HOST` - Default hostname to use when none specified

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
