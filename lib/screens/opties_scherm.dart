import 'package:flutter/material.dart';
import '../main.dart';

class OptiesScherm extends StatefulWidget {
  // Callback om alles te wissen en meteen op te slaan
  final Future<void> Function()? onWisAlles;

  const OptiesScherm({Key? key, this.onWisAlles}) : super(key: key);

  @override
  State<OptiesScherm> createState() => _OptiesSchermState();
}

class _OptiesSchermState extends State<OptiesScherm> {
  Future<void> _vraagBevestiging() async {
    final bevestig = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weet je het zeker?'),
        content: const Text(
            'Alle transacties en spaarsaldi worden permanent gewist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bevestigen'),
          ),
        ],
      ),
    );

    if (bevestig == true && widget.onWisAlles != null) {
      await widget.onWisAlles!();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alle gegevens zijn gewist'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opties'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Instellingen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _vraagBevestiging,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Wis alles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Druk op "Wis alles" om alle transacties en spaarsaldi te resetten.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}