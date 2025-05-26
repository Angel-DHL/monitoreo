import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiciosOperadorScreen extends StatefulWidget {
  final String nombreOperador;

  const ServiciosOperadorScreen({super.key, required this.nombreOperador});

  @override
  State<ServiciosOperadorScreen> createState() => _ServiciosOperadorScreenState();
}

class _ServiciosOperadorScreenState extends State<ServiciosOperadorScreen> {
  late Future<List<Map<String, dynamic>>> _serviciosFuturos;

  @override
  void initState() {
    super.initState();
    _serviciosFuturos = _cargarServiciosDelOperador();
  }

  Future<List<Map<String, dynamic>>> _cargarServiciosDelOperador() async {
    List<Map<String, dynamic>> lista = [];

    var viajesSnap = await FirebaseFirestore.instance
        .collection('viajesyservicios')
        .where('Operador', isEqualTo: widget.nombreOperador)
        .get();

    for (var viajeDoc in viajesSnap.docs) {
      var serviciosSnap = await viajeDoc.reference.collection('servicios').get();
      for (var servicio in serviciosSnap.docs) {
        var data = servicio.data();
        lista.add({
          'docId': servicio.id,
          'viajeRef': viajeDoc.reference,
          'cliente': data['Cliente'],
          'estado': data['Estado'],
          'horaLlegada': data['Hora Llegada'],
          'horaSalida': data['Hora Salida'],
          'stop': data['Stop'],
        });
      }
    }

    lista.sort((a, b) => int.parse(a['stop'].toString()).compareTo(int.parse(b['stop'].toString())));
    return lista;
  }

  Future<void> _registrarLlegada(Map<String, dynamic> servicio) async {
    String horaActual = DateFormat('hh:mm a').format(DateTime.now());
    await servicio['viajeRef']
        .collection('servicios')
        .doc(servicio['docId'])
        .update({'Hora Llegada': horaActual, 'Estado': 'EN CLIENTE'});
    _recargarServicios();
  }

  Future<void> _registrarSalida(Map<String, dynamic> servicio) async {
    String horaActual = DateFormat('hh:mm a').format(DateTime.now());

    // Finaliza el actual
    await servicio['viajeRef']
        .collection('servicios')
        .doc(servicio['docId'])
        .update({'Hora Salida': horaActual, 'Estado': 'FINALIZADO'});

    // Encuentra el siguiente servicio (por stop)
    List<Map<String, dynamic>> todos = await _cargarServiciosDelOperador();
    int stopActual = int.parse(servicio['stop'].toString());
    var siguiente = todos.firstWhere(
        (s) => int.parse(s['stop'].toString()) > stopActual && s['estado'] == 'PENDIENTE',
        orElse: () => {});

    if (siguiente.isNotEmpty) {
      await siguiente['viajeRef']
          .collection('servicios')
          .doc(siguiente['docId'])
          .update({'Estado': 'EN TRÁNSITO'});
    }

    _recargarServicios();
  }

  void _recargarServicios() {
    setState(() {
      _serviciosFuturos = _cargarServiciosDelOperador();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Servicios', style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(onPressed: _recargarServicios, icon: const Icon(Icons.refresh)),
        ],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _serviciosFuturos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes servicios asignados.'));
          }

          return ListView.builder(
  itemCount: snapshot.data!.length,
  itemBuilder: (_, index) {
    final servicio = snapshot.data![index];
    final servicios = snapshot.data!;

    // Encuentra el primer servicio no finalizado (activo)
    final primerServicioActivo = servicios.firstWhere(
      (s) => s['estado'] != 'FINALIZADO',
      orElse: () => {},
    );

    final esServicioActivo = servicio['docId'] == primerServicioActivo['docId'];

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(
          'Cliente: ${servicio['cliente']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stop: ${servicio['stop']}', style: const TextStyle(fontSize: 16)),
            Text('Estado: ${servicio['estado']}', style: const TextStyle(fontSize: 16)),
            Text('Hora Llegada: ${servicio['horaLlegada'] ?? ''}', style: const TextStyle(fontSize: 16)),
            Text('Hora Salida: ${servicio['horaSalida'] ?? ''}', style: const TextStyle(fontSize: 16)),
          ],
        ),
        trailing: Column(
          children: [
            if ((servicio['estado'] == 'PENDIENTE' || servicio['estado'] == 'EN TRÁNSITO') && esServicioActivo)
              ElevatedButton(
                onPressed: () => _registrarLlegada(servicio),
                child: const Text('Llegada'),
              ),
            if (servicio['estado'] == 'EN CLIENTE' && esServicioActivo)
              ElevatedButton(
                onPressed: () => _registrarSalida(servicio),
                child: const Text('Salida'),
              ),
          ],
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
