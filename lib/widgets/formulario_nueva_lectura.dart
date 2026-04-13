import 'dart:io';

import 'package:flutter/material.dart';

import '../models/lectura.dart';

class FormularioNuevaLectura extends StatelessWidget {
  final Lectura lectura;
  final TextEditingController lecturaActualCtrl;
  final TextEditingController observacionCtrl;
  final bool cargando;
  final String? fotoGuardadaPath;
  final String? fotoFechaTomaExif;
  final double? fotoLatitudExif;
  final double? fotoLongitudExif;
  final VoidCallback onTomarFoto;
  final VoidCallback onCancelar;
  final VoidCallback onGuardar;

  const FormularioNuevaLectura({
    super.key,
    required this.lectura,
    required this.lecturaActualCtrl,
    required this.observacionCtrl,
    required this.cargando,
    required this.fotoGuardadaPath,
    required this.fotoFechaTomaExif,
    required this.fotoLatitudExif,
    required this.fotoLongitudExif,
    required this.onTomarFoto,
    required this.onCancelar,
    required this.onGuardar,
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
    final anteriorAutomatica =
    lectura.lecturaActual > 0 ? lectura.lecturaActual : lectura.lecturaAnterior;

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
                Icon(Icons.edit_note, size: 20),
                SizedBox(width: 8),
                Text(
                  'Nueva lectura',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow('Anterior automática', anteriorAutomatica),
            const SizedBox(height: 12),
            TextField(
              controller: lecturaActualCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Lectura actual',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: observacionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: cargando ? null : onTomarFoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  fotoGuardadaPath == null ? 'Tomar foto' : 'Volver a tomar foto',
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text('Fecha: ${fotoFechaTomaExif ?? "-"}'),
              Text('Latitud: ${fotoLatitudExif?.toString() ?? "-"}'),
              Text('Longitud: ${fotoLongitudExif?.toString() ?? "-"}'),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancelar,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: cargando ? null : onGuardar,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}