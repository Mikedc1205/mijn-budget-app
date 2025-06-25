import 'package:flutter/material.dart';
import '../main.dart'; // Voor toegang tot de globale 'spaarsaldi' map en Transactie model
import '../screens/voeg_spaar_transactie_toe_scherm.dart'; // Importeer het scherm voor spaartransacties

class SpaargeldScherm extends StatefulWidget {
  final Future<void> Function()? onSpaargeldChanged;
  final Future<void> Function(Transactie transactie)? onAddTransactie; // Moet er zijn

  const SpaargeldScherm({
    Key? key,
    this.onSpaargeldChanged,
    required this.onAddTransactie, // Maak het 'required' om zeker te zijn dat het wordt meegegeven
  }) : super(key: key);

  @override
  State<SpaargeldScherm> createState() => _SpaargeldSchermState();
}

class _SpaargeldSchermState extends State<SpaargeldScherm> {
  @override
  Widget build(BuildContext context) {
    // Haal de globale spaarsaldi map op.
    // We werken direct met de globale 'spaarsaldi' omdat dit scherm een overzicht is.
    // Als je transacties toevoegt/wijzigt die dit beïnvloeden, zorgt setState ervoor dat het herbouwt.
    final Map<String, double> huidigeSpaarsaldi = Map.from(spaarsaldi); // Kopie voor veiligheid binnen deze build cyclus

    // Filter de banknamen: haal "Cash" eruit als je dat wilt
    final List<String> bankNamen = huidigeSpaarsaldi.keys
        .where((bankNaam) => bankNaam.toLowerCase() != 'cash') // Optioneel: filter 'Cash'
        .toList();

    // Sorteer de banknamen alfabetisch (optioneel, voor consistentie)
    bankNamen.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Bereken het totale spaargeld (alleen van de getoonde banken)
    double totaalSpaargeldGetoond = 0;
    for (String bankNaam in bankNamen) {
      totaalSpaargeldGetoond += huidigeSpaarsaldi[bankNaam] ?? 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Spaargeld'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (bankNamen.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Text(
                'Totaal gespaard: €${totaalSpaargeldGetoond.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary), // Gebruik Theme.of(context).colorScheme.primary
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: bankNamen.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Je hebt nog geen spaarpotten (exclusief "Cash" indien gefilterd).\nVoeg geld toe aan een spaarpot via de "+" knop.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Padding aangepast
              itemCount: bankNamen.length,
              itemBuilder: (context, index) {
                String bankNaam = bankNamen[index];
                double saldo = huidigeSpaarsaldi[bankNaam] ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16), // Iets meer verticale padding
                    leading: Icon(
                      Icons.account_balance_wallet_outlined, // Ander icoontje
                      color: Theme.of(context).colorScheme.primary, // Gebruik Theme
                      size: 30, // Iets groter icoon
                    ),
                    title: Text(
                      bankNaam,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '€ ${saldo.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: saldo >= 0
                            ? (saldo == 0 ? Colors.orange[700] : Colors.green[700]) // Oranje voor 0?
                            : Colors.red[700],
                      ),
                    ),
                    onTap: () {
                      // TODO: Navigeer naar een scherm dat transacties voor 'bankNaam' toont.
                      // Hiervoor heb je een nieuw scherm nodig (bijv. BankTransactieLijstScherm)
                      // of een aanpassing van je bestaande TransactionListScherm.
                      // Je moet 'bankNaam' en de volledige 'transacties' lijst meegeven.
                      // Ook callbacks zoals onDeleteTransactie en onEditTransactie
                      // als je die functionaliteit wilt vanuit het detailscherm.

                      print('Getikt op $bankNaam. Navigeer naar transactiedetails...');
                      // Voorbeeld (vereist dat SpaargeldScherm ook onDelete en onEdit ontvangt):
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => JouwNieuweTransactieLijstVoorBankScherm(
                      //       bankNaam: bankNaam,
                      //       alleTransacties: transacties, // Globale lijst uit main.dart
                      //       onDeleteTransactie: widget.onDeleteTransactie,
                      //       onEditTransactie: widget.onEditTransactie,
                      //     ),
                      //   ),
                      // );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'spaargeld_scherm_fab', // Unieke tag voor dit scherm
        onPressed: () async {
          final result = await Navigator.push<Transactie>(
            context,
            MaterialPageRoute(
              builder: (_) => VoegSpaarTransactieToeScherm(),
            ),
          );

          if (result != null && mounted) { // Controleer 'mounted' voor veiligheid
            setState(() {
              // De globale 'spaarsaldi' map in main.dart is leidend en wordt
              // bijgewerkt door de logica in VoegSpaarTransactieToeScherm of de
              // transactieverwerking in main.dart.
              // De 'widget.onSpaargeldChanged' zorgt voor het opslaan.
              // Een setState() hier zorgt ervoor dat de UI van dit scherm
              // herbouwt met de (potentieel) bijgewerkte globale 'spaarsaldi'.

              if (widget.onSpaargeldChanged != null) {
                widget.onSpaargeldChanged!();
              }
              // De setState() zelf is voldoende om de lijst te vernieuwen,
              // omdat de ListView.builder de (bijgewerkte) globale 'spaarsaldi' zal lezen.
            });
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Sparen'), // Tekst toegevoegd
        tooltip: 'Voeg geld toe aan spaarpot',
      ),
    );
  }
}