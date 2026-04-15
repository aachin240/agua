import 'package:flutter/material.dart';

import '../models/usuario_sesion.dart';
import '../services/local/servicio_usuario_local.dart';
import 'pantalla_lectura.dart';

class PantallaRutasActivas extends StatefulWidget {
  final UsuarioSesion usuarioSesion;

  const PantallaRutasActivas({
    super.key,
    required this.usuarioSesion,
  });

  @override
  State<PantallaRutasActivas> createState() => _PantallaRutasActivasState();
}

class _PantallaRutasActivasState extends State<PantallaRutasActivas> {
  final ServicioUsuarioLocal servicioUsuarioLocal = ServicioUsuarioLocal();

  bool cargando = true;
  String mensaje = '';
  List<int> rutasActivas = [];

  @override
  void initState() {
    super.initState();
    cargarRutasActivas();
  }

  Future<void> cargarRutasActivas() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final rutas = await servicioUsuarioLocal.obtenerRutasActivas(
        widget.usuarioSesion.username,
      );

      if (!mounted) return;

      setState(() {
        rutasActivas = rutas;
        if (rutas.isEmpty) {
          mensaje = 'No tienes rutas activas descargadas.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mensaje = 'No se pudieron cargar las rutas activas: $e';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });
    }
  }

  void abrirRuta(int ruta) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaLectura(
          usuarioSesion: widget.usuarioSesion,
          rutaFiltro: ruta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas activas'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarRutasActivas,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            else if (rutasActivas.isNotEmpty)
              ...rutasActivas.map(
                    (ruta) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.route),
                    ),
                    title: Text(
                      'Ruta $ruta',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Trabajar solo con esta ruta'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => abrirRuta(ruta),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}