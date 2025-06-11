// opties_scherm_html_stub.dart
// Dit bestand wordt gebruikt als dart:html NIET beschikbaar is (bijv. op mobiel of desktop).
// Het definieert "dummy" klassen zodat de code compileert.

// Dummy klasse voor Blob
class Blob {
  Blob(List<List<int>> data, [String? type]) {
    // Implementatie niet nodig voor non-web
  }
}

// Dummy klasse voor Url (bevat static methodes)
class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    // Implementatie niet nodig voor non-web
    return ''; // Retourneer een lege string
  }
  static void revokeObjectUrl(String url) {
    // Implementatie niet nodig voor non-web
  }
}

// Dummy klasse voor AnchorElement
class AnchorElement {
  String? href;
  void click() {
    // Implementatie niet nodig voor non-web
  }
  void setAttribute(String name, String value) {
    // Implementatie niet nodig voor non-web
  }
  AnchorElement({this.href});
}