import 'dart:convert';
import 'package:flutter/material.dart'; // Flutter's eigen material design widgets
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:intl/intl.dart'; // Alleen als je het nog ergens gebruikt
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Importeer je schermen
import 'screens/budget_scherm.dart';
import 'screens/spaargeld_scherm.dart';
import 'screens/opties_scherm.dart';

// Importeer de AuthWrapper
import 'auth_wrapper.dart'; // Zorg dat dit pad klopt!
import 'secure_storage_service.dart'; // Als het nog niet aanw
// --- Globale variabelen en modelklassen blijven hier (of verplaats ze naar een apart modelbestand) ---
var _uuid = Uuid();

class Transactie {
  String id;
  DateTime datum;
  double bedrag;
  String type;
  String categorie;
  String bank;
  String omschrijving;
  String herhaling;
  bool uitSpaarpot;

  Transactie({
    String? id,
    required this.datum,
    required this.bedrag,
    required this.type,
    required this.categorie,
    required this.bank,
    required this.omschrijving,
    required this.herhaling,
    this.uitSpaarpot = false,
  }) : this.id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

  factory Transactie.fromJson(Map<String, dynamic> json) {
    return Transactie(
      id: json['id'] as String? ?? _uuid.v4(), // Zorg dat 'id' ook hier wordt gelezen
      datum: DateTime.parse(json['datum'] as String),
      bedrag: (json['bedrag'] as num).toDouble(),
      type: json['type'] as String,
      categorie: json['categorie'] as String,
      bank: json['bank'] as String,
      omschrijving: json['omschrijving'] as String,
      herhaling: json['herhaling'] as String,
      uitSpaarpot: json['uitSpaarpot'] as bool? ?? false, // Voeg null check toe
    );
  }
}

List<Transactie> transacties = [];
Map<String, double> spaarsaldi = {
  'KBC': 0.0,
  'Keytrade': 0.0,
  'Belfius': 0.0,
  'Cash': 0.0,
};

final List<String> categorieen = [
  'Salaris', 'Boodschappen', 'Huur', 'Vervoer', 'Vrije Tijd', 'Zorg', 'Overig',
];

final List<String> maandNamen = [
  'jan', 'feb', 'mrt', 'apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
];
// --- Einde Globale variabelen en modelklassen ---


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Je hoeft hier niet meer _loadData() aan te roepen, dat gebeurt in MainAppScreenState
  runApp(const RootApp()); // Start met de nieuwe RootApp
}

// 1. Nieuwe Root Widget die de MaterialApp en AuthWrapper bevat
class RootApp extends StatelessWidget {
  const RootApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      // AuthWrapper wordt het startpunt
      home: const AuthWrapper(),
      // Je kunt hier routes definiëren als je die later nodig hebt
    );
  }
}


