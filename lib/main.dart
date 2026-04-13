import 'package:flutter/material.dart';

import 'models/usuario_sesion.dart';
import 'screens/pantalla_lectura.dart';
import 'screens/pantalla_login.dart';
import 'services/local/servicio_base_datos.dart';
import 'services/local/servicio_sesion.dart';
import 'screens/pantalla_seleccion_ruta.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioBaseDatos.instance.database;
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  Future<UsuarioSesion?> _cargarSesion() async {
    final servicioSesion = ServicioSesion();
    return servicioSesion.obtenerSesion();
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
            return PantallaSeleccionRuta(usuarioSesion: usuario);;
          }

          return const PantallaLogin();
        },
      ),
    );
  }
}