import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_reporte_screen.dart';

class ListaReportesScreen extends StatelessWidget {
  const ListaReportesScreen({super.key});

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

  IconData getIconoPorImportancia(String importancia) {
    switch (importancia.toLowerCase()) {
      case 'alta':
        return Icons.warning;
      case 'media':
        return Icons.report_problem;
      case 'baja':
        return Icons.info;
      default:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de fallas',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reportes_fallas')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reportes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final data = reportes[index].data() as Map<String, dynamic>;
              final importancia = data['grado_importancia'] ?? 'desconocida';
              final color = getColorPorImportancia(importancia);
              final icono = getIconoPorImportancia(importancia);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleReporteScreen(data: data),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icono, color: color),
                    ),
                    title: Text(
                      data['unidad'] ?? 'Sin unidad',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Importancia: ${data['grado_importancia'] ?? 'N/A'}',
                          style: TextStyle(color: color),
                        ),
                        const SizedBox(height: 2),
                        Text('Fecha: ${data['fecha'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
