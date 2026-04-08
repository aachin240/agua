import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/lectura_controlador.dart';
import '../models/lectura.dart';
import '../services/device/servicio_foto.dart';
import '../services/device/servicio_ubicacion.dart';
import '../services/lectura_service.dart';
import '../services/local/lectura_local_service.dart';

class LecturaScreen extends StatefulWidget {
  const LecturaScreen({super.key});

  @override
  State<LecturaScreen> createState() => _LecturaScreenState();
}

class _LecturaScreenState extends State<LecturaScreen> {
  final LecturaService servicioRemoto = LecturaService();
  final LecturaLocalService servicioLocal = LecturaLocalService();
  final ServicioUbicacion servicioUbicacion = ServicioUbicacion();
  final ServicioFoto servicioFoto = ServicioFoto();

  late final LecturaControlador controlador;

  final TextEditingController medidorCtrl = TextEditingController();
  final TextEditingController lecturaActualCtrl = TextEditingController();
  final TextEditingController observacionCtrl = TextEditingController();

  int pendientesSync = 0;
  int erroresSync = 0;
  bool sincronizando = false;
  String progresoSync = '';
  List<Lectura> lecturasConError = [];

  Lectura? lectura;
  List<Lectura> lecturas = [];

  String mensaje = '';
  bool cargando = false;
  bool mostrarDetalle = false;
  bool mostrarFormularioGuardar = false;
  bool mostrarLista = true;

  String? fotoGuardadaPath;
  String? fotoFechaTomaExif;
  double? fotoLatitudExif;
  double? fotoLongitudExif;

  @override
  void initState() {
    super.initState();

    controlador = LecturaControlador(
      servicioRemoto: servicioRemoto,
      servicioLocal: servicioLocal,
      servicioUbicacion: servicioUbicacion,
    );

    cargarDatosIniciales();
  }

  @override
  void dispose() {
    medidorCtrl.dispose();
    lecturaActualCtrl.dispose();
    observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarResumenSync() async {
    final resumen = await controlador.obtenerResumenSincronizacion();

    if (!mounted) return;

    setState(() {
      pendientesSync = resumen.pendientes;
      erroresSync = resumen.errores;
      lecturasConError = resumen.conError;
    });
  }

  Future<void> sincronizarAhora() async {
    setState(() {
      sincronizando = true;
      progresoSync = '';
      mensaje = '';
    });

    final resultado = await controlador.sincronizarPendientes(
      onProgress: (actual, total) {
        if (!mounted) return;
        setState(() {
          progresoSync = 'Sincronizando $actual de $total';
        });
      },
    );

    await listarTodo();
    await cargarResumenSync();

    if (!mounted) return;

    setState(() {
      sincronizando = false;
      progresoSync = '';
      mensaje =
      '${resultado.mensaje}. '
          'Exitosas: ${resultado.exitosas}, '
          'Errores: ${resultado.errores}, '
          'Conflictos: ${resultado.conflictos}';
    });
  }

  void limpiarFotoTemporal() {
    fotoGuardadaPath = null;
    fotoFechaTomaExif = null;
    fotoLatitudExif = null;
    fotoLongitudExif = null;
  }

  void limpiarFormulario() {
    lecturaActualCtrl.clear();
    observacionCtrl.clear();
    limpiarFotoTemporal();
  }

  Future<void> cargarDatosIniciales() async {
    setState(() {
      cargando = true;
      mensaje = '';
      mostrarLista = true;
      mostrarDetalle = false;
      mostrarFormularioGuardar = false;
      lectura = null;
    });

    final resultado = await controlador.cargarDatosIniciales();
    await cargarResumenSync();

    if (!mounted) return;

    setState(() {
      cargando = false;
      mensaje = resultado.mensaje;
      lecturas = resultado.lecturas ?? [];
    });
  }

  Future<void> listarTodo() async {
    setState(() {
      cargando = true;
      mostrarLista = true;
      mostrarDetalle = false;
      mostrarFormularioGuardar = false;
      lectura = null;
      mensaje = '';
      limpiarFormulario();
    });

    final resultado = await controlador.listarDesdeBaseLocal();
    await cargarResumenSync();

    if (!mounted) return;

    setState(() {
      cargando = false;
      mensaje = resultado.mensaje;
      lecturas = resultado.lecturas ?? [];
    });
  }

  Future<void> buscar() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    final resultado = await controlador.buscarPorMedidor(medidorCtrl.text);

    if (!mounted) return;

    setState(() {
      cargando = false;
      mensaje = resultado.mensaje;

      if (resultado.ok && resultado.lectura != null) {
        lectura = resultado.lectura;
        mostrarLista = false;
        mostrarDetalle = true;
        mostrarFormularioGuardar = false;
        lecturaActualCtrl.clear();
        observacionCtrl.clear();
        limpiarFotoTemporal();
      } else {
        lectura = null;
        mostrarDetalle = false;
        mostrarFormularioGuardar = false;
      }
    });
  }

