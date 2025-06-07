import 'package:flutter/material.dart';
import '../main.dart'; // Voor toegang tot model en transacties!
import 'transaction_list_scherm.dart';
import 'voeg_transactie_toe_scherm.dart';

class BudgetScherm extends StatefulWidget {

  // Callback zodra transacties of spaarsaldi veranderen:
  final Future<void> Function()? onTransactieChanged;

  const BudgetScherm({Key? key, this.onTransactieChanged}) : super(key: key);

  @override
  State<BudgetScherm> createState() => _BudgetSchermState();
}

class _BudgetSchermState extends State<BudgetScherm> {
  DateTime huidigeDatum = DateTime.now();
  String modus = 'week'; // 'week', 'maand' of 'jaar'

  @override
  void initState() {
    super.initState();
    // Bij openen zetten we de huidigeDatum op de maandag van deze week
    huidigeDatum = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
  }

  DateTime getPeriodeStart() {
    if (modus == 'week') {
      return huidigeDatum;
    } else if (modus == 'maand') {
      return DateTime(huidigeDatum.year, huidigeDatum.month, 1);
    } else {
      return DateTime(huidigeDatum.year, 1, 1);
    }
  }

  DateTime getPeriodeEind() {
    if (modus == 'week') {
      return getPeriodeStart().add(const Duration(days: 6));
    } else if (modus == 'maand') {
      final volgendeMaand =
      DateTime(huidigeDatum.year, huidigeDatum.month + 1, 1);
      return volgendeMaand.subtract(const Duration(days: 1));
    } else {
      return DateTime(huidigeDatum.year, 12, 31);
    }
  }

  String getPeriodeTekst() {
    final start = getPeriodeStart();
    final eind = getPeriodeEind();
    if (modus == 'week') {
      return '${start.day} ${maandNamen[start.month - 1]} – '
          '${eind.day} ${maandNamen[eind.month - 1]} ${eind.year}';
    } else if (modus == 'maand') {
      return '${maandNamen[huidigeDatum.month - 1]} ${huidigeDatum.year}';
    } else {
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
          totaalUitgaven += t.bedrag;
        }
      }
    }
    return totaalInkomen - totaalUitgaven;
  }

  @override
  Widget build(BuildContext context) {
    final saldo = berekenSaldo();
    final isPositief = saldo >= 0;

    Widget saldoKop() {
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

    Widget periodeSelector() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_left),
              onPressed: () {
                setState(() {
                  if (modus == 'week') {
                    huidigeDatum = huidigeDatum.subtract(const Duration(days: 7));
                  } else if (modus == 'maand') {
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

            // Maak de periode‐tekst flexibel, zodat hij niet uit het scherm stroomt
            Expanded(
              child: Text(
                getPeriodeTekst(),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            IconButton(
              icon: const Icon(Icons.arrow_right),
              onPressed: () {
                setState(() {
                  if (modus == 'week') {
                    huidigeDatum = huidigeDatum.add(const Duration(days: 7));
                  } else if (modus == 'maand') {
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

            const SizedBox(width: 8),

            // Zorg dat ToggleButtons verkleint als het te breed wordt
            Flexible(
              child: ToggleButtons(
                isSelected: [
                  modus == 'week',
                  modus == 'maand',
                  modus == 'jaar',
                ],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) {
                      modus = 'week';
                      huidigeDatum = DateTime.now()
                          .subtract(Duration(days: DateTime.now().weekday - 1));
                    }
                    if (index == 1) {
                      modus = 'maand';
                      huidigeDatum = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        1,
                      );
                    }
                    if (index == 2) {
                      modus = 'jaar';
                      huidigeDatum = DateTime(DateTime.now().year, 1, 1);
                    }
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Week'),
                  ),
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
          ],
        ),
      );
    }


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
          Text(
            getPeriodeTekst(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ToggleButtons(
                isSelected: [
                  modus == 'week',
                  modus == 'maand',
                  modus == 'jaar',
                ],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) {
                      modus = 'week';
                      huidigeDatum = DateTime.now()
                          .subtract(Duration(days: DateTime.now().weekday - 1));
                    }
                    if (index == 1) {
                      modus = 'maand';
                      huidigeDatum = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        1,
                      );
                    }
                    if (index == 2) {
                      modus = 'jaar';
                      huidigeDatum = DateTime(DateTime.now().year, 1, 1);
                    }
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Week'),
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Transactie>(
            context,
            MaterialPageRoute(
              builder: (_) => const VoegTransactieToeScherm(),
            ),
          );
          if (result != null) {
            setState(() {
              transacties.add(result);

              if (result.type == 'spaar') {
                spaarsaldi[result.bank] =
                    (spaarsaldi[result.bank] ?? 0) + result.bedrag;
              } else if (result.type == 'uitgave' && result.uitSpaarpot) {
                spaarsaldi[result.bank] =
                    (spaarsaldi[result.bank] ?? 0) - result.bedrag;
              }
            });
            if (widget.onTransactieChanged != null) {
              await widget.onTransactieChanged!();
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );

  }

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
}
