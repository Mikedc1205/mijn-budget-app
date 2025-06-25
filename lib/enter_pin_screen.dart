import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Voor TextInputFormatter
import 'secure_storage_service.dart'; // Importeer je service

class EnterPinScreen extends StatefulWidget {
  // Callback die wordt aangeroepen als de pincode correct is geverifieerd.
  final VoidCallback onPinVerified;

  const EnterPinScreen({Key? key, required this.onPinVerified}) : super(key: key);

  @override
  State<EnterPinScreen> createState() => _EnterPinScreenState();
}

class _EnterPinScreenState extends State<EnterPinScreen> {
  final _pinController = TextEditingController();
  final _storageService = SecureStorageService();
  String? _errorMessage;
  bool _isLoading = false;
  int _failedAttempts = 0; // Optioneel: om het aantal foute pogingen bij te houden

  Future<void> _verifyPin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (_pinController.text.length != 4) {
      setState(() {
        _errorMessage = 'Voer een 4-cijferige pincode in.';
        _isLoading = false;
      });
      return;
    }

    final storedPin = await _storageService.getPin();

    if (storedPin == _pinController.text) {
      // Pincode correct! Roep de callback aan.
      widget.onPinVerified();
      // Je zou hier _isLoading = false kunnen zetten, maar omdat we navigeren,
      // is het misschien niet nodig dat deze widget nog updatet.
    } else {
      _failedAttempts++;
      setState(() {
        _errorMessage = 'Incorrecte pincode.';
        // Optioneel: meer geavanceerde logica voor mislukte pogingen
        if (_failedAttempts >= 3) {
          _errorMessage = 'Te veel foute pogingen. Probeer het later opnieuw.';
          // Hier zou je de knop kunnen uitschakelen voor een tijdje,
          // of de gebruiker uitloggen/app sluiten etc.
        }
        _pinController.clear(); // Maak het veld leeg voor een nieuwe poging
        _isLoading = false;
      });
    }
    // Zorg ervoor dat de lader stopt als er een fout was maar we niet navigeren
    if (mounted && _isLoading && storedPin != _pinController.text) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Geen AppBar, voor een meer "lock screen" gevoel
      body: Center( // Centreer de inhoud
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_open_outlined, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Voer uw pincode in',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                autofocus: true, // Toetsenbord direct openen
                style: const TextStyle(fontSize: 24, letterSpacing: 10), // Grotere cijfers, meer ruimte
                decoration: InputDecoration(
                  // labelText: 'Pincode', // Kan, maar is al duidelijk door de titel
                  counterText: "", // Verberg de standaard teller
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pin),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                onChanged: (value) {
                  // Optioneel: automatisch submitten als 4 cijfers zijn ingevoerd
                  if (value.length == 4 && !_isLoading) {
                    _verifyPin();
                  }
                },
                onSubmitted: (_) { // Ook submitten bij 'enter' op toetsenbord
                  if (!_isLoading) _verifyPin();
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ontgrendelen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}