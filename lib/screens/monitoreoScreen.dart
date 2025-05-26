import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoreoScreen extends StatelessWidget {
  const MonitoreoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Monitoreo de Unidades',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
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

          var unidadesOrdenadas = [
            ...unidadesNumeradas.map((e) => e['doc']),
            ...otrasUnidades
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical, // Permite desplazamiento vertical
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Permite desplazamiento horizontal
                  child: DataTable(
                    columnSpacing: 50.0,
                    headingTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    dataTextStyle: const TextStyle(fontSize: 18, color: Colors.black),
                    columns: const [
  DataColumn(label: Text('Unidad')),
  DataColumn(label: Text('Tipo')),
  DataColumn(label: Text('Estado')),
  DataColumn(label: Text('Operador')), // NUEVA COLUMNA
  DataColumn(label: Text('Modelo')),
  DataColumn(label: Text('Placas')),
],
rows: unidadesOrdenadas.map<DataRow>((unidad) {
  // Definir el color según el estado
  Color estadoColor = Colors.grey;
  String estado = unidad['Estado']?.toString() ?? 'Desconocido';

  if (estado == 'DISPONIBLE') {
    estadoColor = Colors.green;
  } else if (estado == 'PREVENTIVO') {
    estadoColor = Colors.yellow;
  } else if (estado == 'CORRECTIVO') {
    estadoColor = Colors.red;
  } else if (estado == 'EN SERVICIO') {
    estadoColor = Colors.blue;
  }

  return DataRow(
    cells: [
      DataCell(Text(unidad.id, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      DataCell(Text(unidad['Características del Vehículo']?.toString() ?? 'Desconocido')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: estadoColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            estado,
            style: TextStyle(color: estadoColor == Colors.green ? Colors.white : Colors.black),
          ),
        ),
      ),
      DataCell(Text(unidad['Operador']?.toString() ?? 'Desconocido')), // NUEVO DATO
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
}
