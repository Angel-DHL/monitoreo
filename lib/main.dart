import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monitoreo/screens/loginScreen.dart';
import 'package:monitoreo/screens/onboarding_screen.dart'; // 👈 Agrega esta importación
import 'package:monitoreo/theme/tema_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Necesario para prefs
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Stripe.publishableKey = 'pk_test_51RTA9bCinwZigjPMsiE47iI9O3mklercDNJudoalFDXFFtZfOItYLPZnwGMcDrVD6VYOY0sHP1qqEbVmNzrm9j3B00TNQHh80y';
  await Stripe.instance.applySettings();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print('📲 Notificación en primer plano: ${message.notification!.title} - ${message.notification!.body}');
    }
  });

  final prefs = await SharedPreferences.getInstance();
  final temaProvider = TemaProvider();
  await temaProvider.cargarPreferencias();

  final bool onboardingCompletado = prefs.getBool('onboarding_completado') ?? false;

  runApp(
    ChangeNotifierProvider<TemaProvider>.value(
      value: temaProvider,
      child: MyApp(mostrarOnboarding: !onboardingCompletado),
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Mensaje recibido en segundo plano: ${message.notification?.title}");
}

class MyApp extends StatelessWidget {
  final bool mostrarOnboarding;
  const MyApp({super.key, required this.mostrarOnboarding});

  @override
  Widget build(BuildContext context) {
    final temaProvider = Provider.of<TemaProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitoreo App',
      theme: temaProvider.tema,
      home: mostrarOnboarding ? OnboardingScreen() : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
