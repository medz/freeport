import 'package:freeport/freeport.dart';

main() async {
  final port = await freePort();
  print('Free port: $port');
}
