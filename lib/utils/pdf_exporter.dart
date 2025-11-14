import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/grade.dart';
import '../models/course_grade.dart';

class PDFExporter {
  static Future<void> exportTranscript({
    required String studentName,
    required String studentId,
    required double overallGPA,
    required Map<String, double> semesterGPAs,
    required Map<String, List<CourseGrade>> courseGrades,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Academic Transcript',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Student Name: $studentName'),
                          pw.SizedBox(height: 4),
                          pw.Text('Student ID: $studentId'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Overall GPA: ${overallGPA.toStringAsFixed(2)}',
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Generated: ${DateTime.now().toString().split(' ')[0]}',
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),

            // Semester-wise grades
            ...courseGrades.entries.map((entry) {
              final semester = entry.key;
              final courses = entry.value;
              final semesterGPA = semesterGPAs[semester] ?? 0.0;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 16),
                  pw.Container(
                    color: PdfColors.grey300,
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          semester,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Semester GPA: ${semesterGPA.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      // Header row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          _buildTableCell('Course Code', isHeader: true),
                          _buildTableCell('Course Name', isHeader: true),
                          _buildTableCell('Credits', isHeader: true),
                          _buildTableCell('Grade', isHeader: true),
                          _buildTableCell('Grade Point', isHeader: true),
                        ],
                      ),
                      // Data rows
                      ...courses.map((course) {
                        return pw.TableRow(
                          children: [
                            _buildTableCell(course.courseCode),
                            _buildTableCell(course.courseName),
                            _buildTableCell(course.credits.toString()),
                            _buildTableCell(course.letterGrade),
                            _buildTableCell(
                              course.gradePoint.toStringAsFixed(2),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ],
              );
            }).toList(),

            // GPA Summary
            pw.SizedBox(height: 24),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 2),
              ),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GPA Summary',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(),
                  pw.SizedBox(height: 8),
                  ...semesterGPAs.entries.map((entry) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(entry.key),
                          pw.Text(
                            entry.value.toStringAsFixed(2),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Cumulative GPA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        overallGPA.toStringAsFixed(2),
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grading Scale
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Grading Scale',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      _buildGradeScaleRow('O', '10.0', '90% and above'),
                      _buildGradeScaleRow('A+', '9.0', '80% - 89%'),
                      _buildGradeScaleRow('A', '8.0', '70% - 79%'),
                      _buildGradeScaleRow('B+', '7.0', '60% - 69%'),
                      _buildGradeScaleRow('B', '6.0', '50% - 59%'),
                      _buildGradeScaleRow('C', '5.0', '45% - 49%'),
                      _buildGradeScaleRow('D', '4.0', '40% - 44%'),
                      _buildGradeScaleRow('F', '0.0', 'Below 40%'),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  static pw.TableRow _buildGradeScaleRow(
    String grade,
    String point,
    String range,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(grade, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(point, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(range, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  static Future<void> exportCourseReport({
    required String courseCode,
    required String courseName,
    required List<Grade> grades,
    required CourseGrade courseGrade,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Course Grade Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    '$courseCode - $courseName',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Final Grade: ${courseGrade.letterGrade}'),
                      pw.Text(
                        'Grade Point: ${courseGrade.gradePoint.toStringAsFixed(2)}',
                      ),
                      pw.Text(
                        'Percentage: ${courseGrade.finalGrade.toStringAsFixed(2)}%',
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ],
              ),
            ),

            // Assessments table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Assessment Type', isHeader: true),
                    _buildTableCell('Max Marks', isHeader: true),
                    _buildTableCell('Obtained', isHeader: true),
                    _buildTableCell('Percentage', isHeader: true),
                    _buildTableCell('Date', isHeader: true),
                  ],
                ),
                // Data rows
                ...grades.map((grade) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(grade.assessmentType),
                      _buildTableCell(grade.maxMarks.toString()),
                      _buildTableCell(grade.obtainedMarks.toString()),
                      _buildTableCell(
                        '${grade.percentage.toStringAsFixed(2)}%',
                      ),
                      _buildTableCell(grade.date.toString().split(' ')[0]),
                    ],
                  );
                }).toList(),
              ],
            ),

            // Remarks section
            if (grades.any((g) => g.remarks != null && g.remarks!.isNotEmpty))
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 24),
                  pw.Text(
                    'Remarks',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  ...grades
                      .where((g) => g.remarks != null && g.remarks!.isNotEmpty)
                      .map((grade) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Text(
                            '${grade.assessmentType}: ${grade.remarks}',
                          ),
                        );
                      })
                      .toList(),
                ],
              ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
