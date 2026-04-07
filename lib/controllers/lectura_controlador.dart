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
          mensaje: 'Datos cargados desde SQLite',
          lecturas: listaLocal,
        );
      }

      final listaRemota = await servicioRemoto.listarTodo();
      await servicioLocal.guardarLecturasIniciales(listaRemota);

      final listaGuardada = await servicioLocal.listarTodo();

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Datos descargados y guardados localmente',
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
        mensaje: 'Datos cargados desde SQLite',
        lecturas: lista,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al listar desde SQLite: $e',
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
          mensaje: 'No encontrado en SQLite',
        );
      }

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Lectura encontrada',
        lectura: dato,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al buscar en SQLite: $e',
      );
    }
  }

  int? convertirEntero(dynamic valor) {
    if (valor == null) return null;
    return int.tryParse(valor.toString().trim());
  }

  String? validarLecturaActual({
    required Lectura? lectura,
    required int lecturaActual,
  }) {
    if (lectura == null) {
      return 'Primero busca un medidor';
    }

    if (lecturaActual < 0) {
      return 'La lectura actual no puede ser negativa';
    }

    final int? lecturaAnterior = convertirEntero(lectura.lecturaAnterior);

    if (lecturaAnterior == null) {
      return 'La lectura anterior no es válida';
    }

    if (lecturaActual <= lecturaAnterior) {
      return 'La lectura actual debe ser mayor que la lectura anterior';
    }

    return null;
  }

  String fechaActualSql() {
    final ahora = DateTime.now();
    String dosDigitos(int n) => n.toString().padLeft(2, '0');

    return '${ahora.year}-${dosDigitos(ahora.month)}-${dosDigitos(ahora.day)} '
        '${dosDigitos(ahora.hour)}:${dosDigitos(ahora.minute)}:${dosDigitos(ahora.second)}';
  }

  Future<ResultadoOperacionLectura> actualizarLocalmente({
    required Lectura? lectura,
    required String numeroMedidor,
    required String textoLecturaActual,
    String? fotoPathLocal,
    String? fotoFechaToma,
    double? fotoLatitud,
    double? fotoLongitud,
    String? usuarioActualizo,
  }) async {
    try {
      final int? lecturaActual = int.tryParse(textoLecturaActual.trim());

      if (lecturaActual == null) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: 'Ingresa una lectura actual válida',
        );
      }

      final errorValidacion = validarLecturaActual(
        lectura: lectura,
        lecturaActual: lecturaActual,
      );

      if (errorValidacion != null) {
        return ResultadoOperacionLectura(
          ok: false,
          mensaje: errorValidacion,
        );
      }

      final posicion = await servicioUbicacion.obtenerUbicacionActual();

      await servicioLocal.actualizarLecturaLocal(
        numeroMedidor: numeroMedidor.trim(),
        lecturaActual: lecturaActual,
        fechaLectura: fechaActualSql(),
        latitudGps: posicion.latitude,
        longitudGps: posicion.longitude,
        fotoPathLocal: fotoPathLocal,
        fotoFechaToma: fotoFechaToma,
        fotoLatitud: fotoLatitud,
        fotoLongitud: fotoLongitud,
        usuarioActualizo: usuarioActualizo,
      );

      final datoActualizado =
      await servicioLocal.buscarPorMedidor(numeroMedidor.trim());

      return ResultadoOperacionLectura(
        ok: true,
        mensaje: 'Guardado localmente. Pendiente de sincronización.',
        lectura: datoActualizado,
      );
    } catch (e) {
      return ResultadoOperacionLectura(
        ok: false,
        mensaje: 'Error al actualizar localmente: $e',
      );
    }
  }
}