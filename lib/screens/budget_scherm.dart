import 'package:flutter/material.dart';
import '../main.dart'; // Voor toegang tot model en transacties!
import 'transaction_list_scherm.dart';
import 'voeg_transactie_toe_scherm.dart';

// Dit is een testcommentaarregel: aangepast door de AI.
// Zorg ervoor dat 'maandNamen' hier of in main.dart gedefinieerd is.
// Als het in main.dart staat en je hebt het import-statement correct, is het goed.
// Anders, voeg deze lijst toe:
const List<String> maandNamen = [
  'januari', 'februari', 'maart', 'april', 'mei', 'juni',
  'juli', 'augustus', 'september', 'oktober', 'november', 'december'
];


class BudgetScherm extends StatefulWidget {
  final Future<void> Function()? onTransactieChanged;
  final Future<void> Function(Transactie transactie) onDeleteTransactie; // Geen vraagteken, dus niet-nullable
  final Future<void> Function(Transactie transactie)? onAddTransactie;

  const BudgetScherm({
    Key? key,
    this.onTransactieChanged,
    required this.onDeleteTransactie, // Markeer als 'required'
    this.onAddTransactie,
  }) : super(key: key);



  @override
  State<BudgetScherm> createState() => _BudgetSchermState();
}
class _BudgetSchermState extends State<BudgetScherm> {
  DateTime huidigeDatum = DateTime.now();
  String modus = 'maand'; // 'week', 'maand' of 'jaar'

  @override
  void initState() {
    super.initState();
    // Bij openen zetten we de huidigeDatum op de maandag van deze week <-- Deze logica is nu minder relevant
    // OF pas aan naar de geselecteerde default modus
    // Voorbeeld als 'maand' de default is:
    huidigeDatum = DateTime(DateTime.now().year, DateTime.now().month, 1);

    // Als je 'jaar' als default wilt:
    // huidigeDatum = DateTime(DateTime.now().year, 1, 1);
  }

  DateTime getPeriodeStart() {
    // if (modus == 'week') { // <-- Kan weg of blijven (zal niet meer gekozen worden)
    //   return huidigeDatum;
    // } else
    if (modus == 'maand') {
      return DateTime(huidigeDatum.year, huidigeDatum.month, 1);
    } else { // 'jaar'
      return DateTime(huidigeDatum.year, 1, 1);
    }
  }

  DateTime getPeriodeEind() {
    // if (modus == 'week') { // <-- Kan weg of blijven
    //   return getPeriodeStart().add(const Duration(days: 6));
    // } else
    if (modus == 'maand') {
      final volgendeMaand =
      DateTime(huidigeDatum.year, huidigeDatum.month + 1, 1);
      return volgendeMaand.subtract(const Duration(days: 1));
    } else { // 'jaar'
      return DateTime(huidigeDatum.year, 12, 31);
    }
  }


  String getPeriodeTekst() {
    final start = getPeriodeStart();
    final eind = getPeriodeEind();
    // if (modus == 'week') { // <-- Kan weg of blijven
    //   return '${start.day} ${maandNamen[start.month - 1]} – '
    //       '${eind.day} ${maandNamen[eind.month - 1]} ${eind.year}';
    // } else
    if (modus == 'maand') {
      return '${maandNamen[huidigeDatum.month - 1]} ${huidigeDatum.year}';
    } else { // 'jaar'
      return '${huidigeDatum.year}';
    }
  }

  double berekenSaldo() {
    final start = getPeriodeStart();
    final eind = getPeriodeEind();
    double totaalInkomen = 0;
    double totaalUitgaven = 0;

    for (var t in transacties) {
      if (!t.datum.isBefore(start) && !t.datum.isAfter(eind)) {
        if (t.type == 'inkomen') {
          totaalInkomen += t.bedrag;
        } else if (t.type == 'uitgave') {
           if (!t.uitSpaarpot) { // Veronderstelt dat Transactie een 'uitS
             totaalUitgaven += t.bedrag;
           }
        }
      }
    }
    return totaalInkomen - totaalUitgaven;
  }

