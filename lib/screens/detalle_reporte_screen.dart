import 'package:flutter/material.dart';

class DetalleReporteScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetalleReporteScreen({super.key, required this.data});

  Color getColorPorImportancia(String importancia) {
    switch (importancia.toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'media':
        return Colors.orangeAccent;
      case 'baja':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = List<String>.from(data['imagenes'] ?? []);
    final colorImportancia = getColorPorImportancia(data['grado_importancia'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del reporte', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Unidad: ${data['unidad'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Fecha: ${data['fecha']} - ${data['hora']}",
                        style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Importancia: ",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Chip(
                          label: Text(data['grado_importancia'] ?? 'N/A'),
                          backgroundColor: colorImportancia.withOpacity(0.2),
                          labelStyle: TextStyle(color: colorImportancia),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Descripción:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(data['descripcion'] ?? 'Sin descripción',
                        style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (imagenes.isNotEmpty) ...[
              const Text("Evidencias:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              ...imagenes.map((url) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 200,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image));
                      },
                    ),
                  )),
            ] else
              const Text("Sin imágenes adjuntas",
                  style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
