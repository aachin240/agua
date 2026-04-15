import 'package:flutter/material.dart';

import '../controllers/controlador_lectura.dart';
import '../models/lectura.dart';
import '../models/usuario_sesion.dart';
import '../services/device/servicio_ubicacion.dart';
import '../services/local/servicio_lectura_local.dart';
import '../services/servicio_lectura.dart';
import 'pantalla_lectura.dart';

class PantallaSincronizacion extends StatefulWidget {
  final UsuarioSesion usuarioSesion;

  const PantallaSincronizacion({
    super.key,
    required this.usuarioSesion,
  });

  @override
  State<PantallaSincronizacion> createState() => _PantallaSincronizacionState();
}

class _PantallaSincronizacionState extends State<PantallaSincronizacion> {
  late final ControladorLectura controlador;
  final ServicioLecturaLocal servicioLecturaLocal = ServicioLecturaLocal();

  bool cargando = true;
  bool sincronizando = false;
  String mensaje = '';
  String progreso = '';

  List<Lectura> pendientes = [];
  List<Lectura> sincronizadas = [];
  List<Lectura> conflictos = [];
  List<Lectura> errores = [];

  String get usernameOwner => widget.usuarioSesion.username;

  @override
  void initState() {
    super.initState();
    controlador = ControladorLectura(
      servicioRemoto: ServicioLectura(),
      servicioLocal: servicioLecturaLocal,
      servicioUbicacion: ServicioUbicacion(),
    );
    cargarEstado();
  }

  Future<void> cargarEstado() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final pendientesData =
      await servicioLecturaLocal.obtenerPendientesSync(usernameOwner: usernameOwner);
      final sincronizadasData =
      await servicioLecturaLocal.obtenerSincronizadas(usernameOwner);
      final conflictosData =
      await servicioLecturaLocal.obtenerConflictos(usernameOwner);
      final erroresData =
      await servicioLecturaLocal.obtenerErrores(usernameOwner);

      if (!mounted) return;

      setState(() {
        pendientes = pendientesData;
        sincronizadas = sincronizadasData;
        conflictos = conflictosData;
        errores = erroresData;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        mensaje = 'No se pudo cargar la sincronización: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> sincronizarAhora() async {
    setState(() {
      sincronizando = true;
      progreso = '';
      mensaje = '';
    });

    final resultado = await controlador.sincronizarPendientes(
      usernameOwner: usernameOwner,
      onProgress: (actual, total) {
        if (!mounted) return;
        setState(() {
          progreso = 'Sincronizando $actual de $total';
        });
      },
    );

    await cargarEstado();

    if (!mounted) return;

    setState(() {
      sincronizando = false;
      progreso = '';
      mensaje =
      '${resultado.mensaje}. Exitosas: ${resultado.exitosas}, Errores: ${resultado.errores}, Conflictos: ${resultado.conflictos}';
    });
  }

  void abrirRuta(Lectura item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PantallaLectura(
          usuarioSesion: widget.usuarioSesion,
          rutaFiltro: item.ruta,
        ),
      ),
    );
  }

  Widget buildResumen() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Pendientes: ${pendientes.length}')),
            Chip(label: Text('Sincronizadas: ${sincronizadas.length}')),
            Chip(label: Text('Conflictos: ${conflictos.length}')),
            Chip(label: Text('Errores: ${errores.length}')),
          ],
        ),
      ),
    );
  }

  Widget buildSeccion({
    required String titulo,
    required List<Lectura> items,
    required Widget Function(Lectura item) itemBuilder,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        title: Text(
          '$titulo (${items.length})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: items.isEmpty
            ? [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Sin registros'),
            ),
          )
        ]
            : items.map(itemBuilder).toList(),
      ),
    );
  }

  Widget buildItemBase(Lectura item, {List<Widget>? acciones}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.codigoCuenta.isNotEmpty
                ? 'Cuenta ${item.codigoCuenta}'
                : 'Medidor ${item.numeroMedidor}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Medidor: ${item.numeroMedidor}'),
          Text('Ruta: ${item.ruta ?? "-"}'),
          Text('Fecha: ${item.fechaLectura ?? "-"}'),
          if ((item.syncError ?? '').trim().isNotEmpty)
            Text('Detalle: ${item.syncError}'),
          if (acciones != null && acciones.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: acciones,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cargarEstado,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildResumen(),
            const SizedBox(height: 12),
            if (mensaje.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(mensaje),
              ),
            if (mensaje.isNotEmpty) const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (progreso.isNotEmpty) ...[
                      Text(
                        progreso,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (cargando || sincronizando || pendientes.isEmpty)
                            ? null
                            : sincronizarAhora,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(
                          sincronizando ? 'Sincronizando...' : 'Sincronizar ahora',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (cargando)
              const Center(child: CircularProgressIndicator())
            else ...[
              buildSeccion(
                titulo: 'Lecturas pendientes',
                items: pendientes,
                itemBuilder: (item) => buildItemBase(item),
              ),
              const SizedBox(height: 12),
              buildSeccion(
                titulo: 'Lecturas sincronizadas',
                items: sincronizadas,
                itemBuilder: (item) => buildItemBase(item),
              ),
              const SizedBox(height: 12),
              buildSeccion(
                titulo: 'Conflictos',
                items: conflictos,
                itemBuilder: (item) => buildItemBase(item),
              ),
              const SizedBox(height: 12),
              buildSeccion(
                titulo: 'Errores',
                items: errores,
                itemBuilder: (item) => buildItemBase(
                  item,
                  acciones: [
                    OutlinedButton.icon(
                      onPressed: sincronizando ? null : sincronizarAhora,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => abrirRuta(item),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Revisar lectura'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}