import 'package:flutter/material.dart';
import '../models/lectura.dart';
import '../services/lectura_service.dart';

class LecturaScreen extends StatefulWidget {
  const LecturaScreen({super.key});

  @override
  State<LecturaScreen> createState() => _LecturaScreenState();
}

class _LecturaScreenState extends State<LecturaScreen> {
  final LecturaService service = LecturaService();

  final TextEditingController medidorCtrl = TextEditingController();
  final TextEditingController lecturaActualCtrl = TextEditingController();
  final TextEditingController fechaCtrl = TextEditingController();
  final TextEditingController latitudCtrl = TextEditingController();
  final TextEditingController longitudCtrl = TextEditingController();

  Lectura? lectura;
  List<Lectura> lecturas = [];
  String mensaje = '';
  bool cargando = false;
  bool mostrarDetalle = false;
  bool mostrarFormularioActualizar = false;

  @override
  void initState() {
    super.initState();
    listarTodo();
  }

  @override
  void dispose() {
    medidorCtrl.dispose();
    lecturaActualCtrl.dispose();
    fechaCtrl.dispose();
    latitudCtrl.dispose();
    longitudCtrl.dispose();
    super.dispose();
  }

  // =========================
  // MÉTODOS
  // =========================
  Future<void> listarTodo() async {
    setState(() {
      cargando = true;
    });

    try {
      final lista = await service.listarTodo();

      setState(() {
        lecturas = lista;
        mensaje = '';
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
        lectura = null;
        mostrarDetalle = false;
        mostrarFormularioActualizar = false;
      });
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final dato = await service.buscarPorMedidor(numeroMedidor);

      setState(() {
        lectura = dato;
        mensaje = '';
        mostrarDetalle = true;
        mostrarFormularioActualizar = false;

        // Carga valores actuales en el formulario
        lecturaActualCtrl.text =
        dato.lecturaActual == null ? '' : dato.lecturaActual.toString();

        fechaCtrl.text =
        dato.fechaLectura == null ? '' : dato.fechaLectura.toString();

        latitudCtrl.text =
        dato.latitud == null ? '' : dato.latitud.toString();

        longitudCtrl.text =
        dato.longitud == null ? '' : dato.longitud.toString();
      });
    } catch (e) {
      setState(() {
        lectura = null;
        mostrarDetalle = false;
        mostrarFormularioActualizar = false;
        mensaje = 'No encontrado o error: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> actualizar() async {
    if (lectura == null) {
      setState(() {
        mensaje = 'Primero busca un medidor';
      });
      return;
    }

    final int? lecturaActual =
    int.tryParse(lecturaActualCtrl.text.trim());

    final double? latitud = double.tryParse(
      latitudCtrl.text.trim().replaceAll(',', '.'),
    );

    final double? longitud = double.tryParse(
      longitudCtrl.text.trim().replaceAll(',', '.'),
    );

    if (lecturaActual == null || latitud == null || longitud == null) {
      setState(() {
        mensaje = 'Verifica lectura actual, latitud y longitud';
      });
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final msg = await service.actualizarLectura(
        numeroMedidor: medidorCtrl.text.trim(),
        lecturaActual: lecturaActual,
        fechaLectura: fechaCtrl.text.trim(),
        latitud: latitud,
        longitud: longitud,
      );

      await buscar();
      await listarTodo();

      setState(() {
        mensaje = msg;
        mostrarFormularioActualizar = false;
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

  Future<void> refrescarTodo() async {
    await listarTodo();

    if (medidorCtrl.text.trim().isNotEmpty) {
      await buscar();
    }
  }

  // =========================
  // WIDGETS AUXILIARES
  // =========================
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

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturas de agua'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: refrescarTodo,
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
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: cargando ? null : listarTodo,
                          icon: const Icon(Icons.list),
                          label: const Text('Listar'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: cargando ? null : refrescarTodo,
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar'),
              ),
            ),

            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: 8),
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
                    buildInfoRow('Latitud', lectura!.latitud),
                    buildInfoRow('Longitud', lectura!.longitud),
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
                        label: const Text('Actualizar / Completar datos'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (mostrarDetalle && mostrarFormularioActualizar && lectura != null) ...[
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
                    TextField(
                      controller: fechaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Fecha (YYYY-MM-DD HH:MM:SS)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latitudCtrl,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Latitud',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: longitudCtrl,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Longitud',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                mostrarFormularioActualizar = false;
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

            const SizedBox(height: 18),
            const Text(
              'Listado completo',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            if (cargando)
              const Center(child: CircularProgressIndicator()),

            ...lecturas.map((item) {
              return Card(
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
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