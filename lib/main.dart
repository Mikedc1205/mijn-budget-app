import 'dart:convert';
import 'screens/budget_scherm.dart';
import 'screens/spaargeld_scherm.dart'; // Importeer het bijgewerkte SpaargeldScherm
import 'screens/opties_scherm.dart';

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
  String bank; // 'KBC', 'Keytrade', 'Belfius', 'Cash'
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

  // Veranderd: SpaargeldScherm is nu geen const meer in deze lijst
  final List<Widget> _schermen = [
    const BudgetScherm(),
    SpaargeldScherm(), // GEEN 'const' meer hier
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
                  // SpaargeldScherm krijgt nu de _saveData callback mee
                  return SpaargeldScherm(
                    onSpaargeldChanged: _saveData,
                  );
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