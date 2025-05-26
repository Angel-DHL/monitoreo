import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monitoreo/screens/accesodenegadoScreen.dart';
import 'package:monitoreo/screens/lista_reportes_screen.dart';
import 'package:monitoreo/screens/registroViajesyserviciosOperadores.dart';
import 'package:monitoreo/screens/registro_reporte_screen.dart';
import 'package:monitoreo/screens/serviciosOperadorScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:monitoreo/screens/monitoreoScreen.dart';
import 'package:monitoreo/screens/monitoreoAdminScreen.dart';
import 'package:monitoreo/screens/loginScreen.dart';
import 'package:monitoreo/screens/registroOperadoresScreen.dart';
import 'package:monitoreo/screens/bitacoraOperadoresScreen.dart';
import 'package:monitoreo/screens/viajesyserviciosScreen.dart';
import 'package:monitoreo/screens/registroViajesyserviciosScreen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Monitoreo de Unidades',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('email');
              await prefs.remove('password');
              await prefs.setBool('rememberMe', false);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: screenSize.height * 0.05,
                      bottom: screenSize.height * 0.02,
                    ),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: screenSize.height * 0.2,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildButton(
                          context,
                          'Monitoreo de\nUnidades',
                          () async {
                            await _navigateToMonitoreo(context);
                          },
                          isLandscape,
                          screenSize,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        _buildButton(
                          context,
                          'Viajes y\nServicios',
                          () async {
                            await _navigateToViajesYServicios(context);
                          },
                          isLandscape,
                          screenSize,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        _buildButton(
                          context,
                          'Registro de\nOperadores',
                          () async {
                            await _navigateToRegistroOperadores(context);
                          },
                          isLandscape,
                          screenSize,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        _buildButton(
                          context,
                          'Servicios Operadores',
                          () async {
                            await _navigateToServiciosOperadores(context);
                          },
                          isLandscape,
                          screenSize,
                        ),
                        SizedBox(height: screenSize.height * 0.03),
                        _buildButton(
                          context,
                          'Reportes Unidades',
                          () async {
                            await _navigateToReportesUnidades(context);
                          },
                          isLandscape,
                          screenSize,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToMonitoreo(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      String? rol = userDoc['rol'];

      if (rol != null) {
        rol = rol.toLowerCase();

        if (rol == 'admin' || rol == 'mantenimiento') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MonitoreoAdminScreen()),
          );
        } else if (rol == 'operador') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccesoDenegadoScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MonitoreoScreen()),
          );
        }
      }
    }
  }

  Future<void> _navigateToRegistroOperadores(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      String? rol = userDoc['rol'];
      if (rol != null && ['admin', 'operador'].contains(rol.toLowerCase())) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => RegistroOperadorScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BitacoraOperadoresScreen()));
      }
    }
  }

  Future<void> _navigateToReportesUnidades(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      String? rol = userDoc['rol'];

      if (rol != null) {
        rol = rol.toLowerCase();

        if (rol == 'admin' || rol == 'vigilancia' || rol == 'mantenimiento') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistroReporteScreen()),
          );
        } else if (rol == 'operador' || rol == 'ventas') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccesoDenegadoScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListaReportesScreen()),
          );
        }
      }
    }
  }

  Future<void> _navigateToViajesYServicios(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      String? rol = userDoc['rol'];

      if (rol != null) {
        rol = rol.toLowerCase();

        if (rol == 'admin' || rol == 'logistica') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistroViajesyserviciosOperadores()),
          );
        } else if (rol == 'operador' || rol == 'vigilancia' || rol == 'mantenimiento') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AccesoDenegadoScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViajesYServiciosScreen()),
          );
        }
      }
    }
  }

  Future<void> _navigateToServiciosOperadores(BuildContext context) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    
    String? rol = userDoc['rol'];
    String? nombre = userDoc['nombre']; 

    if (rol != null && rol.toLowerCase() == 'operador' && nombre != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiciosOperadorScreen(nombreOperador: nombre),
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AccesoDenegadoScreen()));
    }
  }
}

  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed, bool isLandscape, Size screenSize) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(
          isLandscape ? screenSize.width * 0.5 : screenSize.width * 0.6,
          isLandscape ? screenSize.height * 0.08 : screenSize.height * 0.1,
        ),
        textStyle: TextStyle(
          fontSize: isLandscape ? screenSize.width * 0.04 : screenSize.width * 0.05,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.green,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isLandscape ? screenSize.width * 0.04 : screenSize.width * 0.05,
        ),
      ),
    );
  }
}
