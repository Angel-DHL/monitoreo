import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monitoreo/screens/viajesyserviciosScreen.dart';

class RegistroViajesyserviciosOperadores extends StatefulWidget {
  const RegistroViajesyserviciosOperadores({super.key});

  @override
  State<RegistroViajesyserviciosOperadores> createState() =>
      _RegistroViajesyserviciosOperadoresState();
}

class _RegistroViajesyserviciosOperadoresState
    extends State<RegistroViajesyserviciosOperadores> {
  String? operadorSeleccionado;
  String? unidadSeleccionada;
  int cantidadServicios = 1;

  List<Map<String, dynamic>> servicios = [];

  List<String> operadores = [];
  List<String> unidades = [];

  @override
  void initState() {
    super.initState();
    _cargarOperadoresYUnidades();
    servicios = List.generate(1, (index) => {
          'cliente': '',
          'estado': 'PENDIENTE',
          'stop': index + 1,
        });
  }

  Future<void> _cargarOperadoresYUnidades() async {
    var operadoresSnap =
        await FirebaseFirestore.instance.collection('operadores').get();
    var unidadesSnap =
        await FirebaseFirestore.instance.collection('unidades').get();

    setState(() {
      operadores =
          operadoresSnap.docs.map((doc) => doc['Nombre'].toString()).toList();

      unidades = unidadesSnap.docs
          .map((doc) => doc.id.toString())
          .toList()
        ..sort((a, b) {
          final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return numA.compareTo(numB);
        });
    });
  }

Future<void> _registrarViajeYServicios() async {
  if (operadorSeleccionado == null || unidadSeleccionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debes seleccionar operador y unidad')),
    );
    return;
  }

  // ✅ Validar campos de cliente
  bool camposIncompletos = servicios.any((servicio) => servicio['cliente'].trim().isEmpty);

  if (camposIncompletos) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debes completar todos los campos de cliente en los servicios')),
    );
    return;
  }

  String idViaje = unidadSeleccionada!.replaceAll(RegExp(r'[^0-9]'), '');

  DocumentReference viajeRef = FirebaseFirestore.instance
      .collection('viajesyservicios')
      .doc(idViaje);

  DocumentSnapshot docSnapshot = await viajeRef.get();

  if (docSnapshot.exists) {
    var serviciosSnap = await viajeRef.collection('servicios').get();
    for (var doc in serviciosSnap.docs) {
      await doc.reference.delete();
    }
  }

  await viajeRef.set({
    'Operador': operadorSeleccionado,
    'Unidad': unidadSeleccionada,
    'id viaje': int.tryParse(idViaje) ?? 0,
  });

  for (int i = 0; i < servicios.length; i++) {
    await viajeRef.collection('servicios').doc('servicio${i + 1}').set({
      'Cliente': servicios[i]['cliente'],
      'Estado': servicios[i]['estado'],
      'Stop': servicios[i]['stop'],
      'Hora Llegada': '',
      'Hora Salida': '',
    });
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Viaje y servicios registrados correctamente')),
  );

  setState(() {
    operadorSeleccionado = null;
    unidadSeleccionada = null;
    cantidadServicios = 1;
    servicios = List.generate(1, (index) => {
          'cliente': '',
          'estado': 'PENDIENTE',
          'stop': index + 1,
        });
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Viaje y Servicios', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a vista normal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ViajesYServiciosScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: operadorSeleccionado,
              items: operadores
                  .map((op) =>
                      DropdownMenuItem(value: op, child: Text(op)))
                  .toList(),
              onChanged: (val) => setState(() => operadorSeleccionado = val),
              decoration: const InputDecoration(labelText: 'Selecciona operador'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: unidadSeleccionada,
              items: unidades
                  .map((uni) =>
                      DropdownMenuItem(value: uni, child: Text(uni)))
                  .toList(),
              onChanged: (val) => setState(() => unidadSeleccionada = val),
              decoration: const InputDecoration(labelText: 'Selecciona unidad'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: cantidadServicios,
              items: List.generate(
                10,
                (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}'),
                ),
              ),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    cantidadServicios = val;
                    servicios = List.generate(val, (index) => {
                          'cliente': '',
                          'estado': 'PENDIENTE',
                          'stop': index + 1,
                        });
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Cantidad de servicios'),
            ),
            const SizedBox(height: 16),
            ...List.generate(cantidadServicios, (index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servicio ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    onChanged: (val) => servicios[index]['cliente'] = val,
                  ),
                  DropdownButtonFormField<int>(
                    value: int.tryParse(servicios[index]['stop'].toString()) ?? 1,
                    items: List.generate(
                      10,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (val) => setState(() {
                      servicios[index]['stop'] = val ?? 1;
                    }),
                    decoration: const InputDecoration(labelText: 'Stop'),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _registrarViajeYServicios,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            )
          ],
        ),
      ),
    );
  }
}
