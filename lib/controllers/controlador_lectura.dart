import '../models/lectura.dart';
import '../services/servicio_lectura.dart';
import '../services/local/servicio_lectura_local.dart';
import '../services/device/servicio_ubicacion.dart';

class ResultadoOperacionLectura {
  final bool ok;
  final String mensaje;
  final Lectura? lectura;
  final List<Lectura>? lecturas;

  ResultadoOperacionLectura({
    required this.ok,
    required this.mensaje,
    this.lectura,
    this.lecturas,
  });
}

class EstadoSincronizacionResumen {
  final int pendientes;
  final int errores;
  final List<Lectura> conError;

  EstadoSincronizacionResumen({
    required this.pendientes,
    required this.errores,
    required this.conError,
  });
}

class ResultadoSincronizacion {
  final bool ok;
  final String mensaje;
  final int total;
  final int exitosas;
  final int errores;
  final int conflictos;
  final List<String> mensajesConflictos;

  ResultadoSincronizacion({
    required this.ok,
    required this.mensaje,
    required this.total,
    required this.exitosas,
    required this.errores,
    required this.conflictos,
    required this.mensajesConflictos,
  });
}

class ControladorLectura {
  final ServicioLectura servicioRemoto;
  final ServicioLecturaLocal servicioLocal;
  final ServicioUbicacion servicioUbicacion;

  ControladorLectura({
    required this.servicioRemoto,
    required this.servicioLocal,
    required this.servicioUbicacion,
  });

  Future<ResultadoOperacionLectura> cargarRutas(List<int> rutas) async {
    try {
      if (rutas.isEmpty) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'Debes seleccionar al menos una ruta',
        );
      }

      final listaRemota = await servicioRemoto.listarTodo(rutas: rutas);

