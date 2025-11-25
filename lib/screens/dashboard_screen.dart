import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/grade_provider.dart';
import 'add_edit_grade_screen.dart';
import 'course_grades_screen.dart';
import 'deadlines_screen.dart';
import 'gpa_forecast_screen.dart';
import '../utils/pdf_exporter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Tracker Dashboard'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Transcript',
            onPressed: () => _exportTranscript(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              Provider.of<GradeProvider>(context, listen: false).loadAllData();
            },
          ),
        ],
      ),
      body: Consumer<GradeProvider>(
        builder: (context, gradeProvider, child) {
          if (gradeProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => gradeProvider.loadAllData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPA Overview Card
                  _buildGPACard(context, gradeProvider),
                  const SizedBox(height: 16),

                  // Next Deadline Card
                  _buildDeadlineCard(context, gradeProvider),
                  const SizedBox(height: 16),

                  // Quick Stats
                  _buildQuickStats(context, gradeProvider),
                  const SizedBox(height: 16),

                  // GPA Trend Chart
                  _buildGPATrendChart(context, gradeProvider),
                  const SizedBox(height: 16),

                  // Grade Distribution
                  _buildGradeDistribution(context, gradeProvider),
                  const SizedBox(height: 16),

                  // Recent Grades
                  _buildRecentGrades(context, gradeProvider),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditGradeScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Grade'),
      ),
    );
  }

  Widget _buildGPACard(BuildContext context, GradeProvider provider) {
    final overallGPA = provider.overallGPA;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Overall GPA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overallGPA.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getGPADescription(overallGPA),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGPAAction(
                  context,
                  Icons.school,
                  'View Courses',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CourseGradesScreen(),
                    ),
                  ),
                ),
                _buildGPAAction(
                  context,
                  Icons.trending_up,
                  'Forecast',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GPAForecastScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPAAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(BuildContext context, GradeProvider provider) {
    final nextDeadline = provider.getNextDeadline();

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DeadlinesScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: nextDeadline != null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getDeadlineColor(
                          nextDeadline.daysUntilDeadline,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: _getDeadlineColor(
                          nextDeadline.daysUntilDeadline,
                        ),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Next Re-evaluation Deadline',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextDeadline.courseCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(nextDeadline.deadline),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${nextDeadline.daysUntilDeadline}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getDeadlineColor(
                              nextDeadline.daysUntilDeadline,
                            ),
                          ),
                        ),
                        Text(
                          'days left',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDeadlineColor(
                              nextDeadline.daysUntilDeadline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No upcoming deadlines',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, GradeProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Courses',
            provider.getUniqueCourses().length.toString(),
            Icons.book,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Total Grades',
            provider.grades.length.toString(),
            Icons.assessment,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Average',
            '${provider.getAverageGrade().toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPATrendChart(BuildContext context, GradeProvider provider) {
    final semesterGPAs = provider.semesterGPAs;

    if (semesterGPAs.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedSemesters = semesterGPAs.keys.toList()..sort();
    final spots = sortedSemesters.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), semesterGPAs[entry.value]!);
    }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPA Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < sortedSemesters.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedSemesters[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 10,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistribution(BuildContext context, GradeProvider provider) {
    final distribution = provider.getGradeDistribution();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grade Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...distribution.entries.map((entry) {
              final total = distribution.values.fold<int>(
                0,
                (sum, count) => sum + count,
              );
              final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getGradeColor(entry.key),
                        ),
                        minHeight: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 12),
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
  }

  Widget _buildRecentGrades(BuildContext context, GradeProvider provider) {
    final recentGrades = provider.grades.take(5).toList();

    if (recentGrades.isEmpty) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No grades yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first grade',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Grades',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CourseGradesScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentGrades.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final grade = recentGrades[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getGradeColor(grade.letterGrade),
                  child: Text(
                    grade.letterGrade,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${grade.courseCode} - ${grade.courseName}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${grade.assessmentType} • ${DateFormat('MMM dd, yyyy').format(grade.date)}',
                ),
                trailing: Text(
                  '${grade.obtainedMarks}/${grade.maxMarks}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditGradeScreen(grade: grade),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getGPADescription(double gpa) {
    if (gpa >= 9.0) return 'Outstanding Performance!';
    if (gpa >= 8.0) return 'Excellent Work!';
    if (gpa >= 7.0) return 'Good Progress!';
    if (gpa >= 6.0) return 'Keep it up!';
    if (gpa >= 5.0) return 'Room for improvement';
    return 'Need to work harder';
  }

  Color _getDeadlineColor(int daysLeft) {
    if (daysLeft <= 3) return Colors.red;
    if (daysLeft <= 7) return Colors.orange;
    return Colors.green;
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

  Future<void> _exportTranscript(BuildContext context) async {
    final provider = Provider.of<GradeProvider>(context, listen: false);

    // Show dialog for student details
    String? studentName;
    String? studentId;

    await showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final idController = TextEditingController();

        return AlertDialog(
          title: const Text('Student Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                studentName = nameController.text;
                studentId = idController.text;
                Navigator.pop(context);
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );

    if (studentName != null && studentId != null) {
      await PDFExporter.exportTranscript(
        studentName: studentName!,
        studentId: studentId!,
        overallGPA: provider.overallGPA,
        semesterGPAs: provider.semesterGPAs,
        courseGrades: provider.getAllCourseGrades(),
      );
    }
  }
}
