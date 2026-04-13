import 'package:flutter/material.dart';

import '../models/lectura.dart';

class TarjetaDetalleCuenta extends StatelessWidget {
  final Lectura lectura;
  final VoidCallback onRegistrarNuevaLectura;

  const TarjetaDetalleCuenta({
    super.key,
    required this.lectura,
    required this.onRegistrarNuevaLectura,
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
                Icon(Icons.description_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Datos de la cuenta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildInfoRow('ID cuenta', lectura.idCuenta),
            _buildInfoRow('Código cuenta', lectura.codigoCuenta),
            _buildInfoRow('ID propietario', lectura.idPropietario),
            _buildInfoRow('Medidor', lectura.numeroMedidor),
            _buildInfoRow('Dirección', lectura.direccionServicio),
            _buildInfoRow('Teléfono', lectura.telefonoContacto),
            _buildInfoRow('Lectura anterior', lectura.lecturaAnterior),
            _buildInfoRow('Lectura actual', lectura.lecturaActual),
            _buildInfoRow('Consumo m3', lectura.consumoM3),
            _buildInfoRow('Fecha lectura', lectura.fechaLectura),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRegistrarNuevaLectura,
                icon: const Icon(Icons.edit),
                label: const Text('Registrar nueva lectura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}