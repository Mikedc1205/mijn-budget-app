import 'package:flutter/material.dart';
import 'secure_storage_service.dart'; // Je service
import 'set_pin_screen.dart';         // Scherm om PIN in te stellen
import 'enter_pin_screen.dart';      // Scherm om PIN in te voeren
import 'home_screen.dart';           // Je normale hoofdscherm (PAS DIT EVENTUEEL AAN)
import 'main.dart';
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

enum AuthState {
  unknown, // We weten nog niet of er een PIN is, of deze al is ingevoerd
  noPinSet,  // Er is nog geen PIN ingesteld door de gebruiker
  pinLocked, // Er is een PIN, maar de app is nog vergrendeld
  unlocked   // De app is ontgrendeld (of er was geen PIN nodig)
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SecureStorageService _storageService = SecureStorageService();
  AuthState _authState = AuthState.unknown;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    // Voorkom onnodige rebuilds als de status al bepaald is (bijv. na unlock)
    if (_authState == AuthState.unlocked || _authState == AuthState.noPinSet && mounted) {
      // Als we al unlocked zijn, of als er geen pin is ingesteld en we navigeren naar SetPinScreen,
      // dan hoeven we niet opnieuw te checken tenzij specifiek getriggerd.
      // Als we al op noPinSet staan en SetPinScreen wordt getoond, zal die de status wijzigen via zijn callback.
      return;
    }

    setState(() {
      _authState = AuthState.unknown; // Begin als onbekend tijdens het laden
    });

    final bool hasPin = await _storageService.hasPin();
    if (!mounted) return; // Controleer of widget nog bestaat

    if (hasPin) {
      setState(() {
        _authState = AuthState.pinLocked; // Er is een PIN, dus app is vergrendeld
      });
    } else {
      setState(() {
        _authState = AuthState.noPinSet; // Geen PIN, dus gebruiker moet er een instellen
      });
    }
  }

  void _onPinSuccessfullySet() {
    // Nadat de PIN is ingesteld, is de app nog steeds "vergrendeld"
    // en moet de gebruiker deze de eerste keer invoeren,
    // of we kunnen direct naar unlocked gaan als dat de gewenste flow is.
    // Voor nu gaan we naar pinLocked, zodat de gebruiker de net ingestelde PIN kan invoeren.
    // Dit kan je aanpassen naar AuthState.unlocked als je wilt dat na het instellen direct toegang is.
    if (mounted) {
      setState(() {
        _authState = AuthState.pinLocked; // Of AuthState.unlocked als je dat prefereert
      });
      // Je zou _checkPinStatus opnieuw kunnen aanroepen om te verifiëren, maar SetPinScreen
      // zou dit al moeten garanderen.
    }
  }

  void _onPinVerified() {
    if (mounted) {
      setState(() {
        _authState = AuthState.unlocked; // PIN correct, app ontgrendeld
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_authState) {
      case AuthState.unknown:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(), // Laadscherm
          ),
        );
      case AuthState.noPinSet:
        return SetPinScreen(
          onPinSuccessfullySet: _onPinSuccessfullySet,
        );
      case AuthState.pinLocked:
        return EnterPinScreen(
          onPinVerified: _onPinVerified,
        );
      case AuthState.unlocked:
      // BELANGRIJK: Vervang HomeScreen() door het daadwerkelijke
      // hoofdscherm van je applicatie nadat de gebruiker is ingelogd/ontgrendeld.
        return const MainAppScreen(); // <-- VERANDER DIT
    }
  }
}