      if (listaRemota.isEmpty) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'No hay cuentas para las rutas seleccionadas',
        );
      }

      await servicioLocal.limpiarCuentasLocales();
      await servicioLocal.guardarCuentasIniciales(listaRemota);

      final listaGuardada = await servicioLocal.listarTodo();

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Rutas cargadas correctamente',
        lecturas: listaGuardada,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al cargar las rutas: $e',
      );
    }
  }

  Future<ResultadoOperacionLectura> cargarDatosIniciales() async {
    try {
      final listaLocal = await servicioLocal.listarTodo();

      if (listaLocal.isEmpty) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'No hay rutas cargadas. Primero selecciona una o varias rutas.',
          lecturas: [],
        );
      }

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Datos cargados',
        lecturas: listaLocal,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al cargar datos iniciales: $e',
      );
    }
  }

  Future<ResultadoOperacionLectura> listarDesdeBaseLocal() async {
    try {
      final lista = await servicioLocal.listarTodo();

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Datos cargados',
        lecturas: lista,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al listar: $e',
      );
    }
  }

  Future<ResultadoOperacionLectura> buscarPorMedidor(
      String numeroMedidor,
      ) async {
    try {
      if (numeroMedidor.trim().isEmpty) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'Ingresa un número de medidor',
        );
      }

      final dato = await servicioLocal.buscarPorMedidor(numeroMedidor.trim());

      if (dato == null) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'No encontrado',
        );
      }

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Medidor encontrado',
        lectura: dato,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al buscar: $e',
      );
    }
  }

  num? convertirNumero(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor;

    final texto = valor.toString().trim();
    return num.tryParse(texto);
  }

  String fechaActualSoloFecha() {
    final ahora = DateTime.now();
    String dosDigitos(int n) => n.toString().padLeft(2, '0');

    return '${ahora.year}-${dosDigitos(ahora.month)}-${dosDigitos(ahora.day)}';
  }

  String? validarNuevaLectura({
    required Lectura? cuenta,
    required num lecturaActual,
    required String? fotoPathLocal,
  }) {
    if (cuenta == null) {
      return 'Primero busca un medidor';
    }

    if (lecturaActual < 0) {
      return 'La lectura actual no puede ser negativa';
    }

    final num lecturaAnterior =
        convertirNumero(cuenta.lecturaActual) ??
            convertirNumero(cuenta.lecturaAnterior) ??
            0;

    if (lecturaActual <= lecturaAnterior) {
      return 'La lectura actual debe ser mayor que la lectura anterior';
    }

    if (fotoPathLocal == null || fotoPathLocal.trim().isEmpty) {
      return 'Debes tomar una foto';
    }

    return null;
  }

  Future<ResultadoOperacionLectura> guardarLecturaOffline({
    required Lectura? cuenta,
    required String numeroMedidor,
    required String textoLecturaActual,
    required String? fotoPathLocal,
    required String usuarioRegistro,
    String? observacion,
  }) async {
    try {
      final num? lecturaActual = num.tryParse(textoLecturaActual.trim());

      if (lecturaActual == null) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'Ingresa una lectura actual válida',
        );
      }

      final errorValidacion = validarNuevaLectura(
        cuenta: cuenta,
        lecturaActual: lecturaActual,
        fotoPathLocal: fotoPathLocal,
      );

      if (errorValidacion != null) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: errorValidacion,
        );
      }

      final posicion = await servicioUbicacion.obtenerUbicacionActual();

      final lecturaAnterior =
          convertirNumero(cuenta!.lecturaActual) ??
              convertirNumero(cuenta.lecturaAnterior) ??
              0;

      final consumoM3 = lecturaActual - lecturaAnterior;
      final fechaLectura = fechaActualSoloFecha();

      await servicioLocal.guardarLecturaPendiente(
        idCuenta: cuenta.idCuenta!,
        numeroMedidor: numeroMedidor.trim(),
        lecturaAnterior: lecturaAnterior,
        lecturaActual: lecturaActual,
        consumoM3: consumoM3,
        fechaLectura: fechaLectura,
        fotoPathLocal: fotoPathLocal!,
        usuarioRegistro: usuarioRegistro,
        observacion: observacion,
        latitudGps: posicion.latitude,
        longitudGps: posicion.longitude,
      );

      await servicioLocal.actualizarCuentaLocalDespuesDeLectura(
        numeroMedidor: numeroMedidor.trim(),
        lecturaAnterior: lecturaAnterior,
        lecturaActual: lecturaActual,
        consumoM3: consumoM3,
        fechaLectura: fechaLectura,
      );

      final datoActualizado =
      await servicioLocal.buscarPorMedidor(numeroMedidor.trim());

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Lectura guardada. Pendiente de sincronización.',
        lectura: datoActualizado,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al guardar lectura: $e',
      );
    }
  }

  String limpiarMensajeError(dynamic error) {
    final texto = error.toString().trim();

    String limpio = texto
        .replaceFirst('Exception: ', '')
        .replaceFirst('SocketException: ', '')
        .replaceFirst('FormatException: ', '');

    final lower = limpio.toLowerCase();

    if (lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection timed out')) {
      return 'No hay conexión a internet o no se pudo acceder al servidor';
    }

    if (lower.contains('error http')) {
      return 'El servidor respondió con un error';
    }

    if (lower.contains('servidor devolvió html')) {
      return 'El servicio no respondió correctamente';
    }

    if (lower.contains('no existe la foto local')) {
      return 'No se encontró la foto guardada en el dispositivo';
    }

    if (lower.contains('ya existe una lectura registrada para este período')) {
      return 'Ya existe una lectura registrada para este período';
    }

    if (lower.contains('no se encontró la cuenta para este medidor')) {
      return 'No se encontró la cuenta para este medidor';
    }

    if (lower.contains('no existe un período vigente')) {
      return 'No existe un período vigente para la fecha de lectura';
    }

    if (lower.contains('la lectura actual debe ser mayor')) {
      return 'La lectura actual debe ser mayor que la anterior';
    }

    return limpio;
  }

  bool esConflictoNoReintentable(String mensaje) {
    final m = mensaje.toLowerCase();
    return m.contains('ya existe una lectura registrada para este período');
  }

  Future<void> recargarCuentasDesdeServidor() async {
    // Se deja sin recarga remota por ahora para no perder el filtro
    // de las rutas seleccionadas en esta sesión.
  }

  Future<EstadoSincronizacionResumen> obtenerResumenSincronizacion() async {
    final pendientes = await servicioLocal.contarPendientes();
    final errores = await servicioLocal.contarErrores();
    final conError = await servicioLocal.obtenerConError();

    return EstadoSincronizacionResumen(
      pendientes: pendientes,
      errores: errores,
      conError: conError,
    );
  }

  Future<ResultadoSincronizacion> sincronizarPendientes({
    void Function(int actual, int total)? onProgress,
  }) async {
    try {
      final pendientes = await servicioLocal.obtenerPendientesSync();

      if (pendientes.isEmpty) {
        return ResultadoSincronizacion(
          ok: true,
          mensaje: 'No hay lecturas pendientes por sincronizar',
          total: 0,
          exitosas: 0,
          errores: 0,
          conflictos: 0,
          mensajesConflictos: [],
        );
      }

      int exitosas = 0;
      int errores = 0;
      int conflictos = 0;
      int actual = 0;
      bool requiereRecarga = false;
      final List<String> mensajesConflicto = [];

      for (final item in pendientes) {
        actual += 1;
        onProgress?.call(actual, pendientes.length);

        if (item.idLocal != null) {
          await servicioLocal.marcarComoSincronizando(item.idLocal!);
        }

        try {
          await servicioRemoto.registrarLectura(
            numeroMedidor: item.numeroMedidor,
            lecturaActual: item.lecturaActual,
            fechaLectura: item.fechaLectura ?? fechaActualSoloFecha(),
            latitudGps: item.latitudGps,
            longitudGps: item.longitudGps,
            observacion: item.observacion,
            fotoPathLocal: item.fotoPathLocal,
            usuarioRegistro: item.usuarioRegistro ?? 'app',
          );

          if (item.idLocal != null) {
            await servicioLocal.marcarComoSincronizado(item.idLocal!);
          }

          exitosas += 1;
          requiereRecarga = true;
        } catch (e) {
          final mensaje = limpiarMensajeError(e);

          if (item.idLocal != null) {
            if (esConflictoNoReintentable(mensaje)) {
              mensajesConflicto.add(
                'La lectura del medidor ${item.numeroMedidor} no se subió porque ya existe una lectura registrada para este período.',
              );

              await servicioLocal.eliminarPendiente(item.idLocal!);
              conflictos += 1;
              requiereRecarga = true;
            } else {
              await servicioLocal.marcarComoError(item.idLocal!, mensaje);
              errores += 1;
            }
          } else {
            errores += 1;
          }
        }
      }

      if (requiereRecarga) {
        try {
          await recargarCuentasDesdeServidor();
        } catch (_) {}
      }

      final ok = errores == 0;

      return ResultadoSincronizacion(
        ok: ok,
        mensaje: ok
            ? 'Sincronización completada correctamente'
            : 'Sincronización finalizada con novedades',
        total: pendientes.length,
        exitosas: exitosas,
        errores: errores,
        conflictos: conflictos,
        mensajesConflictos: mensajesConflicto,
      );
    } catch (e) {
      return ResultadoSincronizacion(
        ok: false,
        mensaje: 'Error al sincronizar pendientes: ${limpiarMensajeError(e)}',
        total: 0,
        exitosas: 0,
        errores: 0,
        conflictos: 0,
        mensajesConflictos: [],
      );
    }
  }

}