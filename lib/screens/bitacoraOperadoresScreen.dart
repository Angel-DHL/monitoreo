import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class BitacoraOperadoresScreen extends StatelessWidget {
  const BitacoraOperadoresScreen({super.key});

  Future<void> compartirReporteExcel(BuildContext context) async {
  final filePath = '/storage/emulated/0/Download/bitacora_operadores.xlsx';
  final file = File(filePath);

  if (await file.exists()) {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Bitácora de operadores generada desde la app.',
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Primero genera el archivo Excel')),
    );
  }
}


  Future<void> generarReporteExcel(BuildContext context) async {
    var status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado')),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Bitácora'];

    // Encabezados
    List<String> headers = [
      'Unidad',
      'Operador',
      'Tipo Registro',
      'Fecha Salida',
      'Hora Salida',
      'Fecha Entrada',
      'Hora Entrada',
      'Cliente',
      'Manifiesto',
      'Orden Servicio',
      'Salida Almacén',
      'Observaciones o Insumos',
      'Báscula',
      'Observaciones Entrada',
    ];
    sheetObject.appendRow(headers);

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bitacora_operadores')
        .orderBy('id_bitacora', descending: true)
        .get();

    final dateFormatter = DateFormat('yyyy-MM-dd');

    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      bool isSalida = data['tipo_registro'] == 'Salida';

      List<dynamic> row = [
        data['unidad'] ?? '',
        data['operador'] ?? '',
        data['tipo_registro'] ?? '',
        isSalida && data['fecha_salida'] != null ? dateFormatter.format(data['fecha_salida'].toDate()) : '',
        isSalida ? data['hora_salida'] ?? '' : '',
        !isSalida && data['fecha_entrada'] != null ? dateFormatter.format(data['fecha_entrada'].toDate()) : '',
        !isSalida ? data['hora_entrada'] ?? '' : '',
        data['cliente'] ?? '',
        data['manifiesto'] ?? '',
        isSalida ? data['orden_servicio'] ?? '' : '',
        isSalida ? data['salida_almacen'] ?? '' : '',
        isSalida ? data['observaciones'] ?? '' : '',
        !isSalida ? data['bascula'] ?? '' : '',
        !isSalida ? data['observaciones_entrada'] ?? '' : '',
      ];
      sheetObject.appendRow(row.map((e) => e.toString()).toList());
    }

    final downloadsPath = Directory('/storage/emulated/0/Download');
    String filePath = '${downloadsPath.path}/bitacora_operadores.xlsx';
    var fileBytes = excel.encode();

    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al generar el archivo Excel')),
      );
      return;
    }

    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reporte generado en: $filePath')),
    );

    await OpenFile.open(filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bitácora de Operadores',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => generarReporteExcel(context),
            tooltip: 'Generar Reporte Excel',
          ),
          IconButton(
    icon: const Icon(Icons.share),
    onPressed: () => compartirReporteExcel(context),
    tooltip: 'Compartir Reporte Excel',
  ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('bitacora_operadores')
            .orderBy('id_bitacora', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay registros en la bitácora'));
          }

          var registros = snapshot.data!.docs;
          final dateFormatter = DateFormat('yyyy-MM-dd');

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
                      DataColumn(label: Text('Operador')),
                      DataColumn(label: Text('Tipo Registro')),
                      DataColumn(label: Text('Fecha Salida')),
                      DataColumn(label: Text('Hora Salida')),
                      DataColumn(label: Text('Fecha Entrada')),
                      DataColumn(label: Text('Hora Entrada')),
                      DataColumn(label: Text('Cliente')),
                      DataColumn(label: Text('Manifiesto')),
                      DataColumn(label: Text('Orden Servicio')),
                      DataColumn(label: Text('Salida Almacén')),
                      DataColumn(label: Text('Observaciones o Insumos')),
                      DataColumn(label: Text('Báscula')),
                      DataColumn(label: Text('Observaciones')),
                    ],
                    rows: registros.map<DataRow>((registro) {
                      String tipoRegistro = registro['tipo_registro'] ?? 'Desconocido';
                      bool isSalida = tipoRegistro == 'Salida';

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color>((states) {
                          return isSalida ? Colors.red.shade100 : Colors.greenAccent.shade100;
                        }),
                        cells: [
                          DataCell(Text(registro['unidad'] ?? 'Desconocido')),
                          DataCell(Text(registro['operador'] ?? 'Desconocido')),
                          DataCell(Text(tipoRegistro)),
                          DataCell(Text(isSalida && registro['fecha_salida'] != null
                              ? dateFormatter.format(registro['fecha_salida'].toDate())
                              : '')),
                          DataCell(Text(isSalida ? registro['hora_salida'] ?? '' : '')),
                          DataCell(Text(!isSalida && registro['fecha_entrada'] != null
                              ? dateFormatter.format(registro['fecha_entrada'].toDate())
                              : '')),
                          DataCell(Text(!isSalida ? registro['hora_entrada'] ?? '' : '')),
                          DataCell(Text(registro['cliente'] ?? '')),
                          DataCell(Text(registro['manifiesto'] ?? '')),
                          DataCell(Text(isSalida ? (registro['orden_servicio'] ?? '') : '')),
                          DataCell(Text(isSalida ? (registro['salida_almacen'] ?? '') : '')),
                          DataCell(Text(isSalida ? (registro['observaciones'] ?? '') : '')),
                          DataCell(Text(!isSalida ? (registro['bascula'] ?? '') : '')),
                          DataCell(Text(!isSalida ? (registro['observaciones_entrada'] ?? '') : '')),
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
