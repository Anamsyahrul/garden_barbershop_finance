import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportToCsv({
    required String fileName,
    required List<List<String>> data,
  }) async {
    try {
      // Create CSV string
      final csvData = data.map((row) {
        return row.map((cell) {
          // Escape quotes and wrap in quotes if contains comma
          final escaped = cell.replaceAll('"', '""');
          if (escaped.contains(',') || escaped.contains('"') || escaped.contains('\n')) {
            return '"$escaped"';
          }
          return escaped;
        }).join(',');
      }).join('\n');

      if (kIsWeb) {
        // Not supporting web download yet
        print('Export on web not implemented');
        return;
      }

      // Save to temp file
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      // Share or save
      final xFile = XFile(path, mimeType: 'text/csv');
      await Share.shareXFiles([xFile], subject: fileName);
      
    } catch (e) {
      print('Error exporting CSV: $e');
      rethrow;
    }
  }
}
