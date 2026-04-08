import 'package:flutter/material.dart';

import 'models/usuario_sesion.dart';
import 'screens/lectura_screen.dart';
import 'screens/login_screen.dart';
import 'services/local/database_service.dart';
import 'services/local/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<UsuarioSesion?> _cargarSesion() async {
    final sessionService = SessionService();
    return sessionService.obtenerSesion();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<UsuarioSesion?>(
        future: _cargarSesion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final usuario = snapshot.data;

          if (usuario != null) {
            return LecturaScreen(usuarioSesion: usuario);
          }

          return const LoginScreen();
        },
      ),
    );
  }
}