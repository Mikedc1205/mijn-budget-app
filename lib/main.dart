import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  // Zorg dat SharedPreferences eerst klaar is voordat de app start
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MijnBudgetApp());
}

// ------------ BEGIN Modelklassen ------------

class Transactie {
  DateTime datum;
  double bedrag;
  String type; // 'inkomen', 'uitgave' of 'spaar'
  String categorie;
  String bank; // 'KBC', 'Keytrade', 'Belfius'
  String omschrijving;
  String herhaling; // 'Geen', 'Wekelijks', 'Maandelijks', 'Jaarlijks'
  bool uitSpaarpot;

  Transactie({
    required this.datum,
    required this.bedrag,
    required this.type,
    required this.categorie,
    required this.bank,
    required this.omschrijving,
    required this.herhaling,
    this.uitSpaarpot = false,
  });

  // Omzetten naar een Map zodat we hem in JSON kunnen opslaan
  Map<String, dynamic> toMap() {
    return {
      'datum': datum.toIso8601String(),
      'bedrag': bedrag,
      'type': type,
      'categorie': categorie,
      'bank': bank,
      'omschrijving': omschrijving,
      'herhaling': herhaling,
      'uitSpaarpot': uitSpaarpot,
    };
  }

  // Factory om vanuit een Map (parsed uit JSON) weer een Transactie te maken
  factory Transactie.fromMap(Map<String, dynamic> map) {
    return Transactie(
      datum: DateTime.parse(map['datum'] as String),
      bedrag: (map['bedrag'] as num).toDouble(),
      type: map['type'] as String,
      categorie: map['categorie'] as String,
      bank: map['bank'] as String,
      omschrijving: map['omschrijving'] as String,
      herhaling: map['herhaling'] as String,
      uitSpaarpot: map['uitSpaarpot'] as bool,
    );
  }
}

// Globale in‐memory lijsten en maps, die we met SharedPreferences vullen
List<Transactie> transacties = [];
Map<String, double> spaarsaldi = {
  'KBC': 0.0,
  'Keytrade': 0.0,
  'Belfius': 0.0,
  'Cash': 0.0,
};

// Vooraf gedefinieerde categorieën (uitbreidbaar)
final List<String> categorieen = [
  'Salaris',
  'Boodschappen',
  'Huur',
  'Vervoer',
  'Vrije Tijd',
  'Zorg',
  'Overig',
];

// NL-maandnamen (afkorting)
final List<String> maandNamen = [
  'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
  'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
];
// ------------ EINDE Modelklassen ------------

class MijnBudgetApp extends StatefulWidget {
  const MijnBudgetApp({Key? key}) : super(key: key);

  @override
  State<MijnBudgetApp> createState() => _MijnBudgetAppState();
}

class _MijnBudgetAppState extends State<MijnBudgetApp> {
  int _currentIndex = 0;
  late Future<void> _initialLoad; // om in initState te laden

  final List<Widget> _schermen = [
    const BudgetScherm(),
    const SpaargeldScherm(),
    const OptiesScherm(),
  ];

