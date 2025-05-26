import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:monitoreo/screens/cambiar_contrasena_screen.dart';
import 'package:monitoreo/screens/configuracion_screen.dart';
import 'package:monitoreo/screens/mapa_empresa_widget.dart';

class PerfilScreen extends StatefulWidget {
  @override
  _PerfilScreenState createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String nombre = '';
  String correo = '';
  String rol = '';
  String? fotoUrl;
  File? _image;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

      setState(() {
        nombre = userDoc['nombre'] ?? '';
        correo = user.email ?? '';
        rol = userDoc['rol'] ?? '';
        fotoUrl = userDoc['fotoPerfil'];
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _subirImagenAFirebase();
    }
  }

  Future<void> _subirImagenAFirebase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (_image != null && user != null) {
      final storageRef =
          FirebaseStorage.instance.ref().child('fotos_perfil/${user.uid}.jpg');

      await storageRef.putFile(_image!);
      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({'fotoPerfil': url});

      setState(() {
        fotoUrl = url;
      });
    }
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade600),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfiguracionScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // FOTO DE PERFIL
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.white,
                    backgroundImage: fotoUrl != null
                        ? NetworkImage(fotoUrl!)
                        : const AssetImage('assets/images/user.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.green),
                        onPressed: _seleccionarImagen,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // INFO CARDS
            _buildInfoCard(Icons.person, 'Nombre', nombre),
            _buildInfoCard(Icons.email, 'Correo', correo),
            _buildInfoCard(Icons.security, 'Rol', rol),

            const SizedBox(height: 30),

            // BOTÓN CAMBIAR CONTRASEÑA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CambiarContrasenaScreen()),
                  );
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Cambiar Contraseña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // MAPA
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Ubicación de la empresa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            MapaEmpresaWidget(),
          ],
        ),
      ),
    );
  }
}
