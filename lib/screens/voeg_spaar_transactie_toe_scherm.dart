// voeg_spaar_transactie_toe_scherm.dart

import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Kan grijs zijn als je 'intl' hier nog niet actief gebruikt
import '../main.dart'; // Voor Transactie model en spaarsaldi map

// =======================================================================
// DEZE CLASS MOET HIER STAAN!
// =======================================================================
class VoegSpaarTransactieToeScherm extends StatefulWidget {
  const VoegSpaarTransactieToeScherm({Key? key}) : super(key: key);

  @override
  State<VoegSpaarTransactieToeScherm> createState() => _VoegSpaarTransactieToeSchermState();
}
// =======================================================================

class _VoegSpaarTransactieToeSchermState extends State<VoegSpaarTransactieToeScherm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bedragController = TextEditingController();
  String geselecteerdeBank = spaarsaldi.keys.first; // Standaard de eerste bank
  final TextEditingController _omschrijvingController = TextEditingController();

  @override
  void dispose() {
    _bedragController.dispose();
    _omschrijvingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geld toevoegen aan spaarpot'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _bedragController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                  labelText: 'Bedrag',
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vul een bedrag in.';
                  }
                  final cleanedValue = value.replaceAll(',', '.');
                  final bedrag = double.tryParse(cleanedValue);
                  if (bedrag == null || bedrag <= 0) {
                    return 'Voer een geldig positief bedrag in.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: geselecteerdeBank,
                items: spaarsaldi.keys
                    .map((bankNaam) => DropdownMenuItem(value: bankNaam, child: Text(bankNaam)))
                    .toList(),
                onChanged: (nieuwe) {
                  if (nieuwe != null) {
                    setState(() {
                      geselecteerdeBank = nieuwe;
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Kies spaarpot',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _omschrijvingController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Omschrijving (optioneel)',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  print("DEBUG: 'GELD TOEVOEGEN' knop ingedrukt in VoegSpaarTransactieToeScherm"); // <--- PRINT 1

                  if (_formKey.currentState!.validate()) {
                    print("DEBUG: Formulier validatie GESLAAGD in VoegSpaarTransactieToeScherm"); // <--- PRINT 2 (succes)
                    final bedrag = double.tryParse(_bedragController.text.replaceAll(',', '.')) ?? 0.0;

                    // Creëer een 'spaar' transactie
                    final nieuweTransactie = Transactie(
                      // id: _uuid.v4(), // Zorg ervoor dat je Transactie class een ID genereert als je dit niet doet
                      datum: DateTime.now(), // Huidige datum
                      bedrag: bedrag,
                      type: 'spaar', // Altijd 'spaar' voor dit scherm
                      categorie: 'Spaaroverdracht', // Vaste categorie voor spaartransacties
                      bank: geselecteerdeBank,
                      omschrijving: _omschrijvingController.text.isNotEmpty
                          ? _omschrijvingController.text
                          : 'Geld toegevoegd aan $geselecteerdeBank spaarpot',
                      herhaling: 'Geen', // Geen herhaling voor handmatige spaartransactie
                      uitSpaarpot: false, // Dit is geen uitgave UIT de spaarpot
                    );

                    print("DEBUG: Nieuwe spaartransactie aangemaakt: bedrag=${nieuweTransactie.bedrag}, bank=${nieuweTransactie.bank}, type=${nieuweTransactie.type}"); // <--- PRINT 3
                    print("DEBUG: Ga nu Navigator.pop aanroepen in VoegSpaarTransactieToeScherm");

                    if (mounted) { // Controleer of de widget nog "gemonteerd" is (goede praktijk)
                      Navigator.pop(context, nieuweTransactie); // <--- DEZE REGEL IS BELANGRIJK!
                      // Het geeft 'nieuweTransactie' terug aan het vorige scherm.
                    }
                  } else {
                    print("DEBUG: Formulier validatie MISLUKT in VoegSpaarTransactieToeScherm"); // <--- PRINT 2 (mislukt)
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'GELD TOEVOEGEN',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Annuleer en ga terug
                },
                child: const Text('ANNULEREN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}