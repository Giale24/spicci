import 'package:uuid/uuid.dart';
import '../../models/category.dart';
import '../../models/expense.dart';

class CsvImportHelper {
  /// Analizza una stringa CSV e restituisce la lista di spese estratte.
  static List<Expense> parseExpenses(String csvContent) {
    final rows = _parseCsvRows(csvContent);
    if (rows.isEmpty) return [];

    // Cerca gli indici delle colonne esaminando la prima riga
    final headerRow = rows.first;
    int colId = -1;
    int colDate = -1;
    int colTime = -1;
    int colCategory = -1;
    int colTag = -1;
    int colAmount = -1;
    int colFixed = -1;
    int colExtraordinary = -1;
    int colNote = -1;
    int colCalculation = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final h = headerRow[i].trim().toLowerCase().replaceAll(RegExp(r'[\s_]+'), '');
      if (h == 'id' || h == 'codice') {
        colId = i;
      } else if (h == 'data' || h == 'date' || h == 'giorno' || h == 'day') {
        colDate = i;
      } else if (h == 'ora' || h == 'time' || h == 'orario') {
        colTime = i;
      } else if (h == 'categoria' || h == 'category' || h == 'cat') {
        colCategory = i;
      } else if (h == 'tag' || h == 'sottocategoria' || h == 'subcat' || h == 'etichetta') {
        colTag = i;
      } else if (h == 'importo' || h == 'amount' || h == 'cifra' || h == 'prezzo' || h == 'totale' || h == 'costo' || h == 'spesa') {
        colAmount = i;
      } else if (h == 'fissa' || h == 'fixed' || h == 'ricorrente') {
        colFixed = i;
      } else if (h == 'fuoribudget' || h == 'extraordinary' || h == 'straordinaria') {
        colExtraordinary = i;
      } else if (h == 'nota' || h == 'note' || h == 'descrizione' || h == 'description' || h == 'dettaglio') {
        colNote = i;
      } else if (h == 'dettagliocalcolo' || h == 'calcolo' || h == 'calculation' || h == 'calcolatrice') {
        colCalculation = i;
      }
    }

    // Se la prima riga era un'intestazione riconosciuta, iniziamo dalla riga 1, altrimenti da riga 0
    final hasHeader = (colDate != -1 || colAmount != -1 || colCategory != -1);
    final startIndex = hasHeader ? 1 : 0;

    // Se non c'è intestazione, assegniamo un fallback basato sulle colonne standard di Spicci
    if (!hasHeader) {
      if (headerRow.length >= 6) {
        colId = 0;
        colDate = 1;
        colTime = 2;
        colCategory = 3;
        colTag = 4;
        colAmount = 5;
        if (headerRow.length > 6) colFixed = 6;
        if (headerRow.length > 7) colExtraordinary = 7;
        if (headerRow.length > 8) colNote = 8;
        if (headerRow.length > 9) colCalculation = 9;
      } else if (headerRow.length >= 3) {
        // Formato compatto: Data, Categoria, Importo, [Nota]
        colDate = 0;
        colCategory = 1;
        colAmount = 2;
        if (headerRow.length > 3) colNote = 3;
      }
    }

    final List<Expense> expenses = [];
    const uuid = Uuid();

    for (int r = startIndex; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty || (row.length == 1 && row[0].isEmpty)) continue;

      // 1. Importo (obbligatorio)
      String rawAmount = colAmount >= 0 && colAmount < row.length ? row[colAmount] : '';
      // Se il CSV usa la virgola come separatore di colonna ed un importo con virgola decimale italiana
      // non era racchiuso tra virgolette, viene spezzato nella colonna successiva (es. -45 e 50 €)
      if (colAmount >= 0 && colAmount == row.length - 2 && colAmount == headerRow.length - 1) {
        final nextField = row[colAmount + 1].trim();
        if (RegExp(r'^\d{1,2}(\s*€)?$').hasMatch(nextField)) {
          rawAmount = '$rawAmount,$nextField';
        }
      }
      final amount = _parseAmount(rawAmount);
      if (amount == null || amount <= 0) continue;

      // 2. Data e Ora
      final rawDate = colDate >= 0 && colDate < row.length ? row[colDate] : '';
      final rawTime = colTime >= 0 && colTime < row.length ? row[colTime] : null;
      final date = _parseDateTime(rawDate, rawTime) ?? DateTime.now();

