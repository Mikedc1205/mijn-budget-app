import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

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
                  label: const Text('IN'),
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
                  label: const Text('UIT'),
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