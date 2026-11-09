import 'package:flutter/material.dart';

import 'app/app_container.dart';
import 'app/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final router = AppRouter(AppContainer.produccion());
  runApp(BitacoraApp(router: router));
}

class BitacoraApp extends StatelessWidget {
  final AppRouter router;

  const BitacoraApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitácora de Campo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      initialRoute: AppRoutes.lista,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
