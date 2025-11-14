import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/grade_provider.dart';
import '../models/grade.dart';
import '../models/course_grade.dart';
import '../utils/pdf_exporter.dart';
import 'add_edit_grade_screen.dart';

class CourseGradesScreen extends StatefulWidget {
  const CourseGradesScreen({Key? key}) : super(key: key);

  @override
  State<CourseGradesScreen> createState() => _CourseGradesScreenState();
}

class _CourseGradesScreenState extends State<CourseGradesScreen> {
  String? _selectedSemester;
  String _searchQuery = '';
  String _filterType = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Grades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<GradeProvider>(
        builder: (context, provider, child) {
          final semesters = provider.getUniqueSemesters();

          if (semesters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No courses yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Semester Tabs
              Container(
                color: Colors.grey[100],
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All Semesters'),
                        selected: _selectedSemester == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSemester = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...semesters.map((semester) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(semester),
                            selected: _selectedSemester == semester,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSemester = selected ? semester : null;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Grades List
              Expanded(child: _buildGradesList(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGradesList(GradeProvider provider) {
    List<Grade> grades;

    if (_searchQuery.isNotEmpty) {
      grades = provider.searchGrades(_searchQuery);
    } else if (_selectedSemester != null) {
      grades = provider.getGradesBySemester(_selectedSemester!);
    } else {
      grades = provider.grades;
    }

    if (_filterType != 'All') {
      grades = grades.where((g) => g.assessmentType == _filterType).toList();
    }

    if (grades.isEmpty) {
      return const Center(child: Text('No grades found'));
    }

    // Group grades by course
    Map<String, List<Grade>> courseGroups = {};
    for (var grade in grades) {
      final key = '${grade.courseCode}-${grade.semester}';
      if (!courseGroups.containsKey(key)) {
        courseGroups[key] = [];
      }
      courseGroups[key]!.add(grade);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courseGroups.length,
      itemBuilder: (context, index) {
        final entry = courseGroups.entries.elementAt(index);
        final courseGrades = entry.value;
        final firstGrade = courseGrades.first;

        // Calculate course grade
        final assessments = courseGrades
            .map(
              (g) => {
                'assessmentType': g.assessmentType,
                'maxMarks': g.maxMarks,
                'obtainedMarks': g.obtainedMarks,
                'percentage': g.percentage,
                'date': g.date,
              },
            )
            .toList();

        final courseGrade = CourseGrade.fromGrades(
          firstGrade.courseCode,
          firstGrade.courseName,
          firstGrade.semester,
          firstGrade.credits,
          assessments,
        );

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getGradeColor(courseGrade.letterGrade),
                child: Text(
                  courseGrade.letterGrade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                '${firstGrade.courseCode} - ${firstGrade.courseName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${firstGrade.semester} • ${courseGrades.length} assessments',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${courseGrade.finalGrade.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'GP: ${courseGrade.gradePoint.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              children: [
                // Grade trend chart
                if (courseGrades.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance Trend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 150,
                          child: _buildPerformanceChart(courseGrades),
                        ),
                      ],
                    ),
                  ),

                // Assessment list
                ...courseGrades.map((grade) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      _getAssessmentIcon(grade.assessmentType),
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(grade.assessmentType),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy').format(grade.date),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${grade.obtainedMarks}/${grade.maxMarks}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${grade.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddEditGradeScreen(grade: grade),
                        ),
                      );
                    },
                  );
                }).toList(),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export Report'),
                        onPressed: () =>
                            _exportCourseReport(courseGrade, courseGrades),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceChart(List<Grade> grades) {
    // Sort by date
    final sortedGrades = List<Grade>.from(grades)
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = sortedGrades.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.percentage);
    }).toList();

    // Check for improvement or decline
    final hasImprovement =
        sortedGrades.length > 1 &&
        sortedGrades.last.percentage > sortedGrades.first.percentage;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < sortedGrades.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sortedGrades[value.toInt()].assessmentType.substring(
                        0,
                        3,
                      ),
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: hasImprovement ? Colors.green : Colors.orange,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: hasImprovement
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = _searchQuery;

        return AlertDialog(
          title: const Text('Search Grades'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Search by course or assessment',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              query = value;
            },
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = query;
                });
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    final provider = Provider.of<GradeProvider>(context, listen: false);
    final assessmentTypes = ['All', ...provider.getUniqueAssessmentTypes()];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Assessment Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: assessmentTypes.map((type) {
              return RadioListTile<String>(
                title: Text(type),
                value: type,
                groupValue: _filterType,
                onChanged: (value) {
                  setState(() {
                    _filterType = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'O':
        return Colors.purple;
      case 'A+':
        return Colors.green;
      case 'A':
        return Colors.lightGreen;
      case 'B+':
        return Colors.blue;
      case 'B':
        return Colors.lightBlue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAssessmentIcon(String assessmentType) {
    switch (assessmentType.toLowerCase()) {
      case 'midterm':
      case 'final':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'quiz':
        return Icons.question_answer;
      case 'project':
        return Icons.work;
      case 'practical':
      case 'lab':
        return Icons.science;
      case 'viva':
        return Icons.record_voice_over;
      default:
        return Icons.school;
    }
  }

  Future<void> _exportCourseReport(
    CourseGrade courseGrade,
    List<Grade> grades,
  ) async {
    await PDFExporter.exportCourseReport(
      courseCode: courseGrade.courseCode,
      courseName: courseGrade.courseName,
      grades: grades,
      courseGrade: courseGrade,
    );
  }
}
