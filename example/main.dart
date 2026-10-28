import 'package:freeport/freeport.dart';

Future<void> main() async {
  final port = await freePort(preferred: [8080, 8081]);
  print('Free port: $port');
}
