import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import '../models/question.dart';

class ExportService {
  static Future<void> generateAndSavePdf(
    String courseCode,
    List<Question> questions,
    Map<String, dynamic>? stats,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'QUESTION PAPER: $courseCode',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Questions: ${questions.length}'),
                    pw.Text('Total Marks: ${stats?['total_marks'] ?? 0}'),
                  ],
                ),
                pw.SizedBox(height: 16),
              ],
            ),
          ),
          ...questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Q${i + 1}. ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          q.text,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        '[${q.marks} Marks]',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (q.options != null && q.options!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 24),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: ['a', 'b', 'c', 'd']
                            .where((k) => q.options!.containsKey(k))
                            .map(
                              (k) => pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 4),
                                child: pw.Text(
                                  '${k.toUpperCase()}) ${q.options![k]}',
                                  style: const pw.TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.SizedBox(width: 24),
                      pw.Text(
                        'CO: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        q.coMap.keys.join(', '),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        'LO: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        q.loList.join(', '),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.SizedBox(width: 24),
                      pw.Text(
                        'Correct Answer: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        q.correctAnswer ?? 'N/A',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    // Answer Key Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 1, text: 'Answer Key'),
            pw.SizedBox(height: 16),
            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.SizedBox(width: 40, child: pw.Text('Q${i + 1}:')),
                    pw.Text(
                      q.correctAnswer ?? 'N/A',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      '(CO: ${q.coMap.keys.join(', ')} | LO: ${q.loList.join(', ')})',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );

    final bytes = await pdf.save();

    String? outputPath;
    try {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select where to save the question paper:',
        fileName: 'question_paper_${courseCode.replaceAll(' ', '_')}.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (e) {
      if (e.toString().contains('UnimplementedError')) {
        final directory = await FilePicker.platform.getDirectoryPath();
        if (directory != null) {
          outputPath =
              '$directory/question_paper_${courseCode.replaceAll(' ', '_')}.pdf';
        }
      } else {
        rethrow;
      }
    }

    if (outputPath != null) {
      final file = File(outputPath);
      await file.writeAsBytes(bytes);
    }
  }

  static Future<void> exportToCsv(
    String courseCode,
    List<Question> questions,
  ) async {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(
      'Q No,Question,Type,Option A,Option B,Option C,Option D,Correct Answer,Marks,Difficulty,Course Outcomes,Learning Objectives',
    );

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final List<String> row = [
        (i + 1).toString(),
        '"${q.text.replaceAll('"', '""')}"',
        q.type,
        '"${(q.options?['a'] ?? '').toString().replaceAll('"', '""')}"',
        '"${(q.options?['b'] ?? '').toString().replaceAll('"', '""')}"',
        '"${(q.options?['c'] ?? '').toString().replaceAll('"', '""')}"',
        '"${(q.options?['d'] ?? '').toString().replaceAll('"', '""')}"',
        '"${(q.correctAnswer ?? '').replaceAll('"', '""')}"',
        (q.marks ?? 0).toString(),
        q.difficulty ?? 'Medium',
        '"${q.coMap.keys.join(', ')}"',
        '"${q.loList.join(', ')}"',
      ];
      buffer.writeln(row.join(','));
    }

    final bytes = utf8.encode(buffer.toString());

    String? outputPath;
    try {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select where to save the CSV file:',
        fileName: 'question_paper_${courseCode.replaceAll(' ', '_')}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
    } catch (e) {
      if (e.toString().contains('UnimplementedError')) {
        final directory = await FilePicker.platform.getDirectoryPath();
        if (directory != null) {
          outputPath =
              '$directory/question_paper_${courseCode.replaceAll(' ', '_')}.csv';
        }
      } else {
        rethrow;
      }
    }

    if (outputPath != null) {
      final file = File(outputPath);
      await file.writeAsBytes(bytes);
    }
  }
}
