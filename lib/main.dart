import 'package:flutter/material.dart';

import 'models/usuario_sesion.dart';
import 'screens/pantalla_lectura.dart';
import 'screens/pantalla_login.dart';
import 'screens/pantalla_seleccion_ruta.dart';
import 'services/local/servicio_base_datos.dart';
import 'services/local/servicio_lectura_local.dart';
import 'services/local/servicio_sesion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServicioBaseDatos.instance.database;
  runApp(const MiApp());
}

class EstadoInicio {
  final UsuarioSesion? usuario;
  final bool tieneCuentasLocales;

  const EstadoInicio({
    required this.usuario,
    required this.tieneCuentasLocales,
  });
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  Future<EstadoInicio> _cargarEstadoInicio() async {
    final servicioSesion = ServicioSesion();
    final servicioLecturaLocal = ServicioLecturaLocal();

    final usuario = await servicioSesion.obtenerSesion();
    final tieneCuentasLocales = await servicioLecturaLocal.hayCuentasLocales();

    return EstadoInicio(
      usuario: usuario,
      tieneCuentasLocales: tieneCuentasLocales,
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

          if (estado.tieneCuentasLocales) {
            return PantallaLectura(usuarioSesion: estado.usuario!);
          }

          return PantallaSeleccionRuta(usuarioSesion: estado.usuario!);
        },
      ),
    );
  }
}