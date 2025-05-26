import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ModoTema { claro, oscuro, verde }

class TemaProvider extends ChangeNotifier {
  ModoTema _modoTema = ModoTema.claro;
  String _fuenteActual = 'Roboto';

  // Getters públicos para uso en ConfiguracionScreen
  String get nombreTema => _modoTema.name;
  String get fuente => _fuenteActual;

  // Getter para obtener el tema actual con la fuente aplicada
  ThemeData get tema {
    switch (_modoTema) {
      case ModoTema.oscuro:
        return ThemeData.dark().copyWith(
          textTheme: _aplicarFuente(_fuenteActual, ThemeData.dark().textTheme),
        );
      case ModoTema.verde:
        return ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.green[50],
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green),
          textTheme: _aplicarFuente(_fuenteActual, ThemeData.light().textTheme),
        );
      case ModoTema.claro:
      default:
        return ThemeData.light().copyWith(
          textTheme: _aplicarFuente(_fuenteActual, ThemeData.light().textTheme),
        );
    }
  }

  /// Aplica la fuente personalizada al TextTheme base
  TextTheme _aplicarFuente(String fuente, TextTheme base) {
    return base.apply(fontFamily: fuente);
  }

  /// Cambiar tema desde un String (claro, oscuro, verde)
  Future<void> cambiarTema(String nombre) async {
    switch (nombre) {
      case 'oscuro':
        _modoTema = ModoTema.oscuro;
        break;
      case 'verde':
        _modoTema = ModoTema.verde;
        break;
      case 'claro':
      default:
        _modoTema = ModoTema.claro;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('modoTema', _modoTema.index);
    notifyListeners();
  }

  /// Cambiar fuente
  Future<void> cambiarFuente(String nuevaFuente) async {
    _fuenteActual = nuevaFuente;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fuenteActual', nuevaFuente);
    notifyListeners();
  }

  /// Cargar preferencias al iniciar app
  Future<void> cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final modoIndex = prefs.getInt('modoTema') ?? 0;
    _modoTema = ModoTema.values[modoIndex];
    _fuenteActual = prefs.getString('fuenteActual') ?? 'Roboto';
    notifyListeners();
  }
}