  // Deze functie is al correct in je oorspronkelijke code, maar ik neem 'm voor de volledigheid mee.
  Widget saldoKop() {
    final saldo = berekenSaldo();
    final isPositief = saldo >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        '€ ${saldo.toStringAsFixed(2)}',
        style: TextStyle(
          fontSize: 32,
          color: isPositief ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // saldo en isPositief worden nu gebruikt in saldoKop(), dus hier hoeven ze niet apart gedeclareerd te worden,
    // tenzij je ze ergens anders in de build methode ook direct wilt gebruiken.
    // final saldo = berekenSaldo();
    // final isPositief = saldo >= 0;

    Widget overzichtKaarten() {
      return Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: const Text('Inkomsten'),
                subtitle: Text(
                  '€ ${transacties.where((t) =>
                  t.type == 'inkomen' &&
                      !t.datum.isBefore(getPeriodeStart()) &&
                      !t.datum.isAfter(getPeriodeEind()))
                      .fold(0.0, (s, t) => s + t.bedrag)
                      .toStringAsFixed(2)}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionListScherm(
                        type: 'inkomen',
                        modus: modus,
                        start: getPeriodeStart(),
                        eind: getPeriodeEind(),
                        onDeleteTransactie: widget.onDeleteTransactie, // <-- GEEF DE CA
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Uitgaven'),
                subtitle: Text(
                  '€ ${transacties.where((t) =>
                  t.type == 'uitgave' &&
                      !t.datum.isBefore(getPeriodeStart()) &&
                      !t.datum.isAfter(getPeriodeEind()))
                      .fold(0.0, (s, t) => s + t.bedrag)
                      .toStringAsFixed(2)}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionListScherm(
                        type: 'uitgave',
                        modus: modus,
                        start: getPeriodeStart(),
                        eind: getPeriodeEind(),
                        onDeleteTransactie: widget.onDeleteTransactie, // <--- ZORG DAT DEZE RE
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Sparen'),
                subtitle: Text(
                  '€ ${transacties.where((t) =>
                  t.type == 'spaar' &&
                      !t.datum.isBefore(getPeriodeStart()) &&
                      !t.datum.isAfter(getPeriodeEind()))
                      .fold(0.0, (s, t) => s + t.bedrag)
                      .toStringAsFixed(2)}',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionListScherm(
                        type: 'spaar',
                        modus: modus,
                        start: getPeriodeStart(),
                        eind: getPeriodeEind(),

                        onDeleteTransactie: widget.onDeleteTransactie, // <--- ZORG DAT DEZE REG
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn Budget'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Mijn Budget',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // De nieuwe Row met navigatiepijlen en de periode tekst
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: () {
                  setState(() {
                    // if (modus == 'week') { // <-- Kan weg of blijven
                    //   huidigeDatum = huidigeDatum.subtract(const Duration(days: 7));
                    // } else
                    if (modus == 'maand') {
                      huidigeDatum = DateTime(
                        huidigeDatum.year,
                        huidigeDatum.month - 1,

                        1,
                      );
                    } else {
                      huidigeDatum = DateTime(huidigeDatum.year - 1, 1, 1);
                    }
                  });
                },
              ),
              Text(
                getPeriodeTekst(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: () {
                  setState(() {
                    // if (modus == 'week') { // <-- Kan weg of blijven
                    //   huidigeDatum = huidigeDatum.add(const Duration(days: 7));
                    // } else
                    if (modus == 'maand') {
                      huidigeDatum = DateTime(
                        huidigeDatum.year,
                        huidigeDatum.month + 1,

                        1,
                      );
                    } else {
                      huidigeDatum = DateTime(huidigeDatum.year + 1, 1, 1);
                    }
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8), // Ruimte tussen navigatie en ToggleButtons
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ToggleButtons(
                isSelected: [

                  modus == 'maand',
                  modus == 'jaar',
                ],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) {
                      modus = 'maand';
                      huidigeDatum = DateTime.now()
                          .subtract(Duration(days: DateTime.now().weekday - 1));
                    }
                    if (index == 0) {
                      modus = 'maand';
                      huidigeDatum = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        1,
                      );
                    }
                    if (index == 1) {
                      modus = 'jaar';
                      huidigeDatum = DateTime(DateTime.now().year, 1, 1);
                    }
                  });
                },
                children: const [

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Maand'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Jaar'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          saldoKop(),
          overzichtKaarten(),
        ],
      ),
      // In budget_scherm.dart -> _BudgetSchermState -> build()
      floatingActionButton: FloatingActionButton(
        heroTag: 'budget_scherm_fab', // Unieke tag voor dit scherm
        onPressed: () async {
          final result = await Navigator.push<Transactie>(
            context,
            MaterialPageRoute(
              builder: (_) => const VoegTransactieToeScherm(),
            ),
          );

          if (result != null && mounted) { // Voeg 'mounted' check toe voor veiligheid
            // Controleer of de onAddTransactie callback is meegegeven
            if (widget.onAddTransactie != null) {
              // Roep de centrale _addTransactie functie aan in main.dart
              await widget.onAddTransactie!(result);
            } else {
              // Fallback: Als onAddTransactie niet beschikbaar is, doe het "oude" (minder ideale) werk
              // Dit blok zou je idealiter willen verwijderen als je onAddTransactie consistent gebruikt
              print("WAARSCHUWING: onAddTransactie callback niet gebruikt in BudgetScherm. Globale lijsten direct aangepast.");
              setState(() {
                transacties.add(result); // Globale lijst
                if (result.type == 'spaar') {
                  spaarsaldi[result.bank] = (spaarsaldi[result.bank] ?? 0) + result.bedrag; // Globale map
                } else if (result.type == 'uitgave' && result.uitSpaarpot) {
                  spaarsaldi[result.bank] = (spaarsaldi[result.bank] ?? 0) - result.bedrag; // Globale map
                }
              });
              // Roep nog steeds onTransactieChanged aan om op te slaan als _addTransactie dit niet al deed
              if (widget.onTransactieChanged != null) {
                await widget.onTransactieChanged!();
              }
            }

            // Een setState hier kan nuttig zijn om de UI van BudgetScherm te vernieuwen
            // als de _addTransactie methode (of de fallback) de data heeft gewijzigd
            // en BudgetScherm die data direct toont (bijv. in een lijst of grafiek).
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}