  @override
  void initState() {
    super.initState();
    // Start meteen het laden van opgeslagen data
    _initialLoad = _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Transacties inladen
    final String? txJson = prefs.getString('transacties');
    if (txJson != null) {
      try {
        final List<dynamic> parsedList = jsonDecode(txJson);
        transacties = parsedList
            .map((item) => Transactie.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        transacties = [];
      }
    }

    // 2) Spaarsaldi inladen
    final String? saldiJson = prefs.getString('spaarsaldi');
    if (saldiJson != null) {
      try {
        final Map<String, dynamic> parsedMap = jsonDecode(saldiJson);
        spaarsaldi = parsedMap.map((key, value) =>
            MapEntry(key, (value as num).toDouble()));
      } catch (_) {
        spaarsaldi = {
          'KBC': 0.0,
          'Keytrade': 0.0,
          'Belfius': 0.0,
          'Cash': 0.0,
        };
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Transacties opslaan
    final List<Map<String, dynamic>> mappedTx =
    transacties.map((t) => t.toMap()).toList();
    prefs.setString('transacties', jsonEncode(mappedTx));

    // 2) Spaarsaldi opslaan
    prefs.setString('spaarsaldi', jsonEncode(spaarsaldi));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialLoad,
      builder: (context, snapshot) {
        // zolang hij aan het laden is, laat je een simpel loading‐indicator zien
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        // Zodra data geladen is, tonen we de app
        return MaterialApp(
          title: 'Mijn Budget',
          // Zet de app‐wide locale op Nederlands (België)
          locale: const Locale('nl', 'BE'),
          // Voeg localization‐delegates toe zodat Flutter de NL‐teksten gebruikt
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Geef aan welke locales je ondersteunt
          supportedLocales: const [
            Locale('nl', 'BE'),
          ],
          theme: ThemeData(primarySwatch: Colors.purple),
          home: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _schermen.map((w) {
                // We willen dat de sub‐schermen toegang hebben
                // tot onze save/ load‐functies: daarom geven we
                // een callback mee via InheritedWidget‐principe.
                if (w is BudgetScherm) {
                  return BudgetScherm(
                    onTransactieChanged: _saveData,
                  );
                } else if (w is SpaargeldScherm) {
                  return const SpaargeldScherm();
                } else if (w is OptiesScherm) {
                  return OptiesScherm(
                    onWisAlles: () async {
                      // eerst de globale data legen
                      transacties.clear();
                      spaarsaldi.updateAll((key, value) => 0.0);
                      // dan opslaan
                      await _saveData();
                    },
                  );
                }
                return w;
              }).toList(),
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() {
                _currentIndex = index;
              }),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Budget',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.savings),
                  label: 'Sparen',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Opties',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------ BudgetScherm ------------

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
        children: [
          saldoKop(),
          periodeSelector(),
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
              // Voeg toe aan in‐memory lijst
              transacties.add(result);

              // Pas spaarsaldi aan indien nodig
              if (result.type == 'spaar') {
                spaarsaldi[result.bank] =
                    (spaarsaldi[result.bank] ?? 0) + result.bedrag;
              } else if (result.type == 'uitgave' && result.uitSpaarpot) {
                spaarsaldi[result.bank] =
                    (spaarsaldi[result.bank] ?? 0) - result.bedrag;
              }
            });
            // Sla meteen alles op
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

// ------------ TransactionListScherm ------------

class TransactionListScherm extends StatelessWidget {
  final String type;
  final String modus;
  final DateTime start;
  final DateTime eind;

  const TransactionListScherm({
    Key? key,
    required this.type,
    required this.modus,
    required this.start,
    required this.eind,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gefilterde = transacties.where((t) {
      return t.type == type &&
          !t.datum.isBefore(start) &&
          !t.datum.isAfter(eind);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'inkomen'
            ? 'Inkomsten'
            : type == 'uitgave'
            ? 'Uitgaven'
            : 'Sparen'),
      ),
      body: ListView.builder(
        itemCount: gefilterde.length,
        itemBuilder: (context, index) {
          final t = gefilterde[index];
          return ListTile(
            title: Text('€ ${t.bedrag.toStringAsFixed(2)}'),
            subtitle: Text(
                '${DateFormat('dd MMM yyyy', 'nl').format(t.datum)} • ${t.categorie} • ${t.bank}'),
            trailing: Text(
              type == 'uitgave' ? '-' : '+',
              style: TextStyle(
                color: type == 'uitgave' ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ------------ VoegTransactieToeScherm ------------

class VoegTransactieToeScherm extends StatefulWidget {
  const VoegTransactieToeScherm({Key? key}) : super(key: key);

  @override
  State<VoegTransactieToeScherm> createState() =>
      _VoegTransactieToeSchermState();
}

class _VoegTransactieToeSchermState extends State<VoegTransactieToeScherm> {
  String geselecteerdType = 'inkomen';
  final TextEditingController _bedragController = TextEditingController();
  String geselecteerdeCategorie = categorieen.first;
  bool uitSpaarpot = false;
  final TextEditingController _omschrijvingController =
  TextEditingController();
  DateTime gekozenDatum = DateTime.now();
  String gekozenHerhaling = 'Geen';
  String geselecteerdeBank = 'KBC';

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? gekozen = await showDatePicker(
      context: context,
      initialDate: gekozenDatum,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('nl', 'BE'),
    );
    if (gekozen != null) {
      setState(() {
        gekozenDatum = gekozen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuw item toevoegen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Inkomen'),
                  selected: geselecteerdType == 'inkomen',
                  onSelected: (_) {
                    setState(() {
                      geselecteerdType = 'inkomen';
                      uitSpaarpot = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Uitgave'),
                  selected: geselecteerdType == 'uitgave',
                  onSelected: (_) {
                    setState(() {
                      geselecteerdType = 'uitgave';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Sparen'),
                  selected: geselecteerdType == 'spaar',
                  onSelected: (_) {
                    setState(() {
                      geselecteerdType = 'spaar';
                      uitSpaarpot = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bedragController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '€ ',
                border: OutlineInputBorder(),
                labelText: 'Bedrag',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: geselecteerdeCategorie,
              items: categorieen
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (nieuwe) {
                if (nieuwe != null) {
                  setState(() {
                    geselecteerdeCategorie = nieuwe;
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Categorie',
              ),
            ),
            const SizedBox(height: 16),
            if (geselecteerdType == 'uitgave')
              SwitchListTile(
                title: const Text('Uit spaarpot halen?'),
                value: uitSpaarpot,
                onChanged: (val) {
                  setState(() {
                    uitSpaarpot = val;
                  });
                },
              ),
            if (geselecteerdType == 'uitgave') const SizedBox(height: 16),
            TextField(
              controller: _omschrijvingController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Omschrijving',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Datum'),
              subtitle: Text(
                DateFormat('dd MMM yyyy', 'nl').format(gekozenDatum),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: gekozenHerhaling,
              items: ['Geen', 'Wekelijks', 'Maandelijks', 'Jaarlijks']
                  .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                  .toList(),
              onChanged: (nieuw) {
                if (nieuw != null) {
                  setState(() {
                    gekozenHerhaling = nieuw;
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Herhaling',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: geselecteerdeBank,
              items: ['KBC', 'Keytrade', 'Belfius']
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (nieuw) {
                if (nieuw != null) {
                  setState(() {
                    geselecteerdeBank = nieuw;
                  });
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Bank',
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    final bedrag =
                        double.tryParse(_bedragController.text) ?? 0.0;
                    final nieuweTransactie = Transactie(
                      datum: gekozenDatum,
                      bedrag: bedrag,
                      type: geselecteerdType,
                      categorie: geselecteerdeCategorie,
                      bank: geselecteerdeBank,
                      omschrijving: _omschrijvingController.text,
                      herhaling: gekozenHerhaling,
                      uitSpaarpot: uitSpaarpot,
                    );
                    Navigator.pop(context, nieuweTransactie);
                  },
                  child: const Text('OPSLAAN'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('ANNULEREN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------ SpaargeldScherm ------------

class SpaargeldScherm extends StatelessWidget {
  const SpaargeldScherm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget spaarkaart(String naam, double saldo, Color kleur) {
      return Card(
        color: kleur.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: Icon(
            Icons.account_balance,
            color: kleur,
            size: 32,
          ),
          title: Text(
            naam,
            style: TextStyle(
              fontSize: 18,
              color: kleur,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Text(
            '€ ${saldo.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              color: kleur,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaargeld'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          spaarkaart('KBC', spaarsaldi['KBC']!, Colors.blue),
          spaarkaart('Keytrade', spaarsaldi['Keytrade']!, Colors.purple),
          spaarkaart('Belfius', spaarsaldi['Belfius']!, Colors.red),
          spaarkaart('Cash', spaarsaldi['Cash']!, Colors.grey),
        ],
      ),
    );
  }
}

// ------------ OptiesScherm ------------

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
