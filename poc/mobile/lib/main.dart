import 'package:flutter/material.dart';

import 'config/dependencies.dart';
import 'ui/core/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.production();
  runApp(FirstAidApp(dependencies: dependencies));
}
