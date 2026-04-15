import 'package:flutter/material.dart';

import '../controllers/controlador_lectura.dart';
import '../models/lectura.dart';
import '../models/usuario_sesion.dart';
import '../services/device/servicio_foto.dart';
import '../services/device/servicio_ubicacion.dart';
import '../services/local/servicio_lectura_local.dart';
import '../services/local/servicio_sesion.dart';
import '../services/servicio_lectura.dart';
import '../widgets/formulario_nueva_lectura.dart';
import '../widgets/item_lectura.dart';
import '../widgets/tarjeta_busqueda_medidor.dart';
import '../widgets/tarjeta_detalle_cuenta.dart';
import '../widgets/tarjeta_sincronizacion.dart';
import 'pantalla_login.dart';

class PantallaLectura extends StatefulWidget {
  final UsuarioSesion usuarioSesion;
  final int? rutaFiltro;

  const PantallaLectura({
    super.key,
    required this.usuarioSesion,
    this.rutaFiltro,
  });

  @override
  State<PantallaLectura> createState() => _PantallaLecturaState();
}

class _PantallaLecturaState extends State<PantallaLectura> {
  final ServicioLectura servicioRemoto = ServicioLectura();
  final ServicioLecturaLocal servicioLocal = ServicioLecturaLocal();
  final ServicioUbicacion servicioUbicacion = ServicioUbicacion();
  final ServicioFoto servicioFoto = ServicioFoto();

  late final ControladorLectura controlador;

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
  String? errorLecturaActual;
  bool cargando = false;
  bool mostrarDetalle = false;
  bool mostrarFormularioGuardar = false;
  bool mostrarLista = true;

  String? fotoGuardadaPath;
  String? fotoFechaTomaExif;
  double? fotoLatitudExif;
  double? fotoLongitudExif;

  String get usernameOwner => widget.usuarioSesion.username;

  @override
  void initState() {
    super.initState();

    controlador = ControladorLectura(
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
    final resumen = await controlador.obtenerResumenSincronizacion(
      usernameOwner: usernameOwner,
    );

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
      usernameOwner: usernameOwner,
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

      String texto =
          '${resultado.mensaje}. '
          'Exitosas: ${resultado.exitosas}, '
          'Errores: ${resultado.errores}, '
          'Conflictos: ${resultado.conflictos}';

      if (resultado.mensajesConflictos.isNotEmpty) {
        texto += '\n\n${resultado.mensajesConflictos.join('\n')}';
      }

      mensaje = texto;
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
    limpiarErrorLecturaActual();
  }

  void limpiarErrorLecturaActual() {
    errorLecturaActual = null;
  }

  bool esErrorDeCampoLectura(String texto) {
    final t = texto.toLowerCase();

    return t.contains('lectura actual debe ser mayor') ||
        t.contains('lectura actual no puede ser negativa') ||
        t.contains('ingresa una lectura actual válida');
  }

  bool esAlertaInmediata(String texto) {
    final t = texto.toLowerCase();

    return t.contains('debes tomar una foto') ||
        t.contains('servicio de ubicación está desactivado') ||
        t.contains('permiso de ubicación denegado') ||
        t.contains('permiso de ubicación denegado permanentemente') ||
        t.contains('error al tomar la foto');
  }

  Future<void> mostrarDialogoAlerta({
    required String titulo,
    required String mensaje,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> cargarDatosIniciales() async {
    setState(() {
      cargando = true;
      mensaje = '';
      mostrarLista = true;
      mostrarDetalle = false;
      mostrarFormularioGuardar = false;
      lectura = null;
      errorLecturaActual = null;
    });

    final resultado = await controlador.listarDesdeBaseLocal(
      usernameOwner: usernameOwner,
      ruta: widget.rutaFiltro,
    );

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
      errorLecturaActual = null;
    });

    final resultado = await controlador.listarDesdeBaseLocal(
      usernameOwner: usernameOwner,
      ruta: widget.rutaFiltro,
    );

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
      errorLecturaActual = null;
    });

    final resultado = await controlador.buscarPorMedidor(
      usernameOwner: usernameOwner,
      numeroMedidor: medidorCtrl.text,
    );

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

