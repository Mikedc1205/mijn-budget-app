import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Maak een instance van FlutterSecureStorage
  final _storage = const FlutterSecureStorage();

  // Definieer een constante voor de sleutel waaronder we de pincode opslaan.
  // Dit voorkomt typefouten later.
  static const _pinKey = 'user_pin_code';

  /// Slaat de pincode versleuteld op.
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Haalt de opgeslagen pincode op.
  /// Geeft null terug als er geen pincode is opgeslagen.
  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  /// Verwijdert de opgeslagen pincode.
  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  /// Controleert of er een pincode is opgeslagen.
  /// Geeft true terug als er een pincode is, anders false.
  Future<bool> hasPin() async {
    final pin = await getPin();
    // Een pincode "bestaat" als het niet null is EN niet leeg is.
    return pin != null && pin.isNotEmpty;
  }
}