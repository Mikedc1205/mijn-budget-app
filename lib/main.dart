import 'dart:convert';
import 'screens/budget_scherm.dart';
import 'screens/spaargeld_scherm.dart'; // Importeer het bijgewerkte SpaargeldScherm
import 'screens/opties_scherm.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  // Zorg dat SharedPreferences eerst klaar is voordat de app start
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MijnBudgetApp());
}
var _uuid = Uuid();

// ------------ BEGIN Modelklassen ------------

class Transactie {
  String id; // <-- VOEG DIT VELD TOE
  DateTime datum;
  double bedrag;
  String type; // 'inkomen', 'uitgave' of 'spaar'
  String categorie;
  String bank; // 'KBC', 'Keytrade', 'Belfius', 'Cash'
  String omschrijving;
  String herhaling; // 'Geen', 'Wekelijks', 'Maandelijks', 'Jaarlijks'
  bool uitSpaarpot;

  Transactie({
    String? id, // Optioneel: als je een bestaande ID wilt meegeven
    required this.datum,
    required this.bedrag,
    required this.type,
    required this.categorie,
    required this.bank,
    required this.omschrijving,
    required this.herhaling,
    this.uitSpaarpot = false,
  }): this.id = id ?? _uuid.v4(); // Genereer een nieuwe unieke ID als er geen wordt meegegeven


  // Omzetten naar een Map (voor JSON opslag) - Nu 'toJson()' genoemd
  Map<String, dynamic> toJson() {
    return {
      'id': id, // <-- Neem 'id' op
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

  // Factory om vanuit een Map (parsed uit JSON) weer een Transactie te maken - Nu 'fromJson()' genoemd
  factory Transactie.fromJson(Map<String, dynamic> json) {
    return Transactie(
      datum: DateTime.parse(json['datum'] as String),
      bedrag: (json['bedrag'] as num).toDouble(),
      type: json['type'] as String,
      categorie: json['categorie'] as String,
      bank: json['bank'] as String,
      omschrijving: json['omschrijving'] as String,
      herhaling: json['herhaling'] as String,
      uitSpaarpot: json['uitSpaarpot'] as bool,
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
  late Future<void> _initialLoad;

  @override
  void initState() {
    super.initState();
    _initialLoad = _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txJson = prefs.getString('transacties');
    if (txJson != null) {
      try {
        final List<dynamic> parsedList = jsonDecode(txJson);
        transacties = parsedList
            .map((item) => Transactie.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        transacties = [];
      }
    }
    final String? saldiJson = prefs.getString('spaarsaldi');
    if (saldiJson != null) {
      try {
        final Map<String, dynamic> parsedMap = jsonDecode(saldiJson);
        spaarsaldi =
            parsedMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } catch (_) {
        spaarsaldi = {'KBC': 0.0, 'Keytrade': 0.0, 'Belfius': 0.0, 'Cash': 0.0};
      }
    }
    // setState is nodig na het laden om de UI te vernieuwen, vooral bij herstel.
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addTransactie(Transactie transactie) async {
    setState(() { // setState hier als _MijnBudgetAppState zelf UI heeft die update
      transacties.add(transactie);
      if (transactie.type == 'spaar') {
        spaarsaldi[transactie.bank] = (spaarsaldi[transactie.bank] ?? 0) + transactie.bedrag;
        print('Spaarsaldo voor ${transactie.bank} bijgewerkt naar: ${spaarsaldi[transactie.bank]}');
      } else if (transactie.type == 'uitgave' && transactie.uitSpaarpot) {
        spaarsaldi[transactie.bank] = (spaarsaldi[transactie.bank] ?? 0) - transactie.bedrag;
      }
      // Voeg hier eventueel andere logica toe voor andere transactietypes
    });
    await _saveData(); // Belangrijk: sla de wijzigingen op!
    print('Transactie toegevoegd en data opgeslagen.');
  }
  Future<void> _deleteTransactie(Transactie transactieToDelete) async {
    setState(() {
      transacties.removeWhere((t) => t.id == transactieToDelete.id); // Verwijder op basis van ID

      // Pas ook de spaarsaldi aan als de verwijderde transactie invloed had
      if (transactieToDelete.type == 'spaar') {
        // Als een spaartransactie (storting) wordt verwijderd, moet het bedrag van het saldo af
        spaarsaldi[transactieToDelete.bank] =
            (spaarsaldi[transactieToDelete.bank] ?? 0) - transactieToDelete.bedrag;
      } else if (transactieToDelete.type == 'uitgave' && transactieToDelete.uitSpaarpot) {
        // Als een uitgave UIT een spaarpot wordt verwijderd, moet het bedrag TERUG bij het saldo
        spaarsaldi[transactieToDelete.bank] =
            (spaarsaldi[transactieToDelete.bank] ?? 0) + transactieToDelete.bedrag;
      }
      // Als het een 'inkomen' of reguliere 'uitgave' (niet uit spaarpot) was,
      // hoeft spaarsaldi niet aangepast te worden, alleen de transactielijst.
    });
    await _saveData(); // Sla de wijzigingen op
    print('Transactie met ID ${transactieToDelete.id} verwijderd en data opgeslagen.');
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mappedTx =
    transacties.map((t) => t.toJson()).toList();
    await prefs.setString('transacties', jsonEncode(mappedTx));
    await prefs.setString('spaarsaldi', jsonEncode(spaarsaldi));
  }

  @override
  Widget build(BuildContext context) {
    // Maak de lijst met schermen hier aan in plaats van als instance variable.
    // Dit lost de foutmeldingen op.
    final List<Widget> schermen = [
      BudgetScherm(
        onTransactieChanged: _saveData,
        onDeleteTransactie: _deleteTransactie,
        onAddTransactie: _addTransactie, // Zorg dat deze ook is g
      ),
      SpaargeldScherm(
        onSpaargeldChanged: _saveData,
        // Voeg hier ook de delete-functie toe als je vanuit dit scherm transacties kan verwijderen.
        onAddTransactie: _addTransactie, // <--- DEZE IS CRUCIAAL// onDeonAddTransactie: _addTransactie, // <--- DEZE IS CRUCIAALleteTransactie: _deleteTransactie,
      ),
      OptiesScherm(
        onWisAlles: () async {
          setState(() {
            transacties.clear();
            spaarsaldi.updateAll((key, value) => 0.0);
          });
          await _saveData();
        },
        onGegevensHersteld: () async {
          // _loadData() roept nu zelf setState aan om de UI te vernieuwen.
          await _loadData();
        },
      ),
    ];

    return FutureBuilder<void>(
      future: _initialLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp(
          title: 'Mijn Budget',
          locale: const Locale('nl', 'BE'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('nl', 'BE'),
          ],
          theme: ThemeData(primarySwatch: Colors.purple),
          home: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: schermen, // Gebruik de nieuwe lijst
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