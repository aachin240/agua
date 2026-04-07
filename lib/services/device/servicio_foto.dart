import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';

class ResultadoFoto {
  final String rutaFotoGuardada;
  final String? fechaToma;
  final double? latitud;
  final double? longitud;

  ResultadoFoto({
    required this.rutaFotoGuardada,
    this.fechaToma,
    this.latitud,
    this.longitud,
  });
}

class ServicioFoto {
  final ImagePicker _picker = ImagePicker();

  Future<void> escribirGpsEnExif({
    required String rutaImagen,
    required double latitud,
    required double longitud,
  }) async {
    final exif = await Exif.fromPath(rutaImagen);

    await exif.writeAttributes({
      'GPSLatitude': latitud.abs().toString(),
      'GPSLatitudeRef': latitud >= 0 ? 'N' : 'S',
      'GPSLongitude': longitud.abs().toString(),
      'GPSLongitudeRef': longitud >= 0 ? 'E' : 'W',
    });

    await exif.close();
  }

  Future<String> guardarFotoEnApp(String rutaOrigen) async {
    final directorio = await getApplicationDocumentsDirectory();
    final carpetaFotos = Directory('${directorio.path}/fotos_lecturas');

    if (!await carpetaFotos.exists()) {
      await carpetaFotos.create(recursive: true);
    }

    final nombreArchivo =
        'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final rutaDestino = '${carpetaFotos.path}/$nombreArchivo';

    final archivoOrigen = File(rutaOrigen);
    final archivoDestino = await archivoOrigen.copy(rutaDestino);

    return archivoDestino.path;
  }

  Future<ResultadoFoto?> tomarYPrepararFoto({
    required double latitudActual,
    required double longitudActual,
  }) async {
    final foto = await _picker.pickImage(source: ImageSource.camera);

    if (foto == null) {
      return null;
    }

    final exifOriginal = await Exif.fromPath(foto.path);
    final fechaOriginal = await exifOriginal.getOriginalDate();
    final coordenadasOriginales = await exifOriginal.getLatLong();
    await exifOriginal.close();

    final double? latitudExif = coordenadasOriginales?.latitude;
    final double? longitudExif = coordenadasOriginales?.longitude;

    double latitudFinal = latitudExif ?? latitudActual;
    double longitudFinal = longitudExif ?? longitudActual;

    if (longitudFinal == 0) {
      latitudFinal = latitudActual;
      longitudFinal = longitudActual;
    }

    await escribirGpsEnExif(
      rutaImagen: foto.path,
      latitud: latitudFinal,
      longitud: longitudFinal,
    );

    final rutaGuardada = await guardarFotoEnApp(foto.path);

    return ResultadoFoto(
      rutaFotoGuardada: rutaGuardada,
      fechaToma: fechaOriginal?.toIso8601String(),
      latitud: latitudFinal,
      longitud: longitudFinal,
    );
  }
}