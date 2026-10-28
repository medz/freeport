import 'dart:io';

import 'package:freeport/freeport.dart';

Future<void> main(List<String> arguments) async {
  try {
    await IOOverrides.runZoned(
      () => freePort(hostname: arguments.isEmpty ? null : arguments.single),
      serverSocketBind: (address, port,
          {int backlog = 0, bool v6Only = false, bool shared = false}) async {
        print(address is InternetAddress ? address.address : address);
        throw const SocketException('Address captured');
      },
    );
  } on SocketException {
    // Inspect the chosen address without DNS lookups or real socket bindings.
  }
}