      await mostrarDialogoAlerta(
        titulo: 'No se pudo tomar la foto',
        mensaje: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> guardarLecturaOffline() async {
    setState(() {
      cargando = true;
      mensaje = '';
      errorLecturaActual = null;
    });

    final resultado = await controlador.guardarLecturaOffline(
      usernameOwner: usernameOwner,
      cuenta: lectura,
      numeroMedidor: medidorCtrl.text,
      textoLecturaActual: lecturaActualCtrl.text,
      fotoPathLocal: fotoGuardadaPath,
      observacion: observacionCtrl.text.trim().isEmpty
          ? null
          : observacionCtrl.text.trim(),
      usuarioRegistro: widget.usuarioSesion.username,
    );

    if (resultado.ok) {
      await cargarResumenSync();
    }

    if (!mounted) return;

    if (resultado.ok) {
      setState(() {
        cargando = false;
        mensaje = resultado.mensaje;
        lectura = resultado.lectura;
        mostrarLista = false;
        mostrarDetalle = true;
        mostrarFormularioGuardar = false;
        limpiarFormulario();
      });
      return;
    }

    final texto = resultado.mensaje;

    if (esErrorDeCampoLectura(texto)) {
      setState(() {
        cargando = false;
        errorLecturaActual = texto;
      });
      return;
    }

    if (esAlertaInmediata(texto)) {
      setState(() {
        cargando = false;
      });

      await mostrarDialogoAlerta(
        titulo: 'Atención',
        mensaje: texto,
      );
      return;
    }

    setState(() {
      cargando = false;
      mensaje = texto;
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
        title: Text(
          widget.rutaFiltro != null
              ? 'Ruta ${widget.rutaFiltro} - ${widget.usuarioSesion.username}'
              : 'Lecturas - ${widget.usuarioSesion.username}',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              final servicioSesion = ServicioSesion();
              await servicioSesion.cerrarSesion();

              if (!mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PantallaLogin()),
                    (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
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
            TarjetaBusquedaMedidor(
              medidorCtrl: medidorCtrl,
              cargando: cargando,
              onBuscar: buscar,
              onListarTodo: listarTodo,
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
            TarjetaSincronizacion(
              pendientesSync: pendientesSync,
              erroresSync: erroresSync,
              cargando: cargando,
              sincronizando: sincronizando,
              progresoSync: progresoSync,
              lecturasConError: lecturasConError,
              onSincronizar: sincronizarAhora,
            ),
            if (mostrarDetalle && lectura != null) ...[
              const SizedBox(height: 16),
              TarjetaDetalleCuenta(
                lectura: lectura!,
                onRegistrarNuevaLectura: () {
                  setState(() {
                    mostrarFormularioGuardar = true;
                    lecturaActualCtrl.clear();
                    observacionCtrl.clear();
                    limpiarFotoTemporal();
                  });
                },
              ),
            ],
            if (mostrarDetalle && mostrarFormularioGuardar && lectura != null) ...[
              const SizedBox(height: 16),
              FormularioNuevaLectura(
                lectura: lectura!,
                lecturaActualCtrl: lecturaActualCtrl,
                observacionCtrl: observacionCtrl,
                cargando: cargando,
                fotoGuardadaPath: fotoGuardadaPath,
                fotoFechaTomaExif: fotoFechaTomaExif,
                fotoLatitudExif: fotoLatitudExif,
                fotoLongitudExif: fotoLongitudExif,
                errorLecturaActual: errorLecturaActual,
                onLecturaActualChanged: (_) {
                  if (errorLecturaActual != null) {
                    setState(() {
                      errorLecturaActual = null;
                    });
                  }
                },
                onTomarFoto: tomarFoto,
                onCancelar: () {
                  setState(() {
                    mostrarFormularioGuardar = false;
                    limpiarFormulario();
                  });
                },
                onGuardar: guardarLecturaOffline,
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
                return ItemLectura(
                  item: item,
                  titulo: tituloTarjeta(item),
                  onTap: () async {
                    medidorCtrl.text = item.numeroMedidor;
                    await buscar();
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}