import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:monitoreo/theme/tema_provider.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final temaProvider = Provider.of<TemaProvider>(context);
    final temaActual = temaProvider.nombreTema;
    final fuenteActual = temaProvider.fuente;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración',
        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema de la aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: temaActual,
              items: const [
                DropdownMenuItem(value: 'claro', child: Text('Claro')),
                DropdownMenuItem(value: 'oscuro', child: Text('Oscuro')),
                DropdownMenuItem(value: 'verde', child: Text('Verde personalizado')),
              ],
              onChanged: (value) {
                if (value != null) {
                  temaProvider.cambiarTema(value);
                }
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Fuente de la aplicación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: fuenteActual,
              items: const [
                DropdownMenuItem(value: 'Roboto', child: Text('Clásica (Roboto)')),
                DropdownMenuItem(value: 'Rock', child: Text('Elegante (Rock)')),
                DropdownMenuItem(value: 'Beans', child: Text('Informal (Beans)')),
                DropdownMenuItem(value: 'F25', child: Text('Informal (F25)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  temaProvider.cambiarFuente(value);
                }
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cambios aplicados y guardados')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar configuración'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