  Future<void> tomarFoto() async {
    setState(() {
      mensaje = '';
    });

    try {
      final posicion = await servicioUbicacion.obtenerUbicacionActual();

      final resultado = await servicioFoto.tomarYPrepararFoto(
        latitudActual: posicion.latitude,
        longitudActual: posicion.longitude,
      );

      if (resultado == null || !mounted) return;

      setState(() {
        fotoGuardadaPath = resultado.rutaFotoGuardada;
        fotoFechaTomaExif = resultado.fechaToma;
        fotoLatitudExif = resultado.latitud;
        fotoLongitudExif = resultado.longitud;
        mensaje = 'Foto tomada correctamente';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        mensaje = 'Error al tomar la foto: $e';
      });
    }
  }

  Future<void> guardarLecturaOffline() async {
    setState(() {
      cargando = true;
      mensaje = '';
    });

    final resultado = await controlador.guardarLecturaOffline(
      cuenta: lectura,
      numeroMedidor: medidorCtrl.text,
      textoLecturaActual: lecturaActualCtrl.text,
      fotoPathLocal: fotoGuardadaPath,
      observacion: observacionCtrl.text.trim().isEmpty
          ? null
          : observacionCtrl.text.trim(),
    );

    if (resultado.ok) {
      await cargarResumenSync();
    }

    if (!mounted) return;

    setState(() {
      cargando = false;
      mensaje = resultado.mensaje;

      if (resultado.ok) {
        lectura = resultado.lectura;
        mostrarLista = false;
        mostrarDetalle = true;
        mostrarFormularioGuardar = false;
        limpiarFormulario();
      }
    });
  }

