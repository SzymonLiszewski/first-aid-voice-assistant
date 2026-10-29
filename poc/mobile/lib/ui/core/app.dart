import 'package:flutter/material.dart';

import '../../config/dependencies.dart';
import '../../routing/router.dart';
import 'themes/theme.dart';

class FirstAidApp extends StatelessWidget {
  const FirstAidApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asystent pierwszej pomocy',
      theme: buildAppTheme(),
      initialRoute: Routes.start,
      onGenerateRoute: (route) => buildRoute(route, dependencies),
    );
  }
}