      // 3. Categoria
      final rawCat = colCategory >= 0 && colCategory < row.length ? row[colCategory] : '';
      final categoryId = _resolveCategoryId(rawCat);

      // 4. Tag opzionale
      final rawTag = colTag >= 0 && colTag < row.length ? row[colTag].trim() : '';
      final tag = rawTag.isNotEmpty ? rawTag : null;

      // 5. Nota opzionale
      final rawNote = colNote >= 0 && colNote < row.length ? row[colNote].trim() : '';
      final note = rawNote.isNotEmpty ? rawNote : null;

      // 6. ID
      final rawId = colId >= 0 && colId < row.length ? row[colId].trim() : '';
      final id = (rawId.isNotEmpty && rawId.length > 4) ? rawId : uuid.v4();

      // 7. Spesa Fissa
      final rawFixed = colFixed >= 0 && colFixed < row.length ? row[colFixed] : '';
      final isFixed = _parseBool(rawFixed);

      // 8. Fuori Budget
      final rawExtraordinary = colExtraordinary >= 0 && colExtraordinary < row.length ? row[colExtraordinary] : '';
      final isExtraordinary = _parseBool(rawExtraordinary);

      // 9. Dettaglio Calcolo
      final rawCalc = colCalculation >= 0 && colCalculation < row.length ? row[colCalculation].trim() : '';
      final calculationNote = rawCalc.isNotEmpty ? rawCalc : null;

