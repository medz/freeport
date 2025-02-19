# freeport

A Dart library for finding available network ports. Supports preferred ports, custom hostnames and port availability checking.

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  freeport: ^1.0.0
```

## Usage

### Finding a free port

```dart
// Get any free port
var port = await freePort();

// Try preferred ports first
var port = await freePort(preferred: [8080, 8081]);

// Specify hostname
var port = await freePort(hostname: '127.0.0.1');
```

### Checking port availability

```dart
if (await isAvailablePort(8080)) {
  print('Port 8080 is available');
}
```

### Custom hostname

The hostname parameter can be:
- An InternetAddress object
- A String IP address
- null (uses HOST env var or loopback)

```dart
// Using string IP
var port = await freePort(hostname: '192.168.1.1');

// Using InternetAddress
var address = InternetAddress('127.0.0.1');
var port = await freePort(hostname: address);
```

## Environment Variables

- `HOST` - Default hostname to use when none specified

## License

MIT
