import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Voor toegang tot model, transacties en categorieen!

class VoegTransactieToeScherm extends StatefulWidget {
  const VoegTransactieToeScherm({Key? key}) : super(key: key);

  @override
  State<VoegTransactieToeScherm> createState() =>
      _VoegTransactieToeSchermState();
}

class _VoegTransactieToeSchermState extends State<VoegTransactieToeScherm> {
  // Een GlobalKey om het formulier te kunnen valideren
  final _formKey = GlobalKey<FormState>();

  String geselecteerdType = 'inkomen';
  final TextEditingController _bedragController = TextEditingController();
  // Zorg dat geselecteerdeCategorie een geldige waarde heeft bij opstarten
  // Dit voorkomt een fout als categorieen leeg zou zijn, hoewel het dat hier niet is.
  String geselecteerdeCategorie = categorieen.isNotEmpty ? categorieen.first : 'Overig';
  bool uitSpaarpot = false;
  final TextEditingController _omschrijvingController =
  TextEditingController();
  DateTime gekozenDatum = DateTime.now();
  String gekozenHerhaling = 'Geen';
  // Zorg dat geselecteerdeBank een geldige waarde heeft bij opstarten
  String geselecteerdeBank = 'KBC'; // Ga ervan uit dat KBC altijd bestaat

  // Lijst van banken, deze zou je ook dynamisch kunnen maken via main.dart/shared_preferences
  final List<String> bankNamen = ['KBC', 'Keytrade', 'Belfius', 'Cash'];


  @override
  void initState() {
    super.initState();
    // Als de categorieën dynamisch zouden zijn en geselecteerdeCategorie er niet in zou zitten,
    // dan zorg je hier voor een fallback. Met de huidige setup is dat niet direct nodig.
    if (!categorieen.contains(geselecteerdeCategorie) && categorieen.isNotEmpty) {
      geselecteerdeCategorie = categorieen.first;
    }
    if (!bankNamen.contains(geselecteerdeBank) && bankNamen.isNotEmpty) {
      geselecteerdeBank = bankNamen.first;
    }
  }


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
  void dispose() {
    _bedragController.dispose();
    _omschrijvingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuw item toevoegen'),
        centerTitle: true,
      ),
      // Wikkel de SingleChildScrollView in een Form widget
      body: Form(
        key: _formKey, // Koppel de GlobalKey aan het formulier
        child: SingleChildScrollView(
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
                        uitSpaarpot = false; // Reset als type verandert
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
                        uitSpaarpot = false; // Reset als type verandert
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Gebruik TextFormField voor validatie
              TextFormField(
                controller: _bedragController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                  labelText: 'Bedrag',
                ),
                autofocus: true, // Focus direct op dit veld
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vul een bedrag in.';
                  }
                  // Vervang komma door punt voor parsing
                  final cleanedValue = value.replaceAll(',', '.');
                  final bedrag = double.tryParse(cleanedValue);
                  if (bedrag == null || bedrag <= 0) {
                    return 'Voer een geldig positief bedrag in.';
                  }
                  return null; // Geen fout
                },
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
              // Toon 'uitSpaarpot' alleen bij uitgaven
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
                  labelText: 'Omschrijving (optioneel)', // Geef aan dat het optioneel is
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Datum'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy', 'nl').format(gekozenDatum), // Volledige maandnaam
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
                items: bankNamen // Gebruik de lijst van bankNamen
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
                      // Valideer het formulier voordat je doorgaat
                      if (_formKey.currentState!.validate()) {
                        final bedrag =
                            double.tryParse(_bedragController.text.replaceAll(',', '.')) ?? 0.0; // Zorg dat komma's ook werken

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
                      }
                    },
                    child: const Text('OPSLAAN'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Gewoon teruggaan
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
      ),
    );
  }
}