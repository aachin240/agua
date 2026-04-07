class Lectura {
  final int? idLocal;
  final int? idCuenta;
  final int? idLectura;
  final int? idPeriodo;

  final String numeroMedidor;
  final String codigoCuenta;
  final int? idPropietario;
  final String telefonoContacto;
  final String direccionServicio;

  final num lecturaAnterior;
  final num lecturaActual;
  final num consumoM3;
  final String? fechaLectura;
  final String? usuarioRegistro;
  final String? observacion;

  final double? latitudGps;
  final double? longitudGps;
  final String? fotoPathLocal;

  final int? pendienteSync;
  final String? estadoSync;
  final String? syncError;

  const Lectura({
    this.idLocal,
    this.idCuenta,
    this.idLectura,
    this.idPeriodo,
    required this.numeroMedidor,
    this.codigoCuenta = '',
    this.idPropietario,
    this.telefonoContacto = '',
    this.direccionServicio = '',
    this.lecturaAnterior = 0,
    this.lecturaActual = 0,
    this.consumoM3 = 0,
    this.fechaLectura,
    this.usuarioRegistro,
    this.observacion,
    this.latitudGps,
    this.longitudGps,
    this.fotoPathLocal,
    this.pendienteSync,
    this.estadoSync,
    this.syncError,
  });

  factory Lectura.fromJson(Map<String, dynamic> json) {
    final ultimaLectura =
    json['ultima_lectura'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['ultima_lectura'])
        : <String, dynamic>{};

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    num parseNum(dynamic v, {num defaultValue = 0}) {
      if (v == null) return defaultValue;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? defaultValue;
    }

    String? parseStringOrNull(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return Lectura(
      idLocal: parseInt(json['id_local']),
      idCuenta: parseInt(json['id_cuenta']),
      idLectura: parseInt(json['id_lectura'] ?? ultimaLectura['id_lectura']),
      idPeriodo: parseInt(json['id_periodo'] ?? ultimaLectura['id_periodo']),
      numeroMedidor: (json['numero_medidor'] ?? '').toString(),
      codigoCuenta: (json['codigo_cuenta'] ?? '').toString(),
      idPropietario: parseInt(json['id_propietario']),
      telefonoContacto: (json['telefono_contacto'] ?? '').toString(),
      direccionServicio: (json['direccion_servicio'] ?? '').toString(),
      lecturaAnterior: parseNum(
        json['lectura_anterior'] ?? ultimaLectura['lectura_anterior'],
      ),
      lecturaActual: parseNum(
        json['lectura_actual'] ?? ultimaLectura['lectura_actual'],
      ),
      consumoM3: parseNum(
        json['consumo_m3'] ?? ultimaLectura['consumo_m3'],
      ),
      fechaLectura: parseStringOrNull(
        json['fecha_lectura'] ?? ultimaLectura['fecha_lectura'],
      ),
      usuarioRegistro: parseStringOrNull(
        json['usuario_registro'] ?? ultimaLectura['usuario_registro'],
      ),
      observacion: parseStringOrNull(
        json['observacion'] ?? ultimaLectura['observacion'],
      ),
      latitudGps: parseDouble(json['latitud_gps']),
      longitudGps: parseDouble(json['longitud_gps']),
      fotoPathLocal: parseStringOrNull(json['foto_path_local']),
      pendienteSync: parseInt(json['pendiente_sync']),
      estadoSync: parseStringOrNull(json['estado_sync']),
      syncError: parseStringOrNull(json['sync_error']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_local': idLocal,
      'id_cuenta': idCuenta,
      'id_lectura': idLectura,
      'id_periodo': idPeriodo,
      'numero_medidor': numeroMedidor,
      'codigo_cuenta': codigoCuenta,
      'id_propietario': idPropietario,
      'telefono_contacto': telefonoContacto,
      'direccion_servicio': direccionServicio,
      'lectura_anterior': lecturaAnterior,
      'lectura_actual': lecturaActual,
      'consumo_m3': consumoM3,
      'fecha_lectura': fechaLectura,
      'usuario_registro': usuarioRegistro,
      'observacion': observacion,
      'latitud_gps': latitudGps,
      'longitud_gps': longitudGps,
      'foto_path_local': fotoPathLocal,
      'pendiente_sync': pendienteSync,
      'estado_sync': estadoSync,
      'sync_error': syncError,
    };
  }

  Lectura copyWith({
    int? idLocal,
    int? idCuenta,
    int? idLectura,
    int? idPeriodo,
    String? numeroMedidor,
    String? codigoCuenta,
    int? idPropietario,
    String? telefonoContacto,
    String? direccionServicio,
    num? lecturaAnterior,
    num? lecturaActual,
    num? consumoM3,
    String? fechaLectura,
    String? usuarioRegistro,
    String? observacion,
    double? latitudGps,
    double? longitudGps,
    String? fotoPathLocal,
    int? pendienteSync,
    String? estadoSync,
    String? syncError,
  }) {
    return Lectura(
      idLocal: idLocal ?? this.idLocal,
      idCuenta: idCuenta ?? this.idCuenta,
      idLectura: idLectura ?? this.idLectura,
      idPeriodo: idPeriodo ?? this.idPeriodo,
      numeroMedidor: numeroMedidor ?? this.numeroMedidor,
      codigoCuenta: codigoCuenta ?? this.codigoCuenta,
      idPropietario: idPropietario ?? this.idPropietario,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
      direccionServicio: direccionServicio ?? this.direccionServicio,
      lecturaAnterior: lecturaAnterior ?? this.lecturaAnterior,
      lecturaActual: lecturaActual ?? this.lecturaActual,
      consumoM3: consumoM3 ?? this.consumoM3,
      fechaLectura: fechaLectura ?? this.fechaLectura,
      usuarioRegistro: usuarioRegistro ?? this.usuarioRegistro,
      observacion: observacion ?? this.observacion,
      latitudGps: latitudGps ?? this.latitudGps,
      longitudGps: longitudGps ?? this.longitudGps,
      fotoPathLocal: fotoPathLocal ?? this.fotoPathLocal,
      pendienteSync: pendienteSync ?? this.pendienteSync,
      estadoSync: estadoSync ?? this.estadoSync,
      syncError: syncError ?? this.syncError,
    );
  }
}