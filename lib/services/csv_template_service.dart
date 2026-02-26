import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

enum TemplateType { mcq, essay, short }

class CsvTemplateService {
  static const Map<TemplateType, String> _templateHeaders = {
    TemplateType.mcq:
        'question,option_a,option_b,option_c,option_d,option_correct,co,lo mapping,difficulty,marks',
    TemplateType.essay:
        'question,expected points,co1,co2,co3,co4,co5,lo mapping,difficulty,marks,word limit',
    TemplateType.short:
        'question,key points,co1,co2,co3,co4,co5,lo mapping,difficulty,marks',
  };

  static const Map<TemplateType, String> _templateNames = {
    TemplateType.mcq: 'MCQ Template',
    TemplateType.essay: 'Essay Template',
    TemplateType.short: 'Short Answer Template',
  };

  static String getTemplateName(TemplateType type) => _templateNames[type]!;

  static Future<String?> downloadTemplate(TemplateType type) async {
    try {
      final headers = _templateHeaders[type];
      if (headers == null) return null;

      final csvContent = headers;
      final List<int> bytes = utf8.encode(csvContent);

      final String path = await FileSaver.instance.saveFile(
        name: 'template_${type.name}.csv',
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.csv,
      );

      return path;
    } catch (e) {
      debugPrint('Error downloading template: $e');
      return null;
    }
  }
}
