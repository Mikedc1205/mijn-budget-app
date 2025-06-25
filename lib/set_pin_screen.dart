import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Voor TextInputFormatter
import 'secure_storage_service.dart'; // Importeer je service

class SetPinScreen extends StatefulWidget {
  // Callback om aan te geven dat de pincode succesvol is ingesteld.
  // Dit is handig voor de AuthWrapper later.
  final VoidCallback? onPinSuccessfullySet;

  const SetPinScreen({Key? key, this.onPinSuccessfullySet}) : super(key: key);

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _storageService = SecureStorageService();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _savePin() async {
    setState(() {
      _errorMessage = null; // Reset foutmelding
      _isLoading = true; // Toon laadindicator
    });

    // Validatie
    if (_pinController.text.length != 4) {
      setState(() {
        _errorMessage = 'Pincode moet 4 cijfers lang zijn.';
        _isLoading = false;
      });
      return;
    }
    if (_confirmPinController.text.length != 4) {
      setState(() {
        _errorMessage = 'Bevestigingspincode moet 4 cijfers lang zijn.';
        _isLoading = false;
      });
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'Pincodes komen niet overeen.';
        _isLoading = false;
      });
      return;
    }

    try {
      await _storageService.savePin(_pinController.text);
      if (mounted) { // Controleer of de widget nog steeds in de tree is
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pincode succesvol opgeslagen!')),
        );
        // Roep de callback aan als die is meegegeven
        widget.onPinSuccessfullySet?.call();

        // Navigeer terug of naar het volgende scherm.
        // Als onPinSuccessfullySet is gebruikt door AuthWrapper,
        // zal die de navigatie afhandelen. Anders kun je hier direct navigeren.
        // Voor nu laten we de AuthWrapper dit later bepalen.
        // Als je dit scherm direct test, wil je misschien pop-en:
        // if (Navigator.canPop(context)) {
        //   Navigator.pop(context, true); // Geef 'true' terug om succes aan te geven
        // }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Fout bij opslaan pincode: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Verberg laadindicator
        });
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stel Pincode In'),
        automaticallyImplyLeading: false, // Geen terug-pijl als dit het eerste scherm is
      ),
      body: Center( // Centreer de inhoud
        child: SingleChildScrollView( // Maakt scrollen mogelijk op kleinere schermen
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Knoppen volledige breedte
            children: [
              const Icon(Icons.lock_person_outlined, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text(
                'Kies een 4-cijferige pincode om uw app te beveiligen.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true, // Maak de ingevoerde cijfers onzichtbaar
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: 'Pincode (4 cijfers)',
                  counterText: "", // Verberg de standaard teller (0/4)
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pin),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly // Accepteer alleen cijfers
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  labelText: 'Bevestig Pincode',
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.pin),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
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
                onPressed: _savePin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent, // Thema kleur
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Pincode Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}