// 2. Hernoem je oorspronkelijke MijnBudgetApp naar MainAppScreen
// Dit is de widget die getoond wordt NA succesvolle authenticatie
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({Key? key}) : super(key: key);

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  late Future<void> _initialLoad; // Deze is nog steeds nuttig voor je data

  @override
  void initState() {
    super.initState();
    // Data wordt hier geladen wanneer dit scherm wordt aangemaakt
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
      } catch (e) {
        print("Fout bij laden transacties: $e");
        transacties = [];
      }
    } else {
      transacties = [];
    }

    final String? saldiJson = prefs.getString('spaarsaldi');
    if (saldiJson != null) {
      try {
        final Map<String, dynamic> parsedMap = jsonDecode(saldiJson);
        spaarsaldi =
            parsedMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } catch (e) {
        print("Fout bij laden spaarsaldi: $e");
        spaarsaldi = {'KBC': 0.0, 'Keytrade': 0.0, 'Belfius': 0.0, 'Cash': 0.0};
      }
    } else {
      spaarsaldi = {'KBC': 0.0, 'Keytrade': 0.0, 'Belfius': 0.0, 'Cash': 0.0};
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> mappedTx =
    transacties.map((t) => t.toJson()).toList();
    await prefs.setString('transacties', jsonEncode(mappedTx));
    await prefs.setString('spaarsaldi', jsonEncode(spaarsaldi));
    print("Data opgeslagen via _saveData in _MainAppScreenState");
  }

  Future<void> _addTransactie(Transactie transactie) async {
    setState(() {
      transacties.add(transactie);
      if (transactie.type == 'spaar') {
        spaarsaldi[transactie.bank] = (spaarsaldi[transactie.bank] ?? 0) + transactie.bedrag;
        print("DEBUG [main.dart _addTransactie]: Spaarsaldi voor ${transactie.bank} is nu ${spaarsaldi[transactie.bank]}. Hele map: $spaarsaldi");

    } else if (transactie.type == 'uitgave' && transactie.uitSpaarpot) {
        spaarsaldi[transactie.bank] = (spaarsaldi[transactie.bank] ?? 0) - transactie.bedrag;
      }
    });
    await _saveData();
  }

  Future<void> _deleteTransactie(Transactie transactieToDelete) async {
    setState(() {
      transacties.removeWhere((t) => t.id == transactieToDelete.id);
      if (transactieToDelete.type == 'spaar') {
        spaarsaldi[transactieToDelete.bank] =
            (spaarsaldi[transactieToDelete.bank] ?? 0) - transactieToDelete.bedrag;
      } else if (transactieToDelete.type == 'uitgave' && transactieToDelete.uitSpaarpot) {
        spaarsaldi[transactieToDelete.bank] =
            (spaarsaldi[transactieToDelete.bank] ?? 0) + transactieToDelete.bedrag;
      }
    });
    await _saveData();
    print("Transactie verwijderd en data opgeslagen via _deleteTransactie");

  }

  // Functie om de pincode te resetten en terug te navigeren naar AuthWrapper
  // Deze kan je aanroepen vanuit OptiesScherm bijvoorbeeld
  // Functie om de pincode te resetten en terug te navigeren naar AuthWrapper
  Future<void> _resetPinAndLogout(BuildContext context) async {
    // Vraag eerst om bevestiging
    final confirmReset = await showDialog<bool>(
      context: context, // Gebruik de context die aan _resetPinAndLogout wordt meegegeven
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pincode opnieuw instellen?'),
          content: const Text(
              'Weet u zeker dat u uw huidige pincode wilt verwijderen en een nieuwe wilt instellen? U wordt hiervoor uitgelogd.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ja, opnieuw instellen'),
            ),
          ],
        );
      },
    );

    // Alleen doorgaan als de gebruiker heeft bevestigd
    if (confirmReset == true) {
      final storageService = SecureStorageService();
      await storageService.deletePin();

      if (mounted) { // Controleer of de widget nog in de tree is
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
              (Route<dynamic> route) => false, // Verwijder alle voorgaande routes
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> schermen = [
      BudgetScherm(
        onTransactieChanged: _saveData, // saveData wordt nu lokaal aangeroepen
        onDeleteTransactie: _deleteTransactie,
        onAddTransactie: _addTransactie,

      ),
      SpaargeldScherm(
        onSpaargeldChanged: _saveData,
        onAddTransactie: _addTransactie,
        onDeleteTransactie: _deleteTransactie, // <<<
      ),
      OptiesScherm(
        onWisAlles: () async {
          // Vraag om bevestiging voordat alles gewist wordt
          final confirmWisAlles = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Alle gegevens wissen?'),
                content: const Text(
                    'Weet u zeker dat u alle transacties en spaarsaldi wilt verwijderen? Dit kan niet ongedaan worden gemaakt.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annuleren'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Ja, alles wissen'),
                  ),
                ],
              );
            },
          );

          if (confirmWisAlles == true) {
            setState(() {
              transacties.clear();
              spaarsaldi.updateAll((key, value) => 0.0);
            });
            await _saveData(); // Sla de lege lijsten op
          }
        },
        onGegevensHersteld: () async {
          // Toon een bevestigingsdialoog
          final confirmHerstel = await showDialog<bool>(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Gegevens herstellen?'),
                content: const Text(
                    'Weet u zeker dat u de gegevens wilt herstellen naar de laatst opgeslagen versie? Eventuele niet-opgeslagen wijzigingen gaan verloren.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Annuleren'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Ja, herstellen'),
                  ),
                ],
              );
            },
          );
          if (confirmHerstel == true) {
            await _loadData(); // Herlaad de data
          }
        },
        // Voeg een callback toe voor het resetten van de PIN
    onResetPin: () => _resetPinAndLogout(context),


      ),
    ];

    // Je FutureBuilder kan blijven, maar het bouwt nu de Scaffold met de tabs
    return FutureBuilder<void>(
      future: _initialLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Toon een laadindicator BINNEN de MainAppScreen,
          // de MaterialApp zelf wordt al getoond.
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Als data geladen is, toon de daadwerkelijke app UI
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: schermen,
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
        );
      },
    );
  }
}

// BELANGRIJK: Je moet SecureStorageService importeren in dit bestand als je _resetPinAndLogout gebruikt
// import 'secure_storage_service.dart'; // Voeg dit bovenaan toe als het nog niet is gebeurd

// Je zult ook je OptiesScherm moeten aanpassen om de onResetPin callback te accepteren
// Voorbeeld aanpassing in opties_scherm.dart (alleen relevante deel):
/*
class OptiesScherm extends StatelessWidget {
  final VoidCallback onWisAlles;
  final VoidCallback onGegevensHersteld;
  final VoidCallback onResetPin; // NIEUW

  const OptiesScherm({
    Key? key,
    required this.onWisAlles,
    required this.onGegevensHersteld,
    required this.onResetPin, // NIEUW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opties')),
      body: ListView(
        children: [
          // ... andere ListTiles ...
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Pincode opnieuw instellen'),
            subtitle: const Text('Verwijder huidige pincode en stel een nieuwe in'),
            onTap: onResetPin, // Gebruik de callback
          ),
        ],
      ),
    );
  }
}
*/