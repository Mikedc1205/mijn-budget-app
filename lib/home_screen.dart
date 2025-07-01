import 'package:flutter/material.dart';
import 'secure_storage_service.dart'; // Voorbeeld: om PIN te kunnen resetten
import 'auth_wrapper.dart'; // Om opnieuw te kunnen authenticeren

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<void> _resetPin(BuildContext context) async {
    final storageService = SecureStorageService();
    await storageService.deletePin();

    // Navigeer terug naar de AuthWrapper zodat de gebruiker een nieuwe PIN kan instellen.
    // De AuthWrapper zal de status opnieuw controleren en naar SetPinScreen gaan.
    // Zorg ervoor dat de AuthWrapper de root is van je MaterialApp of een widget die niet
    // gepopt wordt op een manier dat de staat verloren gaat.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (Route<dynamic> route) => false, // Verwijder alle voorgaande routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Budget App - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), // Of Icon(Icons.lock_reset)
            tooltip: 'Pincode opnieuw instellen',
            onPressed: () async {
              // Vraag bevestiging voordat de pincode wordt verwijderd
              final confirm = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Pincode opnieuw instellen?'),
                    content: const Text(
                        'Weet u zeker dat u uw huidige pincode wilt verwijderen en een nieuwe wilt instellen? U wordt hiervoor uitgelogd.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuleren'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Ja, opnieuw instellen'),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await _resetPin(context);
              }
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Welkom bij je Budget App!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}