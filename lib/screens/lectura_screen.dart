import 'dart:io';
import 'package:exif_reader/exif_reader.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';
import '../models/lectura.dart';
import '../services/lectura_service.dart';

class LecturaScreen extends StatefulWidget {
  const LecturaScreen({super.key});

  @override
  State<LecturaScreen> createState() => _LecturaScreenState();
}

class _LecturaScreenState extends State<LecturaScreen> {
  final LecturaService service = LecturaService();

  final ImagePicker _picker = ImagePicker();
  XFile? fotoTomada;
  String? fotoGuardadaPath;
  String? fotoFechaTomaExif;
  double? fotoLatitudExif;
  double? fotoLongitudExif;

  final TextEditingController medidorCtrl = TextEditingController();
  final TextEditingController lecturaActualCtrl = TextEditingController();

  Lectura? lectura;
  List<Lectura> lecturas = [];

  String mensaje = '';
  bool cargando = false;
  bool mostrarDetalle = false;
  bool mostrarFormularioActualizar = false;
  bool mostrarLista = true;

  @override
  void initState() {
    super.initState();
    listarTodo();
  }

  @override
  void dispose() {
    medidorCtrl.dispose();
    lecturaActualCtrl.dispose();
    super.dispose();
  }

  Future<void> probarExifReader(String rutaFoto) async {
    try {
      final bytes = await File(rutaFoto).readAsBytes();
      final exif = await readExifFromBytes(bytes);

      print('========== EXIF_READER ==========');
      print('RUTA FOTO: $rutaFoto');

      if (exif.warnings.isNotEmpty) {
        print('Warnings:');
        for (final warning in exif.warnings) {
          print('  $warning');
        }
      }

      if (exif.tags.isEmpty) {
        print('No EXIF information found');
        return;
      }

      print('GPSLatitude: ${exif.tags['GPSLatitude']}');
      print('GPSLatitudeRef: ${exif.tags['GPSLatitudeRef']}');
      print('GPSLongitude: ${exif.tags['GPSLongitude']}');
      print('GPSLongitudeRef: ${exif.tags['GPSLongitudeRef']}');
      print('DateTimeOriginal: ${exif.tags['DateTimeOriginal']}');
      print('Todos los tags: ${exif.tags}');
      print('===============================');
    } catch (e) {
      print('ERROR EXIF_READER: $e');
    }
  }

  void limpiarFotoTemporal() {
    fotoTomada = null;
    fotoGuardadaPath = null;
    fotoFechaTomaExif = null;
    fotoLatitudExif = null;
    fotoLongitudExif = null;
  }
  Future<Position> _obtenerUbicacionActual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El GPS del dispositivo está desactivado');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _guardarFotoEnApp(XFile foto) async {
    final dir = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${dir.path}/fotos_medidor');

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    final nombre =
        'medidor_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destino = '${carpeta.path}/$nombre';

    final archivoOriginal = File(foto.path);
    final archivoNuevo = await archivoOriginal.copy(destino);

