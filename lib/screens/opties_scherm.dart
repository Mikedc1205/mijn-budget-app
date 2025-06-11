import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Voorwaardelijke import: dart:html wordt ALLEEN geïmporteerd als het platform WEB is.
// Anders wordt een "dummy" implementatie (stub) gebruikt.
import 'opties_scherm_html_stub.dart' if (dart.library.html) 'dart:html' as html;

import '../main.dart'; // Voor toegang tot transacties en spaarsaldi (en Transactie model)

class OptiesScherm extends StatelessWidget {
  final Future<void> Function() onWisAlles;
  final Function() onGegevensHersteld; // Nieuwe callback om UI te vernieuwen

  const OptiesScherm({Key? key, required this.onWisAlles, required this.onGegevensHersteld}) : super(key: key);

  Future<void> _maakBackup(BuildContext context) async {
    try {
      // 1. Data ophalen en voorbereiden
      final prefs = await SharedPreferences.getInstance();
      final String? transactiesJson = prefs.getString('transacties');
      final String? spaarsaldiJson = prefs.getString('spaarsaldi');

      Map<String, dynamic> backupData = {
        'transacties': transactiesJson != null ? jsonDecode(transactiesJson) : [],
        'spaarsaldi': spaarsaldiJson != null ? jsonDecode(spaarsaldiJson) : {},
        'backupDatum': DateTime.now().toIso8601String(),
      };

      String formattedDate = DateTime.now().toIso8601String().substring(0, 10);
      String fileName = 'budget_backup_$formattedDate.json';
      String jsonContent = jsonEncode(backupData);

      // Converteer JSON naar bytes voor opslag
      final bytes = utf8.encode(jsonContent);

      if (kIsWeb) {
        // --- LOGICA VOOR WEB PLATFORM (onveranderd) ---
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Back-up succesvol gedownload als "$fileName"')),
        );
      } else {
        // --- LOGICA VOOR MOBIELE/DESKTOP PLATFORMEN: GEBRUIKER KIEST MAP ---
        // BELANGRIJK: 'bytes: bytes' parameter toegevoegd hier!
        String? outputPath = await FilePicker.platform.saveFile(
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes, // <-- DEZE REGEL IS TOEGEVOEGD!
        );

        if (outputPath == null) {
          // Gebruiker heeft opslaan geannuleerd
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Back-up geannuleerd.')),
          );
          return;
        }

        // De volgende twee regels zijn nu overbodig omdat saveFile het zelf afhandelt
        // final file = File(outputPath);
        // await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Back-up succesvol opgeslagen in:\n$outputPath')),
        );
        print('Backup opgeslagen in: $outputPath');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij back-up maken: $e')),
      );
      print('Fout bij back-up maken: $e');
    }
  }

  // FUNCTIE: Herstel Back-up
  // NIEUWE FUNCTIE: Herstel Back-up
  Future<void> _herstelBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'], // We verwachten .json bestanden
        allowMultiple: false,
      );

      if (result == null) { // Alleen checken op result == null, want path of bytes kan null zijn afhankelijk van platform
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Herstel geannuleerd: Geen bestand geselecteerd.')),
        );
        return;
      }

      String contents;

      if (kIsWeb) {
        // LOGICA VOOR WEB PLATFORM
        if (result.files.single.bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Herstel geannuleerd: Bestand is leeg of kan niet gelezen worden op web.')),
          );
          return;
        }
        contents = utf8.decode(result.files.single.bytes!);
      } else {
        // LOGICA VOOR MOBIELE/DESKTOP PLATFORMEN
        final String? filePath = result.files.single.path;
        if (filePath == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Herstel geannuleerd: Ongeldig bestandspad.')),
          );
          return;
        }
        final file = File(filePath);
        contents = await file.readAsString();
      }

      // Vanaf hier is de logica weer hetzelfde voor beide platforms
      Map<String, dynamic> backupData = jsonDecode(contents);

      final prefs = await SharedPreferences.getInstance();

      // Transacties herstellen
      List<dynamic> rawTransacties = backupData['transacties'] ?? [];
      List<Transactie> hersteldeTransacties = rawTransacties.map((json) => Transactie.fromJson(json)).toList();
      await prefs.setString('transacties', jsonEncode(hersteldeTransacties.map((t) => t.toJson()).toList()));

      // Spaarsaldi herstellen
      Map<String, dynamic> hersteldeSpaarsaldi = backupData['spaarsaldi'] ?? {};
      await prefs.setString('spaarsaldi', jsonEncode(hersteldeSpaarsaldi));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gegevens succesvol hersteld!')),
      );

      // Callback om UI te vernieuwen (belangrijk!)
      onGegevensHersteld();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij herstellen van back-up: $e')),
      );
      print('Fout bij herstellen van back-up: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opties'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Maak Back-up'),
              subtitle: const Text('Sla je gegevens op naar een bestand'),
              onTap: () => _maakBackup(context),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Herstel Back-up'),
              subtitle: const Text('Laad gegevens vanaf een back-upbestand'),
              onTap: () => _herstelBackup(context), // Koppelt aan de nieuwe functie
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Wis Alle Gegevens'),
              subtitle: const Text('Verwijder alle transacties en spaarsaldi'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Gegevens wissen?'),
                      content: const Text(
                          'Weet je zeker dat je alle gegevens wilt verwijderen? Dit kan niet ongedaan gemaakt worden.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Annuleren'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await onWisAlles();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Alle gegevens zijn gewist.')),
                            );
                          },
                          child: const Text('Wis alles'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}