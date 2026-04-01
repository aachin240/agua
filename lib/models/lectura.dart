class Lectura {
  final dynamic id;
  final String nombre;
  final String direccion;
  final String telefono;
  final String numeroMedidor;
  final dynamic lecturaAnterior;
  final dynamic lecturaActual;
  final dynamic fechaLectura;
  final dynamic latitud;
  final dynamic longitud;

  Lectura({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.numeroMedidor,
    required this.lecturaAnterior,
    required this.lecturaActual,
    required this.fechaLectura,
    required this.latitud,
    required this.longitud,
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
      latitud: json['latitud'],
      longitud: json['longitud'],
    );
  }
}