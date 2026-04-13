import 'package:flutter/material.dart';

import '../models/lectura.dart';

class ItemLectura extends StatelessWidget {
  final Lectura item;
  final String titulo;
  final VoidCallback onTap;

  const ItemLectura({
    super.key,
    required this.item,
    required this.titulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        leading: const CircleAvatar(
          child: Icon(Icons.water_drop_outlined),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Medidor: ${item.numeroMedidor}\n'
                'Dirección: ${item.direccionServicio.isEmpty ? "-" : item.direccionServicio}\n'
                'Lectura anterior: ${item.lecturaAnterior}\n'
                'Lectura actual: ${item.lecturaActual}\n'
                'Fecha: ${item.fechaLectura ?? "-"}',
          ),
        ),
      ),
    );
  }
}