      expenses.add(
        Expense(
          id: id,
          amount: amount,
          categoryId: categoryId,
          tag: tag,
          note: note,
          date: date,
          isFixed: isFixed,
          isExtraordinary: isExtraordinary,
          calculationNote: calculationNote,
        ),
      );
    }

    return expenses;
  }

  /// Parser robusto per righe CSV che gestisce virgolette, separatori e newline interni
  static List<List<String>> _parseCsvRows(String content) {
    if (content.isEmpty) return [];

    // Rimuove eventuale BOM UTF-8 (\uFEFF)
    String cleanContent = content;
    if (cleanContent.startsWith('\uFEFF')) {
      cleanContent = cleanContent.substring(1);
    }

    // Rileva delimitatore (; oppure , o \t)
    final firstLine = cleanContent.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    String delimiter = ';';
    final countSemicolon = ';'.allMatches(firstLine).length;
    final countComma = ','.allMatches(firstLine).length;
    final countTab = '\t'.allMatches(firstLine).length;

    if (countComma > countSemicolon && countComma > countTab) {
      delimiter = ',';
    } else if (countTab > countSemicolon && countTab > countComma) {
      delimiter = '\t';
    }

    final List<List<String>> rows = [];
    List<String> currentRow = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < cleanContent.length; i++) {
      final char = cleanContent[i];

      if (char == '"') {
        if (inQuotes && i + 1 < cleanContent.length && cleanContent[i + 1] == '"') {
          currentField.write('"');
          i++; // Salta il doppio apice di escape
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        currentRow.add(currentField.toString().trim());
        currentField.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < cleanContent.length && cleanContent[i + 1] == '\n') {
          i++;
        }
        currentRow.add(currentField.toString().trim());
        currentField.clear();
        if (currentRow.any((f) => f.isNotEmpty)) {
          rows.add(currentRow);
        }
        currentRow = [];
      } else {
        currentField.write(char);
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((f) => f.isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }

  /// Converte stringhe di importo (es. "12,50", "1.250,50 €", "-15.00") in double positivo
  static double? _parseAmount(String raw) {
    if (raw.trim().isEmpty) return null;

    String clean = raw.replaceAll(RegExp(r'[^0-9,\.\-]'), '').trim();
    if (clean.isEmpty) return null;

    final isNegative = clean.startsWith('-');
    if (isNegative) clean = clean.substring(1);

    if (clean.contains(',') && clean.contains('.')) {
      final lastComma = clean.lastIndexOf(',');
      final lastDot = clean.lastIndexOf('.');
      if (lastComma > lastDot) {
        // Formato italiano: 1.250,50 -> 1250.50
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Formato anglosassone: 1,250.50 -> 1250.50
        clean = clean.replaceAll(',', '');
      }
    } else if (clean.contains(',')) {
      clean = clean.replaceAll(',', '.');
    }

    final val = double.tryParse(clean);
    return val?.abs();
  }

  /// Converte data e ora da vari formati comuni
  static DateTime? _parseDateTime(String rawDate, String? rawTime) {
    final d = rawDate.trim();
    if (d.isEmpty) return null;

    DateTime? parsedDate;

    // 1. Prova formato ISO standard (es. 2026-10-30 o 2026-10-30T12:00:00)
    parsedDate = DateTime.tryParse(d);

    // 2. Prova formato italiano GG/MM/AAAA o GG-MM-AAAA
    if (parsedDate == null) {
      final itMatch = RegExp(r'^(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})').firstMatch(d);
      if (itMatch != null) {
        final day = int.tryParse(itMatch.group(1)!) ?? 1;
        final month = int.tryParse(itMatch.group(2)!) ?? 1;
        int year = int.tryParse(itMatch.group(3)!) ?? DateTime.now().year;
        if (year < 100) year += 2000;
        parsedDate = DateTime(year, month, day);
      }
    }

    // 3. Prova formato AAAA/MM/GG
    if (parsedDate == null) {
      final yMatch = RegExp(r'^(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})').firstMatch(d);
      if (yMatch != null) {
        final year = int.tryParse(yMatch.group(1)!) ?? DateTime.now().year;
        final month = int.tryParse(yMatch.group(2)!) ?? 1;
        final day = int.tryParse(yMatch.group(3)!) ?? 1;
        parsedDate = DateTime(year, month, day);
      }
    }

    if (parsedDate == null) return null;

    // Aggiunge l'ora se presente
    int hour = parsedDate.hour;
    int minute = parsedDate.minute;

    if (rawTime != null && rawTime.trim().isNotEmpty) {
      final timeMatch = RegExp(r'^(\d{1,2}):(\d{1,2})').firstMatch(rawTime.trim());
      if (timeMatch != null) {
        hour = int.tryParse(timeMatch.group(1)!) ?? hour;
        minute = int.tryParse(timeMatch.group(2)!) ?? minute;
      }
    }

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
  }

  /// Risolve il nome o id della categoria verso gli ID ufficiali di Spicci
  static String _resolveCategoryId(String raw) {
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) return 'altro';

    // Ricerca diretta per id o nome
    for (final cat in Category.defaultCategories) {
      if (cat.id == clean || cat.name.toLowerCase() == clean) {
        return cat.id;
      }
    }

    // Sinonimi comuni per importazione da altri budget tracker o estratti conto
    if (clean.contains('cibo') || clean.contains('alimentar') || clean.contains('spesa') || clean.contains('ristor') || clean.contains('bar') || clean.contains('food') || clean.contains('pranzo') || clean.contains('cena')) {
      return 'cibo';
    }
    if (clean.contains('trasport') || clean.contains('auto') || clean.contains('benzina') || clean.contains('carburante') || clean.contains('treno') || clean.contains('mezzi') || clean.contains('pedaggio') || clean.contains('taxi')) {
      return 'trasporti';
    }
    if (clean.contains('svago') || clean.contains('divertiment') || clean.contains('hobby') || clean.contains('cinema') || clean.contains('viagg') || clean.contains('sport') || clean.contains('giochi')) {
      return 'svago';
    }
    if (clean.contains('casa') || clean.contains('affitto') || clean.contains('bollett') || clean.contains('luce') || clean.contains('gas') || clean.contains('acqua') || clean.contains('mutuo') || clean.contains('arred')) {
      return 'casa';
    }
    if (clean.contains('shopping') || clean.contains('abbigliamento') || clean.contains('vestiti') || clean.contains('scarpe') || clean.contains('elettronica') || clean.contains('amazon')) {
      return 'shopping';
    }
    if (clean.contains('salute') || clean.contains('farmacia') || clean.contains('medic') || clean.contains('dentista') || clean.contains('dottore') || clean.contains('terapia')) {
      return 'salute';
    }
    if (clean.contains('abbonament') || clean.contains('netflix') || clean.contains('spotify') || clean.contains('palestra') || clean.contains('telefono') || clean.contains('internet')) {
      return 'abbonamenti';
    }

    return 'altro';
  }

  /// Converte indicatori booleani (SI, YES, TRUE, 1) in bool
  static bool _parseBool(String raw) {
    final clean = raw.trim().toUpperCase();
    return clean == 'SI' || clean == 'SÌ' || clean == 'YES' || clean == 'TRUE' || clean == '1' || clean == 'Y' || clean == 'S';
  }
}
