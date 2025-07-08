import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Zorg ervoor dat Transactie hier gedefinieerd is (of importeer het direct)

class TransactionListScherm extends StatefulWidget {
  final String type;
  final String modus;
  final DateTime start;
  final DateTime eind;
  final void Function(Transactie) onDeleteTransactie;
  final String? bankNaam; // <--- NIEUW

  const TransactionListScherm({
    Key? key,
    required this.type,
    required this.modus,
    required this.start,
    required this.eind,
    required this.onDeleteTransactie,
    this.bankNaam, // <--- NIEUW
  }) : super(key: key);

  @override
  State<TransactionListScherm> createState() => _TransactionListSchermState();
}

// ... de rest van de _TransactionListSchermState class blijft hieronder


class _TransactionListSchermState extends State<TransactionListScherm> { // Maak een State class
  late List<Transactie> gefilterdeTransacties; // Maak dit een state variabele

  @override
  void initState() {
    super.initState();
    _filterTransacties(); // Filter de transacties bij initialisatie
  }

  void _filterTransacties() {
    gefilterdeTransacties = transacties.where((t) {
      // Start met basis type en datum matching
      bool typeMatch = t.type == widget.type;
      bool datumMatch = !t.datum.isBefore(widget.start) && !t.datum.isAfter(widget.eind);

      // Standaard bankMatch op true. Wordt alleen false als bankNaam is opgegeven en niet matcht.
      bool bankMatch = true;
      if (widget.bankNaam != null && widget.bankNaam!.isNotEmpty) { // Controleer ook op isNotEmpty
        bankMatch = t.bank == widget.bankNaam;
      }

      return typeMatch && datumMatch && bankMatch;
    }).toList();

    // Optioneel: Sorteer de transacties, bijvoorbeeld op datum (nieuwste eerst)
    gefilterdeTransacties.sort((a, b) => b.datum.compareTo(a.datum));
  }

  void _handleDelete(Transactie transactie) {
    // Roep eerst de callback aan die de transactie uit de globale lijst verwijdert
    // en de state in de parent widget (BudgetScherm/main.dart) bijwerkt.
    widget.onDeleteTransactie(transactie);

    // Update vervolgens de lokale lijst in DIT scherm om de UI direct te verversen.
    setState(() {
      // De transactie is al uit de globale 'transacties' lijst verwijderd
      // door de widget.onDeleteTransactie call.
      // We moeten nu de lokale 'gefilterdeTransacties' opnieuw filteren of
      // de specifieke transactie eruit verwijderen. Opnieuw filteren is veiliger.
      _filterTransacties();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${transactie.omschrijving.isNotEmpty ? transactie.omschrijving : transactie.categorie} verwijderd'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Als gefilterdeTransacties leeg is, toon een melding
    if (gefilterdeTransacties.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.type == 'inkomen'
              ? 'Inkomsten'
              : widget.type == 'uitgave'
              ? 'Uitgaven'
              : 'Sparen'),
        ),
        body: const Center(
          child: Text('Geen transacties gevonden voor deze periode.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'inkomen'
            ? 'Inkomsten'
            : widget.type == 'uitgave'
            ? 'Uitgaven'
            : 'Sparen'),
      ),
      body: ListView.builder(
        itemCount: gefilterdeTransacties.length, // Gebruik de state variabele
        itemBuilder: (context, index) {
          final t = gefilterdeTransacties[index]; // Gebruik de state variabele
          return Dismissible(
            key: Key(t.id.toString()), // BELANGRIJK: Zorg dat je Transactie class een unieke 'id' heeft
            // Als je geen 'id' hebt, gebruik dan ValueKey(t) of ObjectKey(t)
            // maar een unieke ID (string of int) is beter.
            background: Container(
              color: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart, // Swipe van rechts naar links
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Bevestig verwijdering"),
                    content: Text("Weet u zeker dat u '${t.omschrijving.isNotEmpty ? t.omschrijving : t.categorie}' wilt verwijderen?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("ANNULEREN"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("VERWIJDEREN"),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              _handleDelete(t);
            },
            child: ListTile(
              title: Text('€ ${t.bedrag.toStringAsFixed(2)}'),
              subtitle: Text(
                  '${DateFormat('dd MMM yyyy', 'nl_NL').format(t.datum)} • ${t.categorie} • ${t.bank}'), // Gebruik 'nl_NL' voor Nederlandse locale
              trailing: Icon( // Gebruik een Icon voor betere visuele indicatie
                widget.type == 'uitgave' ? Icons.remove_circle_outline : Icons.add_circle_outline,
                color: widget.type == 'uitgave' ? Colors.red : Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }
}