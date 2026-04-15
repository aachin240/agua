import 'package:flutter/material.dart';

import '../models/usuario_sesion.dart';
import '../services/local/servicio_lectura_local.dart';
import '../services/local/servicio_sesion.dart';
import '../services/local/servicio_usuario_local.dart';
import '../services/servicio_autenticacion.dart';
import 'pantalla_inicio_operativo.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  final ServicioAutenticacion servicioAutenticacion = ServicioAutenticacion();
  final ServicioSesion servicioSesion = ServicioSesion();
  final ServicioUsuarioLocal servicioUsuarioLocal = ServicioUsuarioLocal();
  final ServicioLecturaLocal servicioLecturaLocal = ServicioLecturaLocal();

  bool cargando = false;
  String mensaje = '';
  bool ocultarClave = true;

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        mensaje = 'Ingresa usuario y clave';
      });
      return;
    }

    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final UsuarioSesion usuario = await servicioAutenticacion.login(
        username: username,
        password: password,
      );

      await servicioUsuarioLocal.guardarUsuarioAutorizado(
        usuario: usuario,
        clave: password,
      );

      await servicioSesion.guardarSesion(usuario);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PantallaInicioOperativo(usuarioSesion: usuario),
        ),
            (route) => false,
      );
      return;
    } catch (_) {
      try {
        final usuarioOffline = await servicioUsuarioLocal.validarLoginOffline(
          username: username,
          clave: password,
        );

        if (usuarioOffline == null) {
          throw Exception(
            'No se pudo iniciar sesión en línea y este usuario no está autorizado offline en este dispositivo.',
          );
        }

        final rutasActivas = await servicioUsuarioLocal.obtenerRutasActivas(
          usuarioOffline.username,
        );

        final hayCuentasLocales =
        await servicioLecturaLocal.hayCuentasLocalesDeUsuario(
          usuarioOffline.username,
        );

        if (!hayCuentasLocales || rutasActivas.isEmpty) {
          throw Exception(
            'El usuario está autorizado offline, pero no tiene rutas activas cargadas en este dispositivo.',
          );
        }

        await servicioSesion.guardarSesion(usuarioOffline);

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PantallaInicioOperativo(
              usuarioSesion: usuarioOffline,
            ),
          ),
              (route) => false,
        );
        return;
      } catch (offlineError) {
        if (!mounted) return;
        setState(() {
          mensaje = offlineError.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingreso'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop, size: 64),
                    const SizedBox(height: 10),
                    const Text(
                      'Módulo de Lecturas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: ocultarClave,
                      decoration: InputDecoration(
                        labelText: 'Clave',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              ocultarClave = !ocultarClave;
                            });
                          },
                          icon: Icon(
                            ocultarClave
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (mensaje.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(mensaje),
                      ),
                    if (mensaje.isNotEmpty) const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: cargando ? null : iniciarSesion,
                        icon: const Icon(Icons.login),
                        label: Text(
                          cargando ? 'Ingresando...' : 'Ingresar',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}