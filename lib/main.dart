import 'package:flutter/material.dart';

import 'models/usuario_sesion.dart';
import 'screens/pantalla_inicio_operativo.dart';
import 'screens/pantalla_login.dart';
import 'services/local/servicio_base_datos.dart';
import 'services/local/servicio_sesion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioBaseDatos.instance.database;
  runApp(const MiApp());
}

class EstadoInicio {
  final UsuarioSesion? usuario;

  const EstadoInicio({
    required this.usuario,
  });
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  Future<EstadoInicio> _cargarEstadoInicio() async {
    final servicioSesion = ServicioSesion();
    final usuario = await servicioSesion.obtenerSesion();

    return EstadoInicio(
      usuario: usuario,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<EstadoInicio>(
        future: _cargarEstadoInicio(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final estado = snapshot.data;

          if (estado == null || estado.usuario == null) {
            return const PantallaLogin();
          }

          return PantallaInicioOperativo(
            usuarioSesion: estado.usuario!,
          );
        },
      ),
    );
  }
}