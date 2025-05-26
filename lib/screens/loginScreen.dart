import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monitoreo/screens/homeScreen.dart';
import 'package:monitoreo/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String _errorMessage = '';
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isVisible = false; // Para el fade-in

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();

    // Animación de aparición de pantalla
    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _isVisible = true;
      });
    });
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      _rememberMe = true;
      _login(); // Auto-login
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor, completa todos los campos.');
      return;
    }

    _showLoadingDialog();

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        Navigator.pop(context); // Cierra el loading
        setState(() => _errorMessage = 'No se encontró el usuario en Firestore.');
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? role = userData['rol'];
      String? nombre = userData['nombre'];

      if (role == null) {
        Navigator.pop(context);
        setState(() => _errorMessage = 'Tu cuenta no tiene un rol asignado.');
        return;
      }

      if (role == 'admin' || role == 'logistica' || role == 'ventas' || role == 'vigilancia' || role == 'mantenimiento' || role == 'operador') {
        // Guardar token FCM
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM Token: $fcmToken");

        if (fcmToken != null) {
          await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
            'fcm_token': fcmToken,
          }, SetOptions(merge: true));
        }

        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString('email', _emailController.text);
          await prefs.setString('password', _passwordController.text);
        } else {
          await prefs.remove('email');
          await prefs.remove('password');
        }

        Navigator.pop(context); // Cierra el loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, ${nombre ?? 'Usuario'}!'),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pop(context);
        setState(() => _errorMessage = 'No tienes permisos suficientes.');
      }
    } catch (e) {
      Navigator.pop(context);
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Iniciar Sesión',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isLandscape = constraints.maxWidth > constraints.maxHeight;

          return AnimatedOpacity(
            duration: Duration(milliseconds: 700),
            opacity: _isVisible ? 1.0 : 0.0,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.jpg',
                        height: isLandscape ? 100 : 250,
                      ),
                      SizedBox(height: isLandscape ? 10 : 30),
                      _buildTextField(_emailController, 'Correo electrónico', false, null),
                      SizedBox(height: 15),
                      _buildTextField(_passwordController, 'Contraseña', true, _togglePasswordVisibility),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text('Recuérdame'),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildLoginButton(isLandscape),
                      if (_errorMessage.isNotEmpty) _buildErrorMessage(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isPassword, VoidCallback? toggleVisibility) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: toggleVisibility,
              )
            : null,
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Widget _buildLoginButton(bool isLandscape) {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 30 : 50,
          vertical: isLandscape ? 12 : 15,
        ),
        backgroundColor: Colors.green,
        textStyle: TextStyle(fontSize: isLandscape ? 16 : 24),
      ),
      child: Text(
        'Iniciar sesión',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Column(
      children: [
        SizedBox(height: 15),
        Text(
          _errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
