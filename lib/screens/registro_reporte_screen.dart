import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monitoreo/screens/lista_reportes_screen.dart';
import 'package:uuid/uuid.dart';

class RegistroReporteScreen extends StatefulWidget {
  @override
  _RegistroReporteScreenState createState() => _RegistroReporteScreenState();
}

class _RegistroReporteScreenState extends State<RegistroReporteScreen> {
  final _descripcionController = TextEditingController();
  String? _unidadSeleccionada;
  String? _gradoImportancia;
  List<XFile> _imagenes = [];
  bool _subiendo = false;

  List<String> _unidades = [];
  final _grados = ['ALTA', 'MEDIA', 'BAJA'];

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
  }

  Future<void> _cargarUnidades() async {
    final snapshot = await FirebaseFirestore.instance.collection('unidades').get();

    final unidades = snapshot.docs.map((doc) => doc.id).toList();

    unidades.sort((a, b) {
      final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    setState(() {
      _unidades = unidades;
    });
  }

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        _imagenes.add(foto);
      });
    }
  }

  Future<void> _seleccionarImagenes() async {
    final picker = ImagePicker();
    final List<XFile>? seleccionadas = await picker.pickMultiImage();
    if (seleccionadas != null) {
      setState(() {
        _imagenes = seleccionadas;
      });
    }
  }

  Future<List<String>> _subirImagenes() async {
    List<String> urls = [];
    for (var img in _imagenes) {
      final file = File(img.path);
      final fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('reportes_fallas/$fileName.jpg');
      if (!file.existsSync()) {
        throw Exception("El archivo no existe: ${img.path}");
      }
      try {
        final uploadTask = await ref.putFile(file);
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print('Error al subir la imagen: $e');
      }
    }
    return urls;
  }

  Future<void> _guardarReporte() async {
    if (_unidadSeleccionada == null || _gradoImportancia == null || _descripcionController.text.isEmpty || _imagenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor completa todos los campos.')));
      return;
    }

    setState(() => _subiendo = true);
    final urls = await _subirImagenes();

    final now = DateTime.now();
    final id = const Uuid().v4();

    await FirebaseFirestore.instance.collection('reportes_fallas').add({
      'id_reporte': id,
      'unidad': _unidadSeleccionada,
      'descripcion': _descripcionController.text,
      'fecha': "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}",
      'hora': "${now.hour}:${now.minute.toString().padLeft(2, '0')}",
      'grado_importancia': _gradoImportancia,
      'imagenes': urls,
    });

    setState(() => _subiendo = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reporte guardado.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green,
        title: Text(
          'Nuevo Reporte',
          style: TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Cambiar a vista normal',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListaReportesScreen()),
              );
            },
          ),
        ],
      ),
      body: _subiendo
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _unidades.isEmpty
                      ? CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: _unidadSeleccionada,
                          hint: Text('Selecciona una unidad'),
                          items: _unidades.map((unidad) {
                            return DropdownMenuItem(
                              value: unidad,
                              child: Text(unidad),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _unidadSeleccionada = value),
                        ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: 'Descripción del problema'),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _gradoImportancia,
                    hint: Text('Grado de importancia'),
                    items: _grados.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) => setState(() => _gradoImportancia = value),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _seleccionarImagenes,
                        icon: Icon(Icons.image),
                        label: Text('Desde galería'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _tomarFoto,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Tomar foto'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _imagenes.map((img) => Image.file(File(img.path), width: 80, height: 80)).toList(),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _guardarReporte,
                    child: Text('Guardar reporte'),
                  ),
                ],
              ),
            ),
    );
  }
}
