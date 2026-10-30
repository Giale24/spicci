import 'package:web/web.dart' as web;

Future<String?> saveCsvFile(String content, String fileName) async {
  try {
    final encodedUri = 'data:text/csv;charset=utf-8,\uFEFF${Uri.encodeComponent(content)}';
    final anchor = web.HTMLAnchorElement()
      ..href = encodedUri
      ..download = fileName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    return 'Scaricato';
  } catch (e) {
    return null;
  }
}