    return archivoNuevo.path;
  }

  Future<void> tomarFoto() async {
    print('Entro a tomar foto');
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
      );


      if (foto == null) return;

      print('RUTA ORIGINAL PICKER: ${foto.path}');

      final exifOriginal = await Exif.fromPath(foto.path);
      final coordsOriginal = await exifOriginal.getLatLong();
      final attrsOriginal = await exifOriginal.getAttributes();

      print('ORIGINAL coords: $coordsOriginal');
      print('ORIGINAL GPSLatitude: ${attrsOriginal?["GPSLatitude"]}');
      print('ORIGINAL GPSLatitudeRef: ${attrsOriginal?["GPSLatitudeRef"]}');
      print('ORIGINAL GPSLongitude: ${attrsOriginal?["GPSLongitude"]}');
      print('ORIGINAL GPSLongitudeRef: ${attrsOriginal?["GPSLongitudeRef"]}');

      await exifOriginal.close();

      final rutaFinal = await _guardarFotoEnApp(foto);
      //await probarExifReader(rutaFinal);

      String? fechaExif;
      double? latExif;
      double? longExif;

      try {
        final exif = await Exif.fromPath(rutaFinal);

        final originalDate = await exif.getOriginalDate();
        final coordinates = await exif.getLatLong();
        final attrs = await exif.getAttributes();

        fechaExif = originalDate?.toString();
        print('RUTA FOTO: $rutaFinal');
        print('EXIF fecha: $originalDate');
        print('EXIF coordinates: $coordinates');
        print('EXIF GPSLatitude: ${attrs?["GPSLatitude"]}');
        print('EXIF GPSLatitudeRef: ${attrs?["GPSLatitudeRef"]}');
        print('EXIF GPSLongitude: ${attrs?["GPSLongitude"]}');
        print('EXIF GPSLongitudeRef: ${attrs?["GPSLongitudeRef"]}');

        if (coordinates != null) {
          print(coordinates);
          latExif = coordinates.latitude;
          longExif = coordinates.longitude;
        }

        await exif.close();
      } catch (_) {
        // Si no hay EXIF o falla la lectura, seguimos sin romper el flujo
      }

      setState(() {
        fotoTomada = foto;
        fotoGuardadaPath = rutaFinal;
        fotoFechaTomaExif = fechaExif;
        fotoLatitudExif = latExif;
        fotoLongitudExif = longExif;
        mensaje = 'Foto tomada correctamente';
      });
    } catch (e) {
      setState(() {
        mensaje = 'Error al tomar la foto: $e';
      });
    }
  }

  Future<void> listarTodo() async {
    setState(() {
      cargando = true;
      mostrarLista = true;
      mostrarDetalle = false;
      mostrarFormularioActualizar = false;
      lectura = null;
      mensaje = '';

      limpiarFotoTemporal();
    });

    try {
      final lista = await service.listarTodo();

      setState(() {
        lecturas = lista;
      });
    } catch (e) {
      setState(() {
        mensaje = 'Error al listar: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> buscar() async {
    final numeroMedidor = medidorCtrl.text.trim();

    if (numeroMedidor.isEmpty) {
      setState(() {
        mensaje = 'Ingresa un número de medidor';
      });
      return;
    }

    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final dato = await service.buscarPorMedidor(numeroMedidor);

      setState(() {
        lectura = dato;
        mostrarLista = false;
        mostrarDetalle = true;
        mostrarFormularioActualizar = false;
        lecturaActualCtrl.text =
        dato.lecturaActual == null ? '' : dato.lecturaActual.toString();

        limpiarFotoTemporal();
      });
    } catch (e) {
      setState(() {
        lectura = null;
        mostrarDetalle = false;
        mostrarFormularioActualizar = false;
        mensaje = 'No encontrado o error';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  String _fechaActualSql() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  Future<void> actualizar() async {
    if (lectura == null) {
      setState(() {
        mensaje = 'Primero busca un medidor';
      });
      return;
    }

    final int? lecturaActual = int.tryParse(lecturaActualCtrl.text.trim());

    if (lecturaActual == null) {
      setState(() {
        mensaje = 'Ingresa una lectura actual válida';
      });
      return;
    }

    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final posicion = await _obtenerUbicacionActual();

      final msg = await service.actualizarLectura(
        numeroMedidor: medidorCtrl.text.trim(),
        lecturaActual: lecturaActual,
        fechaLectura: _fechaActualSql(),
        latitudGps: posicion.latitude,
        longitudGps: posicion.longitude,
        fotoPathLocal: fotoGuardadaPath,
        fotoFechaToma: fotoFechaTomaExif,
        fotoLatitud: fotoLatitudExif,
        fotoLongitud: fotoLongitudExif,
      );

      final datoActualizado =
      await service.buscarPorMedidor(medidorCtrl.text.trim());

      setState(() {
        lectura = datoActualizado;
        mostrarLista = false;
        mostrarDetalle = true;
        mostrarFormularioActualizar = false;
        mensaje = msg;
      });
    } catch (e) {
      setState(() {
        mensaje = 'Error al actualizar: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Widget buildInfoRow(String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
              valor == null ? '-' : valor.toString(),
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

            if (mostrarDetalle && lectura != null) ...[
              const SizedBox(height: 16),
              buildCard(
                titulo: 'Datos del medidor',
                icon: Icons.description_outlined,
                child: Column(
                  children: [
                    buildInfoRow('Nombre', lectura!.nombre),
                    buildInfoRow('Dirección', lectura!.direccion),
                    buildInfoRow('Teléfono', lectura!.telefono),
                    buildInfoRow('Medidor', lectura!.numeroMedidor),
                    buildInfoRow('Lectura anterior', lectura!.lecturaAnterior),
                    buildInfoRow('Lectura actual', lectura!.lecturaActual),
                    buildInfoRow('Fecha lectura', lectura!.fechaLectura),
                    buildInfoRow('Latitud GPS', lectura!.latitudGps),
                    buildInfoRow('Longitud GPS', lectura!.longitudGps),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            mostrarFormularioActualizar = true;
                          });
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Actualizar lectura'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (mostrarDetalle &&
                mostrarFormularioActualizar &&
                lectura != null) ...[
              const SizedBox(height: 16),
              buildCard(
                titulo: 'Actualizar lectura',
                icon: Icons.edit_note,
                child: Column(
                  children: [
                    TextField(
                      controller: lecturaActualCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Lectura actual',
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
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text('EXIF fecha: ${fotoFechaTomaExif ?? "-"}'),
                      Text('EXIF latitud: ${fotoLatitudExif?.toString() ?? "-"}'),
                      Text('EXIF longitud: ${fotoLongitudExif?.toString() ?? "-"}'),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                mostrarFormularioActualizar = false;
                                fotoTomada = null;
                                fotoGuardadaPath = null;
                                fotoFechaTomaExif = null;
                                fotoLatitudExif = null;
                                fotoLongitudExif = null;
                              });
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: cargando ? null : actualizar,
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
                'Listado completo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (cargando)
              const Center(child: CircularProgressIndicator()),

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
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(
                      item.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Medidor: ${item.numeroMedidor}\n'
                            'Lectura anterior: ${item.lecturaAnterior}\n'
                            'Lectura actual: ${item.lecturaActual}\n'
                            'Fecha: ${item.fechaLectura}',
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