// ... tus imports originales
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:monitoreo/screens/bitacoraOperadoresScreen.dart';

class RegistroOperadorScreen extends StatefulWidget {
  const RegistroOperadorScreen({super.key});

  @override
  _RegistroOperadorScreenState createState() => _RegistroOperadorScreenState();
}

class _RegistroOperadorScreenState extends State<RegistroOperadorScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedUnidad;
  String? selectedOperador;
  DateTime? fechaSalida, fechaEntrada;
  TimeOfDay? horaSalida, horaEntrada;
  String? cliente, manifiesto, salidaAlmacen, ordenServicio, observaciones, bascula, observacionesEntrada;
  String tipoRegistro = "Salida";

  List<String> unidades = [];
  List<String> operadores = [];

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
    _cargarOperadores();
  }

  void _cargarUnidades() async {
    FirebaseFirestore.instance.collection('unidades').snapshots().listen((snapshot) {
      List<String> unidadesSinOrdenar = snapshot.docs.map((doc) => doc.id.trim()).toList();

      List<Map<String, dynamic>> unidadesNumeradas = [];
      List<String> otrasUnidades = [];

      for (var unidad in unidadesSinOrdenar) {
        RegExp regexUnidad = RegExp(r'^UNIDAD #(\d+)$', caseSensitive: false);
        Match? match = regexUnidad.firstMatch(unidad);

        if (match != null) {
          int numeroUnidad = int.parse(match.group(1)!);
          unidadesNumeradas.add({'nombre': unidad, 'numero': numeroUnidad});
        } else {
          otrasUnidades.add(unidad);
        }
      }

      unidadesNumeradas.sort((a, b) => a['numero'].compareTo(b['numero']));
      otrasUnidades.sort();

      var unidadesOrdenadas = [
        ...unidadesNumeradas.map((e) => e['nombre'] as String),
        ...otrasUnidades
      ];

      setState(() {
        unidades = unidadesOrdenadas;
      });
    });
  }

  void _cargarOperadores() async {
    FirebaseFirestore.instance.collection('operadores').snapshots().listen((snapshot) {
      setState(() {
        operadores = snapshot.docs.map((doc) => doc['Nombre'] as String).toList();
      });
    });
  }

  Future<void> _selectDate(BuildContext context, bool isSalida) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        isSalida ? fechaSalida = picked : fechaEntrada = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isSalida) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        isSalida ? horaSalida = picked : horaEntrada = picked;
      });
    }
  }

  Future<int> _obtenerNuevoIdBitacora() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bitacora_operadores')
        .orderBy('id_bitacora', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      int ultimoId = snapshot.docs.first['id_bitacora'] ?? 0;
      return ultimoId + 1;
    } else {
      return 1;
    }
  }

  void _registrar() {
    if (_formKey.currentState?.validate() ?? false) {
      DateTime now = DateTime.now();

      if (tipoRegistro == "Salida") {
        if (fechaSalida != null && fechaSalida!.isAfter(now)) {
          _mostrarError('La fecha de salida no puede ser posterior a la actual.');
          return;
        }

        if (horaSalida != null) {
          final horaActual = TimeOfDay.now();
          final ahora = DateTime(now.year, now.month, now.day, horaActual.hour, horaActual.minute);
          final salida = DateTime(fechaSalida!.year, fechaSalida!.month, fechaSalida!.day, horaSalida!.hour, horaSalida!.minute);
          if (salida.isAfter(ahora)) {
            _mostrarError('La hora de salida no puede ser mayor a la actual.');
            return;
          }
        }

        if (manifiesto != null && manifiesto!.isNotEmpty && int.tryParse(manifiesto!) == null) {
          _mostrarError('El manifiesto debe ser un valor numérico.');
          return;
        }

      } else {
        if (fechaEntrada != null && fechaEntrada!.isAfter(now)) {
          _mostrarError('La fecha de entrada no puede ser posterior a la actual.');
          return;
        }

        if (horaEntrada != null) {
          final horaActual = TimeOfDay.now();
          final ahora = DateTime(now.year, now.month, now.day, horaActual.hour, horaActual.minute);
          final entrada = DateTime(fechaEntrada!.year, fechaEntrada!.month, fechaEntrada!.day, horaEntrada!.hour, horaEntrada!.minute);
          if (entrada.isAfter(ahora)) {
            _mostrarError('La hora de entrada no puede ser mayor a la actual.');
            return;
          }
        }
      }

      _obtenerNuevoIdBitacora().then((nuevoId) {
        FirebaseFirestore.instance.collection('bitacora_operadores').add({
          'id_bitacora': nuevoId,
          'tipo_registro': tipoRegistro,
          'unidad': selectedUnidad,
          'operador': selectedOperador,
          'fecha_salida': fechaSalida != null ? Timestamp.fromDate(fechaSalida!) : null,
          'hora_salida': horaSalida?.format(context),
          'cliente': cliente,
          'manifiesto': manifiesto,
          'salida_almacen': salidaAlmacen,
          'orden_servicio': ordenServicio,
          'observaciones': observaciones,
          'bascula': bascula,
          'fecha_entrada': fechaEntrada != null ? Timestamp.fromDate(fechaEntrada!) : null,
          'hora_entrada': horaEntrada?.format(context),
          'observaciones_entrada': observacionesEntrada,
        }).then((_) {
          String nuevoEstado = tipoRegistro == "Salida" ? "EN SERVICIO" : "DISPONIBLE";

          Map<String, dynamic> updateData = {
            'Estado': nuevoEstado,
            'Operador': tipoRegistro == "Salida" ? selectedOperador : 'NA',
          };

          FirebaseFirestore.instance
              .collection('unidades')
              .doc(selectedUnidad)
              .update(updateData);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso')),
          );
          _limpiarCampos();
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        });
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registro de Operador',
          style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: 'Bitácora',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => BitacoraOperadoresScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double textScaleFactor = MediaQuery.of(context).textScaleFactor;
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio(value: "Salida", groupValue: tipoRegistro, onChanged: (value) => setState(() => tipoRegistro = value!), activeColor: Colors.blue),
                        Text("Salida", style: TextStyle(fontSize: 18 * textScaleFactor)),
                        const SizedBox(width: 20),
                        Radio(value: "Entrada", groupValue: tipoRegistro, onChanged: (value) => setState(() => tipoRegistro = value!), activeColor: Colors.blue),
                        Text("Entrada", style: TextStyle(fontSize: 18 * textScaleFactor)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (tipoRegistro == "Salida") ...[
                      _buildDateTimeField("Fecha Salida", fechaSalida, () => _selectDate(context, true)),
                      _buildDateTimeField("Hora Salida", horaSalida, () => _selectTime(context, true)),
                      _buildDropdownField("Unidad", selectedUnidad, unidades, (value) => setState(() => selectedUnidad = value)),
                      _buildDropdownField("Operador", selectedOperador, operadores, (value) => setState(() => selectedOperador = value)),
                      _buildTextField("Cliente", (value) => cliente = value),
                      _buildTextField("Manifiesto", (value) => manifiesto = value),
                      _buildTextField("Salida Almacén", (value) => salidaAlmacen = value, isObligatorio: false),
                      _buildTextField("Orden de Servicio", (value) => ordenServicio = value, isObligatorio: false),
                      _buildTextField("Observaciones o Insumos", (value) => observaciones = value, isObligatorio: false),
                    ] else ...[
                      _buildDateTimeField("Fecha Entrada", fechaEntrada, () => _selectDate(context, false)),
                      _buildDateTimeField("Hora Entrada", horaEntrada, () => _selectTime(context, false)),
                      _buildDropdownField("Unidad", selectedUnidad, unidades, (value) => setState(() => selectedUnidad = value)),
                      _buildDropdownField("Operador", selectedOperador, operadores, (value) => setState(() => selectedOperador = value)),
                      _buildTextField("Báscula", (value) => bascula = value, isObligatorio: false),
                      _buildTextField("Observaciones", (value) => observacionesEntrada = value, isObligatorio: false),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _registrar,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Registrar', style: TextStyle(color: Colors.white, fontSize: 28 * textScaleFactor)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(String label, dynamic value, VoidCallback onTap) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 18)),
      controller: TextEditingController(
        text: value is DateTime
            ? DateFormat('yyyy-MM-dd').format(value)
            : value is TimeOfDay
                ? value.format(context)
                : '',
      ),
      readOnly: true,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField(
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 18)),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged, {bool isObligatorio = true}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 18)),
      onChanged: onChanged,
      validator: (value) {
        if (isObligatorio && (value == null || value.isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }

  void _limpiarCampos() {
  setState(() {
    selectedUnidad = null;
    selectedOperador = null;
    fechaSalida = null;
    horaSalida = null;
    fechaEntrada = null;
    horaEntrada = null;
    cliente = null;
    manifiesto = null;
    salidaAlmacen = null;
    ordenServicio = null;
    observaciones = null;
    bascula = null;
    observacionesEntrada = null;
    tipoRegistro = "Salida";
  });
  _formKey.currentState?.reset();
  }
}
