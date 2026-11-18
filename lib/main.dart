import 'package:flutter/material.dart';

import 'app/app_container.dart';
import 'app/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final container = AppContainer.produccion();
  // Archivos de envíos anteriores; sin esperar, para no frenar el arranque
  // (D-022).
  container.compartir.limpiarTemporales();
  runApp(BitacoraApp(router: AppRouter(container)));
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
