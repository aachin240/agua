import 'package:flutter/material.dart';

import '../models/usuario_sesion.dart';
import '../services/local/servicio_lectura_local.dart';
import '../services/local/servicio_usuario_local.dart';
import 'pantalla_lectura.dart';
import 'pantalla_rutas_activas.dart';
import 'pantalla_seleccion_ruta.dart';

class PantallaInicioOperativo extends StatefulWidget {
  final UsuarioSesion usuarioSesion;

  const PantallaInicioOperativo({
    super.key,
    required this.usuarioSesion,
  });

  @override
  State<PantallaInicioOperativo> createState() => _PantallaInicioOperativoState();
}

class _PantallaInicioOperativoState extends State<PantallaInicioOperativo> {
  final ServicioUsuarioLocal servicioUsuarioLocal = ServicioUsuarioLocal();
  final ServicioLecturaLocal servicioLecturaLocal = ServicioLecturaLocal();

  bool cargando = true;
  String mensaje = '';

  List<int> rutasActivas = [];
  int pendientes = 0;
  int errores = 0;

  String get usernameOwner => widget.usuarioSesion.username;

  @override
  void initState() {
    super.initState();
    cargarEstado();
  }

  Future<void> cargarEstado() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final rutas = await servicioUsuarioLocal.obtenerRutasActivas(usernameOwner);
      final pendientesUsuario = await servicioLecturaLocal.contarPendientes(usernameOwner);
      final erroresUsuario = await servicioLecturaLocal.contarErrores(usernameOwner);

      if (!mounted) return;

      setState(() {
        rutasActivas = rutas;
        pendientes = pendientesUsuario;
        errores = erroresUsuario;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mensaje = 'No se pudo cargar el entorno local: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> continuarConRutasActivas() async {
    if (rutasActivas.isEmpty) {
      setState(() {
        mensaje = 'No tienes rutas activas descargadas. Debes gestionar rutas primero.';
      });
      return;
    }

    if (rutasActivas.length == 1) {
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PantallaLectura(
            usuarioSesion: widget.usuarioSesion,
            rutaFiltro: rutasActivas.first,
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaRutasActivas(
          usuarioSesion: widget.usuarioSesion,
        ),
      ),
    );
  }

  Future<void> abrirSincronizacionYLecturas() async {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaLectura(
          usuarioSesion: widget.usuarioSesion,
        ),
      ),
    );
  }

  Future<void> gestionarRutas() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaSeleccionRuta(
          usuarioSesion: widget.usuarioSesion,
        ),
      ),
    );

    await cargarEstado();
  }

  Widget _tarjetaAccion({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: cargando ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(icono),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      descripcion,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(height: 10),
                      trailing,
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color ?? Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rutasTexto = rutasActivas.isEmpty
        ? 'Sin rutas activas'
        : rutasActivas.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio operativo'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarEstado,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.account_circle, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      widget.usuarioSesion.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.usuarioSesion.username,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Rutas activas: $rutasTexto'),
                        ),
                        Chip(
                          label: Text('Pendientes: $pendientes'),
                        ),
                        Chip(
                          label: Text('Errores: $errores'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (mensaje.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(mensaje),
              ),
            if (mensaje.isNotEmpty) const SizedBox(height: 16),
            if (cargando)
              const Center(child: CircularProgressIndicator())
            else ...[
              _tarjetaAccion(
                icono: Icons.route,
                titulo: 'Continuar con rutas activas',
                descripcion: rutasActivas.isEmpty
                    ? 'No tienes rutas activas descargadas'
                    : rutasActivas.length == 1
                    ? 'Entrar directamente a la ruta ${rutasActivas.first}'
                    : 'Elegir una de tus rutas activas descargadas',
                onTap: continuarConRutasActivas,
              ),
              _tarjetaAccion(
                icono: Icons.sync,
                titulo: 'Sincronizar pendientes',
                descripcion:
                'Abrir el módulo actual de lecturas y sincronización para revisar pendientes, conflictos y errores.',
                onTap: abrirSincronizacionYLecturas,
                trailing: Row(
                  children: [
                    Chip(label: Text('Pendientes: $pendientes')),
                    const SizedBox(width: 8),
                    Chip(label: Text('Errores: $errores')),
                  ],
                ),
              ),
              _tarjetaAccion(
                icono: Icons.playlist_add_check,
                titulo: 'Gestionar rutas',
                descripcion:
                'Consultar, agregar o cambiar rutas. Requiere conexión si deseas descargar nuevas rutas.',
                onTap: gestionarRutas,
              ),
            ],
          ],
        ),
      ),
    );
  }
}