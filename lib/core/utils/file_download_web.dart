import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String?> saveCsvFile(String content, String fileName) async {
  try {
    // BOM UTF-8 (\uFEFF) per corretta interpretazione di caratteri accentati ed euro in Excel
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
    final blob = web.Blob(
      [bytes.toJS].toJS,
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
    web.URL.revokeObjectURL(url);
    return fileName;
  } catch (e) {
    return null;
  }
}
