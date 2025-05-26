import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroViajesyServiciosScreen extends StatefulWidget {
  const RegistroViajesyServiciosScreen({super.key});

  @override
  State<RegistroViajesyServiciosScreen> createState() => _RegistroViajesyServiciosScreenState();
}

class _RegistroViajesyServiciosScreenState extends State<RegistroViajesyServiciosScreen> {
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
    servicios = List.generate(1, (_) => {"Cliente": "", "Estado": "", "Stop": ""});
  }

  Future<void> _cargarOperadoresYUnidades() async {
    final operadoresSnapshot = await FirebaseFirestore.instance.collection('operadores').get();
    final unidadesSnapshot = await FirebaseFirestore.instance.collection('unidades').get();

    setState(() {
      operadores = operadoresSnapshot.docs.map((doc) => doc['Nombre'].toString()).toList();
      unidades = unidadesSnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void _actualizarCantidadServicios(int cantidad) {
    setState(() {
      cantidadServicios = cantidad;
      servicios = List.generate(cantidad, (_) => {"Cliente": "", "Estado": "", "Stop": ""});
    });
  }

  Future<void> _registrarViajeYServicios() async {
    if (operadorSeleccionado == null || unidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona operador y unidad')));
      return;
    }

    // Obtener el número de la unidad para usarlo como id_viaje
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(unidadSeleccionada!);
    int idViaje = match != null ? int.parse(match.group(0)!) : DateTime.now().millisecondsSinceEpoch;

    final viajeDoc = await FirebaseFirestore.instance.collection('viajesyservicios').add({
      'Operador': operadorSeleccionado,
      'Unidad': unidadSeleccionada,
      'id viaje': idViaje,
    });

    for (int i = 0; i < servicios.length; i++) {
      final servicio = servicios[i];
      await viajeDoc.collection('servicios').doc('servicio${i + 1}').set({
        'Cliente': servicio['Cliente'],
        'Estado': servicio['Estado'],
        'Stop': servicio['Stop'],
        'Hora Llegada': '',
        'Hora Salida': '',
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viaje y servicios registrados exitosamente')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Viaje y Servicios'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Selecciona Operador:'),
            DropdownButton<String>(
              value: operadorSeleccionado,
              isExpanded: true,
              hint: const Text('Operador'),
              items: operadores.map((op) {
                return DropdownMenuItem(value: op, child: Text(op));
              }).toList(),
              onChanged: (value) => setState(() => operadorSeleccionado = value),
            ),
            const SizedBox(height: 10),
            const Text('Selecciona Unidad:'),
            DropdownButton<String>(
              value: unidadSeleccionada,
              isExpanded: true,
              hint: const Text('Unidad'),
              items: unidades.map((un) {
                return DropdownMenuItem(value: un, child: Text(un));
              }).toList(),
              onChanged: (value) => setState(() => unidadSeleccionada = value),
            ),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad de Servicios'),
              initialValue: cantidadServicios.toString(),
              onChanged: (value) {
                int cantidad = int.tryParse(value) ?? 1;
                _actualizarCantidadServicios(cantidad);
              },
            ),
            const SizedBox(height: 20),
            const Text('Datos de los Servicios:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...servicios.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> servicio = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servicio ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    onChanged: (val) => servicio['Cliente'] = val,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Estado'),
                    onChanged: (val) => servicio['Estado'] = val,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Stop'),
                    onChanged: (val) => servicio['Stop'] = val,
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrarViajeYServicios,
              child: const Text('Registrar Viaje y Servicios'),
            ),
          ],
        ),
      ),
    );
  }
}
