import 'package:flutter/material.dart';
import '../main.dart'; // zodat spaarsaldi beschikbaar is

class SpaargeldScherm extends StatefulWidget {
  const SpaargeldScherm({Key? key}) : super(key: key);

  @override
  State<SpaargeldScherm> createState() => _SpaargeldSchermState();
}

class _SpaargeldSchermState extends State<SpaargeldScherm> {
  // De widget voor één spaarkaart
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '€ ${saldo.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                color: kleur,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Wijzig saldo',
              onPressed: () async {
                final controller = TextEditingController(text: saldo.toStringAsFixed(2));
                final result = await showDialog<double>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Wijzig saldo voor $naam'),
                    content: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Nieuw saldo (€)'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(), // Annuleren
                        child: const Text('Annuleren'),
                      ),
                      TextButton(
                        onPressed: () {
                          final value = double.tryParse(controller.text.replaceAll(',', '.'));
                          Navigator.of(context).pop(value);
                        },
                        child: const Text('Opslaan'),
                      ),
                    ],
                  ),
                );
                if (result != null) {
                  setState(() {
                    spaarsaldi[naam] = result;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaargeld'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          spaarkaart('KBC', spaarsaldi['KBC'] ?? 0.0, Colors.blue),
          spaarkaart('Keytrade', spaarsaldi['Keytrade'] ?? 0.0, Colors.purple),
          spaarkaart('Belfius', spaarsaldi['Belfius'] ?? 0.0, Colors.red),
          spaarkaart('Cash', spaarsaldi['Cash'] ?? 0.0, Colors.grey),
        ],
      ),
    );
  }
}
