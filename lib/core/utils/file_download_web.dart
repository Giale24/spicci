import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String?> saveCsvFile(String content, String fileName) async {
  try {
    // Includiamo BOM UTF-8 (\uFEFF) per garantire perfetta apertura in Excel
    final fullText = '\uFEFF$content';
    final blob = web.Blob(
      [fullText.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8;'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();

    // RITARDO FONDAMENTALE: Non revocare l'URL del blob immediatamente!
    // Se revocato subito, il browser interrompe lo stream di download troncando il file.
    Future.delayed(const Duration(seconds: 30), () {
      web.URL.revokeObjectURL(url);
    });

    return fileName;
  } catch (e) {
    return null;
  }
}
