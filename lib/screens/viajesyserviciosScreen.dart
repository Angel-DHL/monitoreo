import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViajesYServiciosScreen extends StatefulWidget {
  @override
  _ViajesYServiciosScreenState createState() => _ViajesYServiciosScreenState();
}

class _ViajesYServiciosScreenState extends State<ViajesYServiciosScreen> {
  String? unidadSeleccionada;
  String? operador;
  List<Map<String, dynamic>> servicios = [];

  Future<List<String>> obtenerUnidadesEnServicio() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('unidades')
        .where('Estado', isEqualTo: 'EN SERVICIO')
        .get();

    final unidades = snapshot.docs.map((doc) => doc.id).toList();

    unidades.sort((a, b) {
      final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    return unidades;
  }

  Future<void> cargarServicios(String unidad) async {
    final viajeSnapshot = await FirebaseFirestore.instance
        .collection('viajesyservicios')
        .where('Unidad', isEqualTo: unidad)
        .get();

    if (viajeSnapshot.docs.isNotEmpty) {
      final viajeDoc = viajeSnapshot.docs.first;
      final operadorNombre = viajeDoc['Operador'] ?? 'Desconocido';

      final serviciosSnapshot = await viajeDoc.reference
          .collection('servicios')
          .get();

      setState(() {
        operador = operadorNombre;
        servicios = serviciosSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } else {
      setState(() {
        operador = null;
        servicios = [];
      });
    }
  }

  Color obtenerColorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'EN TRÁNSITO':
        return Colors.yellow;
      case 'EN CLIENTE':
        return Colors.blue;
      case 'FINALIZADO':
        return Colors.green;
      case 'PENDIENTE':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Viajes y Servicios',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (unidadSeleccionada != null) {
                cargarServicios(unidadSeleccionada!);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<String>>(
              future: obtenerUnidadesEnServicio(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                final unidades = snapshot.data!;
                return DropdownButton<String>(
                  isExpanded: true,
                  value: unidadSeleccionada,
                  hint: Text('Selecciona una unidad'),
                  items: unidades.map((unidad) {
                    return DropdownMenuItem<String>(
                      value: unidad,
                      child: Text(unidad),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      unidadSeleccionada = valor;
                    });
                    if (valor != null) cargarServicios(valor);
                  },
                );
              },
            ),
            if (operador != null) ...[
              SizedBox(height: 16),
              Text(
                'Operador: $operador',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
            SizedBox(height: 16),
            Expanded(
              child: servicios.isEmpty
                  ? Text('No hay servicios para esta unidad.')
                  : ListView.builder(
                      itemCount: servicios.length,
                      itemBuilder: (context, index) {
                        final servicio = servicios[index];
                        final estado = servicio['Estado'] ?? 'N/A';
                        final colorEstado = obtenerColorEstado(estado);
                        final stop = servicio['Stop']?.toString();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (stop != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: Text(
                                    'STOP: $stop',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800]),
                                  ),
                                ),
                              ),
                            Stack(
                              children: [
                                Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          servicio['Cliente'] ?? 'Sin cliente',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text(
                                              'Llegada: ${servicio['Hora Llegada'] ?? 'N/A'}',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.schedule_outlined, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text(
                                              'Salida: ${servicio['Hora Salida'] ?? 'N/A'}',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text(
                                              'Estado: $estado',
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Círculo de color del estado
                                Positioned(
                                  top: 15,
                                  right: 15,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: colorEstado,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
