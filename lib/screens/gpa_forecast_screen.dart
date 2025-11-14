import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grade_provider.dart';

class GPAForecastScreen extends StatefulWidget {
  const GPAForecastScreen({Key? key}) : super(key: key);

  @override
  State<GPAForecastScreen> createState() => _GPAForecastScreenState();
}

class _GPAForecastScreenState extends State<GPAForecastScreen> {
  String? _selectedSemester;
  Map<String, TextEditingController> _scoreControllers = {};
  double? _forecastedGPA;

  @override
  void dispose() {
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPA Forecast')),
      body: Consumer<GradeProvider>(
        builder: (context, provider, child) {
          final semesters = provider.getUniqueSemesters();

          if (semesters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No data to forecast',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some grades first',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enter hypothetical scores to forecast your GPA for a semester',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Semester Selection
                const Text(
                  'Select Semester',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_view_month),
                  ),
                  hint: const Text('Choose a semester'),
                  items: semesters.map((semester) {
                    return DropdownMenuItem(
                      value: semester,
                      child: Text(semester),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                      _forecastedGPA = null;
                      _initializeControllers(provider);
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (_selectedSemester != null) ...[
                  // Current GPA
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Semester GPA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            provider
                                .getSemesterGPA(_selectedSemester!)
                                .toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Course Score Inputs
                  const Text(
                    'Enter Hypothetical Scores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._buildCourseInputs(provider),

                  const SizedBox(height: 24),

                  // Calculate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _calculateForecast(provider),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'Calculate Forecast',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  if (_forecastedGPA != null) ...[
                    const SizedBox(height: 24),

                    // Forecasted GPA Result
                    Card(
                      elevation: 4,
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              'Forecasted GPA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _forecastedGPA!.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildGPAComparison(provider),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Impact Analysis
                    _buildImpactAnalysis(provider),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _initializeControllers(GradeProvider provider) {
    if (_selectedSemester == null) return;

    // Dispose old controllers
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    _scoreControllers.clear();

    // Get unique courses for the selected semester
    final grades = provider.getGradesBySemester(_selectedSemester!);
    final courses = <String>{};

    for (var grade in grades) {
      courses.add(grade.courseCode);
    }

    // Create controllers for each course
    for (var course in courses) {
      final courseGrades = grades.where((g) => g.courseCode == course).toList();
      // Calculate average current percentage
      double avgPercentage = 0;
      for (var grade in courseGrades) {
        avgPercentage += grade.percentage;
      }
      avgPercentage /= courseGrades.length;

      _scoreControllers[course] = TextEditingController(
        text: avgPercentage.toStringAsFixed(1),
      );
    }
  }

  List<Widget> _buildCourseInputs(GradeProvider provider) {
    if (_selectedSemester == null || _scoreControllers.isEmpty) {
      return [];
    }

    final grades = provider.getGradesBySemester(_selectedSemester!);
    final courseNames = <String, String>{};

    for (var grade in grades) {
      courseNames[grade.courseCode] = grade.courseName;
    }

    return _scoreControllers.entries.map((entry) {
      final courseCode = entry.key;
      final controller = entry.value;
      final courseName = courseNames[courseCode] ?? '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$courseCode - $courseName',
            border: const OutlineInputBorder(),
            suffixText: '%',
            helperText: 'Enter percentage (0-100)',
          ),
          keyboardType: TextInputType.number,
        ),
      );
    }).toList();
  }

  void _calculateForecast(GradeProvider provider) {
    if (_selectedSemester == null) return;

    final hypotheticalScores = <String, double>{};

    for (var entry in _scoreControllers.entries) {
      final score = double.tryParse(entry.value.text);
      if (score != null && score >= 0 && score <= 100) {
        hypotheticalScores[entry.key] = score;
      }
    }

    if (hypotheticalScores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid scores')),
      );
      return;
    }

    setState(() {
      _forecastedGPA = provider.forecastGPA(
        _selectedSemester!,
        hypotheticalScores,
      );
    });
  }

  Widget _buildGPAComparison(GradeProvider provider) {
    final currentGPA = provider.getSemesterGPA(_selectedSemester!);
    final difference = _forecastedGPA! - currentGPA;
    final isImprovement = difference > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isImprovement ? Icons.arrow_upward : Icons.arrow_downward,
          color: isImprovement ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(
          '${difference.abs().toStringAsFixed(2)} ${isImprovement ? 'increase' : 'decrease'}',
          style: TextStyle(
            fontSize: 14,
            color: isImprovement ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactAnalysis(GradeProvider provider) {
    final currentGPA = provider.getSemesterGPA(_selectedSemester!);
    final difference = _forecastedGPA! - currentGPA;

    String analysis;
    Color color;
    IconData icon;

    if (difference > 0.5) {
      analysis =
          'Excellent improvement! Your efforts will significantly boost your GPA.';
      color = Colors.green;
      icon = Icons.celebration;
    } else if (difference > 0) {
      analysis =
          'Good progress! Keep up the good work to maintain this improvement.';
      color = Colors.lightGreen;
      icon = Icons.thumb_up;
    } else if (difference > -0.5) {
      analysis =
          'Minor change. Focus on consistency to maintain your current performance.';
      color = Colors.orange;
      icon = Icons.warning_amber;
    } else {
      analysis =
          'Significant decline. You may need to put in extra effort to improve.';
      color = Colors.red;
      icon = Icons.error_outline;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Impact Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(analysis, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
