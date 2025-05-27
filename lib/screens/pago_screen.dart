import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PagoScreen extends StatefulWidget {
  @override
  _PagoScreenState createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  CardFieldInputDetails? _cardDetails;
  bool _loading = false;

  Future<void> _realizarPago() async {
    if (_cardDetails == null || !_cardDetails!.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa una tarjeta válida')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. Crear PaymentIntent
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer sk_test_XXXXXXXXXXXXXXXXXXXXXXX', // Tu SECRET_KEY (no usar en producción frontend)
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': '10000', // $100.00 MXN en centavos
          'currency': 'mxn',
          'payment_method_types[]': 'card',
        },
      );

      final jsonResponse = json.decode(response.body);
      final clientSecret = jsonResponse['client_secret'];

      // 2. Confirmar pago
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ¡Pago exitoso!')),
      );
    } catch (e) {
      print('Error en el pago: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al procesar el pago')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simular Pago', style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white
        )),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ingresa los datos de tu tarjeta',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 20),
      CardField(
        onCardChanged: (card) {
          setState(() => _cardDetails = card);
        },
        style: TextStyle(fontSize: 18),
      ),
      SizedBox(height: 30),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _realizarPago,
          icon: Icon(Icons.payment),
          label: Text(_loading ? 'Procesando...' : 'Pagar \$100.00 MXN'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: 16),
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}
