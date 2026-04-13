import 'package:flutter/material.dart';

import '../models/lectura.dart';

class TarjetaSincronizacion extends StatelessWidget {
  final int pendientesSync;
  final int erroresSync;
  final bool cargando;
  final bool sincronizando;
  final String progresoSync;
  final List<Lectura> lecturasConError;
  final VoidCallback onSincronizar;

  const TarjetaSincronizacion({
    super.key,
    required this.pendientesSync,
    required this.erroresSync,
    required this.cargando,
    required this.sincronizando,
    required this.progresoSync,
    required this.lecturasConError,
    required this.onSincronizar,
  });

  Widget _buildInfoRow(String titulo, dynamic valor) {
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

  @override
  Widget build(BuildContext context) {
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
            const Row(
              children: [
                Icon(Icons.sync, size: 20),
                SizedBox(width: 8),
                Text(
                  'Sincronización',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow('Pendientes', pendientesSync),
            _buildInfoRow('Errores', erroresSync),
            if (progresoSync.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                progresoSync,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (cargando || sincronizando || pendientesSync == 0)
                    ? null
                    : onSincronizar,
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  sincronizando ? 'Sincronizando...' : 'Sincronizar ahora',
                ),
              ),
            ),
            if (lecturasConError.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Lecturas con novedades',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...lecturasConError.map(
                    (e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Medidor: ${e.numeroMedidor}'),
                      Text('Fecha: ${e.fechaLectura ?? "-"}'),
                      Text('Error: ${e.syncError ?? "Error no identificado"}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}