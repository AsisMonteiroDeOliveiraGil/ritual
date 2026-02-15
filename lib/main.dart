import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ritual/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await bootstrap();
}
