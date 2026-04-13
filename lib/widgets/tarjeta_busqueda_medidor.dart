import 'package:flutter/material.dart';

class TarjetaBusquedaMedidor extends StatelessWidget {
  final TextEditingController medidorCtrl;
  final bool cargando;
  final VoidCallback onBuscar;
  final VoidCallback onListarTodo;

  const TarjetaBusquedaMedidor({
    super.key,
    required this.medidorCtrl,
    required this.cargando,
    required this.onBuscar,
    required this.onListarTodo,
  });

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
                Icon(Icons.search, size: 20),
                SizedBox(width: 8),
                Text(
                  'Buscar medidor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: medidorCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (!cargando) {
                  onBuscar();
                }
              },
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
                    onPressed: cargando ? null : onBuscar,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: cargando ? null : onListarTodo,
                    icon: const Icon(Icons.list),
                    label: const Text('Listar todo'),
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