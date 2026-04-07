import '../models/lectura.dart';
import '../services/lectura_service.dart';
import '../services/local/lectura_local_service.dart';
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

class LecturaControlador {
  final LecturaService servicioRemoto;
  final LecturaLocalService servicioLocal;
  final ServicioUbicacion servicioUbicacion;

  LecturaControlador({
    required this.servicioRemoto,
    required this.servicioLocal,
    required this.servicioUbicacion,
  });

  Future<ResultadoOperacionLectura> cargarDatosIniciales() async {
    try {
      final listaLocal = await servicioLocal.listarTodo();

      if (listaLocal.isNotEmpty) {
        return ResultadoOperacionLectura(
          ok: true,
          mensaje: 'Datos cargados',
          lecturas: listaLocal,
        );
      }

      final listaRemota = await servicioRemoto.listarTodo();
      await servicioLocal.guardarCuentasIniciales(listaRemota);

      final listaGuardada = await servicioLocal.listarTodo();

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Cuentas descargadas y guardadas localmente',
        lecturas: listaGuardada,
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
        usuarioRegistro: 'app',
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
}