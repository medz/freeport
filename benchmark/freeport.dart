import 'dart:convert';
import 'dart:io';

import 'package:freeport/freeport.dart';

Future<void> main() async {
  const warmup = 12;
  const samples = 80;
  print(jsonEncode({
    'sdk': Platform.version,
    'os': Platform.operatingSystem,
    'warmup': warmup,
    'samples': samples,
    'units': 'microseconds per call',
  }));

  for (final hostname in ['127.0.0.1', 'localhost']) {
    final address = (await InternetAddress.lookup(hostname)).first;
    final sockets = <ServerSocket>[];
    try {
      for (var i = 0; i < 64; i++) {
        sockets.add(await ServerSocket.bind(address, 0));
      }
      final occupied = sockets.map((socket) => socket.port).toList();
      final available = await ServerSocket.bind(address, 0);
      final free = available.port;
      await available.close();

      final cases = <String, List<int>>{
        'no candidates': [],
        'first candidate available': [free, ...occupied],
        '8 occupied candidates': occupied.take(8).toList(),
        '64 occupied candidates': occupied,
        '64 occupied, then available': [...occupied, free],
      };
      for (final entry in cases.entries) {
        final timings = <int>[];
        for (var i = -warmup; i < samples; i++) {
          final watch = Stopwatch()..start();
          final port = await freePort(
            preferred: entry.value,
            hostname: hostname,
          );
          watch.stop();
          if (port == 0 ||
              occupied.contains(port) ||
              (entry.value.contains(free) && port != free)) {
            throw StateError('Unexpected port $port for ${entry.key}');
          }
          if (i >= 0) timings.add(watch.elapsedMicroseconds);
        }
        timings.sort();
        print(jsonEncode({
          'hostname': hostname,
          'address': address.address,
          'case': entry.key,
          'median_us': timings[samples ~/ 2],
          'p95_us': timings[(samples * 0.95).floor()],
        }));
      }
    } finally {
      await Future.wait(sockets.map((socket) => socket.close()));
    }
  }
}
