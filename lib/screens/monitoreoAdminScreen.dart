import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monitoreo/screens/monitoreoScreen.dart';

class MonitoreoAdminScreen extends StatefulWidget {
  const MonitoreoAdminScreen({super.key});

  @override
  _MonitoreoAdminScreenState createState() => _MonitoreoAdminScreenState();
}

class _MonitoreoAdminScreenState extends State<MonitoreoAdminScreen> {
  List<String> estadosDisponibles = ["DISPONIBLE", "PREVENTIVO", "CORRECTIVO"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitoreo de Unidades (Admin)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a vista normal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MonitoreoScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('unidades').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay unidades registradas'));
          }

          var unidades = snapshot.data!.docs;
          List<Map<String, dynamic>> unidadesNumeradas = [];
          List otrasUnidades = [];

          for (var unidad in unidades) {
            String nombre = unidad.id.trim();
            RegExp regexUnidad = RegExp(r'^UNIDAD #(\d+)$');
            Match? match = regexUnidad.firstMatch(nombre);
            if (match != null) {
              int numeroUnidad = int.parse(match.group(1)!);
              unidadesNumeradas.add({'doc': unidad, 'numero': numeroUnidad});
            } else {
              otrasUnidades.add(unidad);
            }
          }

          unidadesNumeradas.sort((a, b) => a['numero'].compareTo(b['numero']));
          otrasUnidades.sort((a, b) => a.id.compareTo(b.id));
          var unidadesOrdenadas = [...unidadesNumeradas.map((e) => e['doc']), ...otrasUnidades];

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 50.0,
                    headingTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    dataTextStyle: const TextStyle(fontSize: 18, color: Colors.black),
                    columns: const [
                      DataColumn(label: Text('Unidad')),
                      DataColumn(label: Text('Tipo')),
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('Modelo')),
                      DataColumn(label: Text('Placas')),
                    ],
                    rows: unidadesOrdenadas.map<DataRow>((unidad) {
                      String estadoActual = unidad['Estado']?.toString() ?? 'Desconocido';
                      Color estadoColor = _getEstadoColor(estadoActual);

                      return DataRow(
                        cells: [
                          DataCell(Text(unidad.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          DataCell(Text(unidad['Características del Vehículo']?.toString() ?? 'Desconocido')),
                          DataCell(
  estadoActual == 'EN SERVICIO'
      ? Text(
          estadoActual,
          style: TextStyle(
            color: _getEstadoColor(estadoActual),
            fontWeight: FontWeight.bold,
          ),
        )
      : DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: estadosDisponibles.contains(estadoActual) ? estadoActual : null,
            hint: const Text("Seleccionar estado"),
            items: estadosDisponibles.map((String estado) {
              return DropdownMenuItem<String>(
                value: estado,
                child: Text(
                  estado,
                  style: TextStyle(color: _getEstadoColor(estado)),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                _actualizarEstado(unidad.id, newValue);
              }
            },
          ),
        ),
),

                          DataCell(Text(unidad['Modelo']?.toString() ?? 'Desconocido')),
                          DataCell(Text(unidad['Placas']?.toString() ?? 'Desconocido')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _actualizarEstado(String unidadId, String nuevoEstado) {
    FirebaseFirestore.instance.collection('unidades').doc(unidadId).update({
      'Estado': nuevoEstado,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a $nuevoEstado')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $error')),
      );
    });
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'DISPONIBLE':
        return Colors.green;
      case 'PREVENTIVO':
        return Colors.amber;
      case 'CORRECTIVO':
        return Colors.red;
      case 'EN SERVICIO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
