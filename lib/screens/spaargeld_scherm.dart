import 'package:flutter/material.dart';
import '../main.dart'; // Voor toegang tot de globale 'spaarsaldi' map en Transactie model
import '../screens/voeg_spaar_transactie_toe_scherm.dart'; // Importeer het scherm voor spaartransacties
import '../screens/transaction_list_scherm.dart'; // <<<--- VOEG DEZE IMPORT TOE

class SpaargeldScherm extends StatefulWidget {
  final Future<void> Function()? onSpaargeldChanged;
  final Future<void> Function(Transactie transactie)? onAddTransactie;
  final void Function(Transactie) onDeleteTransactie; // <<<--- NIEUWE CALLBACK

  const SpaargeldScherm({
    Key? key,
    this.onSpaargeldChanged,
    required this.onAddTransactie,
    required this.onDeleteTransactie, // <<<--- VOEG TOE AAN CONSTRUCTOR
  }) : super(key: key);

  @override
  State<SpaargeldScherm> createState() => _SpaargeldSchermState();
}

// ... rest van de code ...



class _SpaargeldSchermState extends State<SpaargeldScherm> {
  @override
  Widget build(BuildContext context) {
    print("[SpaargeldScherm BUILD] Globale spaarsaldi: $spaarsaldi"); // <--- VOEG DEZE PRINT TOE
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
                      print('Getikt op $bankNaam. Navigeert nu naar TransactionListScherm...');

                      final DateTime beginDatumHeelVroeg = DateTime(2000, 1, 1);
                      final DateTime eindDatumHeelLaat = DateTime(2100, 12, 31);
                      final String transactieTypeFilter = 'spaar';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionListScherm(
                            type: transactieTypeFilter,
                            modus: 'bank_overzicht',
                            start: beginDatumHeelVroeg,
                            eind: eindDatumHeelLaat,
                            bankNaam: bankNaam, // Dit gebruikt de 'bankNaam' van de huidige ListTile
                            onDeleteTransactie: widget.onDeleteTransactie,
                          ),
                        ),
                      );
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
          print("[SpaargeldScherm] '+ Sparen' knop gedrukt. Net voor Navigator.push.");
          try {
            final result = await Navigator.push<Transactie>(
              context,
              MaterialPageRoute(
                builder: (_) => VoegSpaarTransactieToeScherm(),
              ),
            );

            print("[SpaargeldScherm] Terug van VoegSpaarTransactieToeScherm. Resultaat type: ${result?.runtimeType}, Resultaat toString: ${result?.toString()}");
            print("[SpaargeldScherm] Widget mounted status na push: $mounted");

            // In spaargeld_scherm.dart, in de onPressed:

// ... (code waar je 'result' krijgt van Navigator.push) ...

            if (mounted) {
              print("[SpaargeldScherm] Widget is mounted na terugkeer.");
              if (result != null) { // result is de nieuwe Transactie
                print("[SpaargeldScherm] Resultaat (nieuwe transactie) is NIET null. Waarde: $result");

                // --- START WIJZIGING ---
                // Roep de onAddTransactie callback aan met de nieuwe transactie.
                // Deze callback is in MainAppScreenState gekoppeld aan _addTransactie,
                // die de globale spaarsaldi correct muteert én _saveData aanroept.
                if (widget.onAddTransactie != null) {
                  print("[SpaargeldScherm] widget.onAddTransactie wordt aangeroepen met de nieuwe transactie.");
                  await widget.onAddTransactie!(result); // Geef 'result' (de Transactie) mee!
                  print("[SpaargeldScherm] widget.onAddTransactie AANGEROEPEN en voltooid.");
                } else {
                  print("[SpaargeldScherm] widget.onAddTransactie is NULL (FOUTCONFIGURATIE!).");
                }

                // Nu, nadat de globale data is bijgewerkt door onAddTransactie,
                // roep setState aan om DIT SpaargeldScherm te herbouwen.
                setState(() {
                  print("[SpaargeldScherm] setState wordt nu aangeroepen NA onAddTransactie, om UI van SpaargeldScherm te vernieuwen.");
                });
                print("[SpaargeldScherm] Na setState in SpaargeldScherm.");
                // --- EINDE WIJZIGING ---

              } else {
                print("[SpaargeldScherm] Resultaat (nieuwe transactie) is NULL na terugkeer van VoegSpaarTransactieToeScherm.");
              }
            } else {
              print("[SpaargeldScherm] Widget is NIET mounted na terugkeer. Geen UI update.");
            }
// ...


          } catch (e, s) {
            print("[SpaargeldScherm] FOUT opgetreden tijdens/na Navigator.push: $e");
            print("[SpaargeldScherm] Stacktrace: $s");
          }
          print("[SpaargeldScherm] Einde onPressed FloatingActionButton.");
        },
        icon: const Icon(Icons.add),
        label: const Text('Sparen'), // Tekst toegevoegd
        tooltip: 'Voeg geld toe aan spaarpot',
      ),
    );
  }
}