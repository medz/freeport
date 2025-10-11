# Freeport

[![pub package](https://img.shields.io/pub/v/freeport.svg)](https://pub.dev/packages/freeport)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Tests](https://github.com/medz/freeport/actions/workflows/test.yml/badge.svg)](https://github.com/medz/freeport/actions/workflows/test.yml)

A fast and reliable Dart library for finding available network ports with parallel checking and custom hostname support.

## Features

✨ **Zero Dependencies** - Lightweight library with no external dependencies
🚀 **Parallel Port Checking** - Check multiple ports simultaneously for optimal performance
🎯 **Preferred Port Selection** - Try specific ports first with intelligent fallback
🌐 **Custom Hostname Support** - Bind to specific network interfaces or IP addresses
⚡ **Smart Two-Stage Strategy** - Combines speed and reliability for port detection
🔧 **Environment Variable Support** - Configure defaults via environment variables

## Installation

Add freeport to your `pubspec.yaml`:

```yaml
dependencies:
  freeport: ^0.0.2
```

Or install via command line:

```bash
dart pub add freeport
```

## Quick Start

```dart
import 'package:freeport/freeport.dart';

void main() async {
  // Find any available port
  final port = await freePort();
  print('Available port: $port');

  // Try preferred ports first
  final preferredPort = await freePort(preferred: [8080, 8081, 8082]);
  print('Got port: $preferredPort');
}
```

## API Reference

### `freePort()`

Find an available network port.

```dart
Future<int> freePort({
  List<int>? preferred,
  dynamic hostname,
})
```

**Parameters:**
- `preferred` - List of ports to try first (optional)
- `hostname` - Target hostname/IP address (optional, defaults to loopback)

**Returns:** An available port number

**Examples:**

```dart
// Get any free port
final port = await freePort();

// Try preferred ports in order
final port = await freePort(preferred: [3000, 3001, 3002]);

// Specify custom hostname
final port = await freePort(hostname: '192.168.1.100');

// Combine options
final port = await freePort(
  preferred: [8080, 8081],
  hostname: '127.0.0.1'
);
```

### `isAvailablePort()`

Check if a specific port is available.

```dart
Future<bool> isAvailablePort(
  int port, {
  dynamic hostname,
})
```

**Parameters:**
- `port` - Port number to check
- `hostname` - Target hostname/IP address (optional)

**Returns:** `true` if port is available, `false` otherwise

**Examples:**

```dart
// Check default hostname
if (await isAvailablePort(8080)) {
  print('Port 8080 is free');
}

// Check specific hostname
if (await isAvailablePort(8080, hostname: '192.168.1.1')) {
  print('Port 8080 is free on 192.168.1.1');
}
```

## Advanced Usage

### Working with Different Hostname Types

The `hostname` parameter accepts multiple types:

```dart
import 'dart:io';

// String IP address
await freePort(hostname: '192.168.1.1');

// InternetAddress object
final address = InternetAddress('127.0.0.1');
await freePort(hostname: address);

// IPv6 address
await freePort(hostname: '::1');

// Hostname resolution
await freePort(hostname: 'localhost');
```

### Environment Configuration

Set default hostname via environment variable:

```bash
export HOST=192.168.1.100
```

```dart
// Will use HOST environment variable if no hostname specified
final port = await freePort();
```

### Error Handling

```dart
try {
  final port = await freePort(preferred: [80, 443, 8080]);
  print('Using port: $port');
} catch (e) {
  print('Failed to find available port: $e');
}
```

## Performance

Freeport uses an intelligent two-stage checking strategy:

1. **Parallel Stage**: Simultaneously checks all preferred ports for maximum speed
2. **Sequential Stage**: Falls back to reliable sequential checking if needed

This approach provides the best balance of speed and reliability, especially when checking multiple preferred ports.

## Use Cases

- **Development Servers**: Find available ports for local development
- **Microservices**: Dynamic port allocation in containerized environments
- **Testing**: Avoid port conflicts in automated test suites
- **CLI Tools**: Build developer tools that need available ports
- **Docker/Kubernetes**: Dynamic service port assignment

## Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/medz/freeport/issues)
- 📖 **Documentation**: [pub.dev](https://pub.dev/packages/freeport)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/medz/freeport/discussions)
- ❤️ **Sponsor**: [GitHub Sponsors](https://github.com/sponsors/medz)

---

Made with ❤️ by [medz](https://github.com/medz)
