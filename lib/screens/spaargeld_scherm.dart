import 'package:flutter/material.dart';
import '../main.dart'; // Voor toegang tot de globale 'spaarsaldi' map en Transactie model
import '../screens/voeg_spaar_transactie_toe_scherm.dart'; // NIEUW: Importeer het scherm voor spaartransacties

class SpaargeldScherm extends StatefulWidget {
  final Future<void> Function()? onSpaargeldChanged;

  const SpaargeldScherm({Key? key, this.onSpaargeldChanged}) : super(key: key);

  @override
  State<SpaargeldScherm> createState() => _SpaargeldSchermState();
}

class _SpaargeldSchermState extends State<SpaargeldScherm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Spaargeld'),
        centerTitle: true,
      ),
      body: spaarsaldi.isEmpty
          ? const Center(
        child: Text(
          'Nog geen spaarsaldi. Voeg transacties toe!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: spaarsaldi.length,
        itemBuilder: (context, index) {
          String bankNaam = spaarsaldi.keys.elementAt(index);
          double saldo = spaarsaldi.values.elementAt(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Icon(
                Icons.account_balance,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(
                bankNaam,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '€ ${saldo.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: saldo >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
              onTap: () {
                // print('Getikt op $bankNaam');
              },
            ),
          );
        },
      ),
      // NIEUW: FloatingActionButton toegevoegd
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Transactie>(
            context,
            MaterialPageRoute(
              builder: (_) => VoegSpaarTransactieToeScherm(), // Nieuw scherm
            ),
          );

          if (result != null) {
            setState(() {
              // De transactie is van het type 'spaar', dus we voegen het bedrag toe aan de bank
              // De 'main.dart' logica voor 'spaar' transacties zal dit ook doen.
              // We triggeren hier een update van de spaarsaldi om de UI direct te verversen.
              spaarsaldi[result.bank] = (spaarsaldi[result.bank] ?? 0) + result.bedrag;

              // Roep de callback aan om de data op te slaan in SharedPreferences
              if (widget.onSpaargeldChanged != null) {
                widget.onSpaargeldChanged!();
              }
            });
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Voeg geld toe aan spaarpot',
      ),
    );
  }
}