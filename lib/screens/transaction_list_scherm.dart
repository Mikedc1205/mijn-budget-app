import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

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
