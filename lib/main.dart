import 'package:flutter/material.dart';
import 'app.dart';
import 'core/localization/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleController.instance.init();
  runApp(const SmritiCareApp());
}
