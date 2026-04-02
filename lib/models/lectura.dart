class Lectura {
  final dynamic id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String numeroMedidor;
  final dynamic lecturaAnterior;
  final dynamic lecturaActual;
  final dynamic fechaLectura;
  final dynamic latitudGps;
  final dynamic longitudGps;
  final dynamic fotoPathLocal;
  final dynamic fotoFechaToma;
  final dynamic fotoLatitud;
  final dynamic fotoLongitud;
  final dynamic usuarioActualizo;

  Lectura({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.numeroMedidor,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.fechaLectura,
    required this.longitudGps,
    required this.latitudGps,
    required this.fotoPathLocal,
    required this.fotoFechaToma,
    required this.fotoLatitud,
    required this.fotoLongitud,
    required this.usuarioActualizo,

  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    return Lectura(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      direccion: json['direccion'] ?? '',
      telefono: json['telefono'] ?? '',
      numeroMedidor: json['numero_medidor']?.toString() ?? '',
      lecturaAnterior: json['lectura_anterior'],
      lecturaActual: json['lectura_actual'],
      fechaLectura: json['fecha_lectura'],
      latitudGps: json['latitud_gps'],
      longitudGps: json['longitud_gps'],
      fotoPathLocal: json['foto_path_local'],
      fotoFechaToma: json['foto_fecha_toma'],
      fotoLatitud: json['foto_latitud'],
      fotoLongitud: json['foto_longitud'],
      usuarioActualizo: json['usuario_actualizo'],
    );
  }
}