  Widget buildInfoRow(String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor == null || valor.toString().trim().isEmpty
                  ? '-'
                  : valor.toString(),
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard({
    required String titulo,
    required Widget child,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  String tituloTarjeta(Lectura item) {
    if (item.codigoCuenta.trim().isNotEmpty) {
      return 'Cuenta ${item.codigoCuenta}';
    }
    return 'Medidor ${item.numeroMedidor}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturas de agua'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (mostrarLista) {
            await listarTodo();
          } else if (medidorCtrl.text.trim().isNotEmpty) {
            await buscar();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildCard(
              titulo: 'Buscar medidor',
              icon: Icons.search,
              child: Column(
                children: [
                  TextField(
                    controller: medidorCtrl,
                    decoration: InputDecoration(
                      labelText: 'Número de medidor',
                      prefixIcon: const Icon(Icons.water_drop_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: cargando ? null : buscar,
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: cargando ? null : listarTodo,
                          icon: const Icon(Icons.list),
                          label: const Text('Listar todo'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(mensaje),
              ),
            ],
            const SizedBox(height: 16),
            buildCard(
              titulo: 'Sincronización',
              icon: Icons.sync,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildInfoRow('Pendientes', pendientesSync),
                  buildInfoRow('Errores', erroresSync),
                  if (progresoSync.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      progresoSync,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (cargando || sincronizando || pendientesSync == 0)
                          ? null
                          : sincronizarAhora,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(
                        sincronizando ? 'Sincronizando...' : 'Sincronizar ahora',
                      ),
                    ),
                  ),
                  if (lecturasConError.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Lecturas con novedades',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...lecturasConError.map(
                          (e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medidor: ${e.numeroMedidor}'),
                            Text('Fecha: ${e.fechaLectura ?? "-"}'),
                            Text('Error: ${e.syncError ?? "Error no identificado"}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (mostrarDetalle && lectura != null) ...[
              const SizedBox(height: 16),
              buildCard(
                titulo: 'Datos de la cuenta',
                icon: Icons.description_outlined,
                child: Column(
                  children: [
                    buildInfoRow('ID cuenta', lectura!.idCuenta),
                    buildInfoRow('Código cuenta', lectura!.codigoCuenta),
                    buildInfoRow('ID propietario', lectura!.idPropietario),
                    buildInfoRow('Medidor', lectura!.numeroMedidor),
                    buildInfoRow('Dirección', lectura!.direccionServicio),
                    buildInfoRow('Teléfono', lectura!.telefonoContacto),
                    buildInfoRow('Lectura anterior', lectura!.lecturaAnterior),
                    buildInfoRow('Lectura actual', lectura!.lecturaActual),
                    buildInfoRow('Consumo m3', lectura!.consumoM3),
                    buildInfoRow('Fecha lectura', lectura!.fechaLectura),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            mostrarFormularioGuardar = true;
                            lecturaActualCtrl.clear();
                            observacionCtrl.clear();
                            limpiarFotoTemporal();
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Registrar nueva lectura'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (mostrarDetalle && mostrarFormularioGuardar && lectura != null) ...[
              const SizedBox(height: 16),
              buildCard(
                titulo: 'Nueva lectura',
                icon: Icons.edit_note,
                child: Column(
                  children: [
                    buildInfoRow(
                      'Anterior automática',
                      lectura!.lecturaActual > 0
                          ? lectura!.lecturaActual
                          : lectura!.lecturaAnterior,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lecturaActualCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Lectura actual',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: observacionCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observación (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: cargando ? null : tomarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          fotoGuardadaPath == null
                              ? 'Tomar foto'
                              : 'Volver a tomar foto',
                        ),
                      ),
                    ),
                    if (fotoGuardadaPath != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(fotoGuardadaPath!),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fotoGuardadaPath!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Fecha: ${fotoFechaTomaExif ?? "-"}'),
                      Text('Latitud: ${fotoLatitudExif?.toString() ?? "-"}'),
                      Text('Longitud: ${fotoLongitudExif?.toString() ?? "-"}'),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                mostrarFormularioGuardar = false;
                                limpiarFormulario();
                              });
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: cargando ? null : guardarLecturaOffline,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (mostrarLista) ...[
              const SizedBox(height: 18),
              const Text(
                'Listado',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (cargando) const Center(child: CircularProgressIndicator()),
            if (mostrarLista)
              ...lecturas.map((item) {
                return Card(
                  elevation: 1.5,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    onTap: () async {
                      medidorCtrl.text = item.numeroMedidor;
                      await buscar();
                    },
                    contentPadding: const EdgeInsets.all(14),
                    leading: const CircleAvatar(
                      child: Icon(Icons.water_drop_outlined),
                    ),
                    title: Text(
                      tituloTarjeta(item),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Medidor: ${item.numeroMedidor}\n'
                            'Dirección: ${item.direccionServicio.isEmpty ? "-" : item.direccionServicio}\n'
                            'Lectura anterior: ${item.lecturaAnterior}\n'
                            'Lectura actual: ${item.lecturaActual}\n'
                            'Fecha: ${item.fechaLectura ?? "-"}',
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}