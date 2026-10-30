import 'package:flutter_test/flutter_test.dart';
import 'package:spicci/core/utils/csv_import_helper.dart';

void main() {
  group('CsvImportHelper', () {
    test('parses standard Spicci export CSV correctly', () {
      const csv = '''ID;Data;Ora;Categoria;Tag;Importo;Fissa;FuoriBudget;Nota;DettaglioCalcolo
"abc-1";2026-10-30;12:30;Cibo;Pranzo;15,50;NO;NO;"Pizza con colleghi";"10+5.5"
"abc-2";2026-10-29;08:15;Trasporti;;2,20;NO;NO;"Biglietto metro";""
"abc-3";2026-10-01;00:00;Casa;Affitto;650,00;SI;NO;"Affitto mensile";""
"abc-4";2026-09-15;16:45;Altro;;120,00;NO;SI;"Riparazione auto straordinaria";""
''';

      final expenses = CsvImportHelper.parseExpenses(csv);

      expect(expenses.length, 4);

      expect(expenses[0].id, 'abc-1');
      expect(expenses[0].amount, 15.50);
      expect(expenses[0].categoryId, 'cibo');
      expect(expenses[0].tag, 'Pranzo');
      expect(expenses[0].isFixed, false);
      expect(expenses[0].isExtraordinary, false);
      expect(expenses[0].note, 'Pizza con colleghi');
      expect(expenses[0].calculationNote, '10+5.5');
      expect(expenses[0].date.year, 2026);
      expect(expenses[0].date.month, 10);
      expect(expenses[0].date.day, 30);
      expect(expenses[0].date.hour, 12);
      expect(expenses[0].date.minute, 30);

      expect(expenses[2].amount, 650.0);
      expect(expenses[2].isFixed, true);
      expect(expenses[2].isExtraordinary, false);

      expect(expenses[3].amount, 120.0);
      expect(expenses[3].isFixed, false);
      expect(expenses[3].isExtraordinary, true);
    });

    test('parses bank export with commas, Italian dates, and currency symbols', () {
      const csv = '''Data,Categoria,Descrizione,Importo
30/10/2026,Ristorante,"Cena giapponese",-45,50 €
28/10/2026,Benzina,Rifornimento Eni,65.00
25/10/2026,Farmacia,Medicine,12,30
''';

      final expenses = CsvImportHelper.parseExpenses(csv);

      expect(expenses.length, 3);
      // Synonym mappings
      expect(expenses[0].categoryId, 'cibo');
      expect(expenses[0].amount, 45.50);
      expect(expenses[0].note, 'Cena giapponese');
      expect(expenses[0].date.day, 30);
      expect(expenses[0].date.month, 10);
      expect(expenses[0].date.year, 2026);

      expect(expenses[1].categoryId, 'trasporti');
      expect(expenses[1].amount, 65.0);

      expect(expenses[2].categoryId, 'salute');
      expect(expenses[2].amount, 12.30);
    });

    test('handles quotes with newlines and escaped quotes', () {
      const csv = '''Data;Categoria;Importo;Nota
2026-10-30;Cibo;25,00;"Nota su
più righe con ""doppi apici"""
''';

      final expenses = CsvImportHelper.parseExpenses(csv);

      expect(expenses.length, 1);
      expect(expenses[0].amount, 25.0);
      expect(expenses[0].note, 'Nota su\npiù righe con "doppi apici"');
    });

    test('ignores empty or malformed rows', () {
      const csv = '''Data;Categoria;Importo
;;
2026-10-30;Altro;0
2026-10-30;Cibo;invalid
2026-10-30;Cibo;10.50
;;
''';

      final expenses = CsvImportHelper.parseExpenses(csv);
      expect(expenses.length, 1);
      expect(expenses[0].amount, 10.50);
    });
  });
}
