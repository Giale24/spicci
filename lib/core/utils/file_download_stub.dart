import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveCsvFile(String content, String fileName) async {
  try {
    // BOM UTF-8 per compatibilità totale con Excel su Windows, Mac e mobile
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);

    // 1. Prova prima con il selettore di salvataggio nativo del sistema
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Salva esportazione SpicciTrack CSV',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/csv',
      );
      if (uri != null) {
        return uri.path;
      }
    } catch (e) {
      debugPrint('FilePicker.saveFile fallback: $e');
    }

    // 2. Fallback: salva direttamente nella cartella Downloads (o Documents) del dispositivo
    Directory? targetDir = await getDownloadsDirectory();
    targetDir ??= await getApplicationDocumentsDirectory();

    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (e) {
    debugPrint('Errore durante il salvataggio CSV: $e');
    return null;
  }
}
