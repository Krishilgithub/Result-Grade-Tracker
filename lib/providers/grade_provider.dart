import 'package:flutter/foundation.dart';
import '../models/grade.dart';
import '../models/course_grade.dart';
import '../models/deadline.dart';
import '../database/database_helper.dart';

class GradeProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Grade> _grades = [];
  List<ReEvaluationDeadline> _deadlines = [];
  double _overallGPA = 0.0;
  Map<String, double> _semesterGPAs = {};
  bool _isLoading = false;

  List<Grade> get grades => _grades;
  List<ReEvaluationDeadline> get deadlines => _deadlines;
  double get overallGPA => _overallGPA;
  Map<String, double> get semesterGPAs => _semesterGPAs;
  bool get isLoading => _isLoading;

  GradeProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    await Future.wait([loadGrades(), loadDeadlines(), loadGPAs()]);

    _isLoading = false;
    notifyListeners();
  }

  // ==================== GRADE OPERATIONS ====================

  Future<void> loadGrades() async {
    _grades = await _dbHelper.getAllGrades();
    notifyListeners();
  }

  Future<void> addGrade(Grade grade) async {
    await _dbHelper.insertGrade(grade);
    await loadGrades();
    await loadGPAs();
  }

  Future<void> updateGrade(Grade grade) async {
    await _dbHelper.updateGrade(grade);
    await loadGrades();
    await loadGPAs();
  }

  Future<void> deleteGrade(int id) async {
    await _dbHelper.deleteGrade(id);
    await loadGrades();
    await loadGPAs();
  }

  List<Grade> getGradesByCourse(String courseCode) {
    return _grades.where((grade) => grade.courseCode == courseCode).toList();
  }

  List<Grade> getGradesBySemester(String semester) {
    return _grades.where((grade) => grade.semester == semester).toList();
  }

  List<Grade> searchGrades(String query) {
    final lowerQuery = query.toLowerCase();
    return _grades.where((grade) {
      return grade.courseCode.toLowerCase().contains(lowerQuery) ||
          grade.courseName.toLowerCase().contains(lowerQuery) ||
          grade.assessmentType.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Grade> filterByAssessmentType(String assessmentType) {
    return _grades
        .where((grade) => grade.assessmentType == assessmentType)
        .toList();
  }

  // ==================== COURSE GRADE OPERATIONS ====================

  List<CourseGrade> getCourseGrades(String semester) {
    final semesterGrades = getGradesBySemester(semester);

    // Group grades by course
    Map<String, List<Grade>> courseGradesMap = {};
    for (var grade in semesterGrades) {
      if (!courseGradesMap.containsKey(grade.courseCode)) {
        courseGradesMap[grade.courseCode] = [];
      }
      courseGradesMap[grade.courseCode]!.add(grade);
    }

    // Create CourseGrade objects
    List<CourseGrade> courseGrades = [];
    for (var entry in courseGradesMap.entries) {
      final grades = entry.value;
      final assessments = grades
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

      courseGrades.add(
        CourseGrade.fromGrades(
          grades.first.courseCode,
          grades.first.courseName,
          grades.first.semester,
          grades.first.credits,
          assessments,
        ),
      );
    }

    return courseGrades;
  }

  Map<String, List<CourseGrade>> getAllCourseGrades() {
    final semesters = getUniqueSemesters();
    Map<String, List<CourseGrade>> allCourseGrades = {};

    for (var semester in semesters) {
      allCourseGrades[semester] = getCourseGrades(semester);
    }

    return allCourseGrades;
  }

  // ==================== GPA OPERATIONS ====================

  Future<void> loadGPAs() async {
    _overallGPA = await _dbHelper.calculateOverallGPA();
    _semesterGPAs = await _dbHelper.getAllSemesterGPAs();
    notifyListeners();
  }

  double getSemesterGPA(String semester) {
    return _semesterGPAs[semester] ?? 0.0;
  }

  // ==================== DEADLINE OPERATIONS ====================

  Future<void> loadDeadlines() async {
    _deadlines = await _dbHelper.getAllDeadlines();
    notifyListeners();
  }

  Future<void> addDeadline(ReEvaluationDeadline deadline) async {
    await _dbHelper.insertDeadline(deadline);
    await loadDeadlines();
  }

  Future<void> updateDeadline(ReEvaluationDeadline deadline) async {
    await _dbHelper.updateDeadline(deadline);
    await loadDeadlines();
  }

  Future<void> deleteDeadline(int id) async {
    await _dbHelper.deleteDeadline(id);
    await loadDeadlines();
  }

  ReEvaluationDeadline? getNextDeadline() {
    if (_deadlines.isEmpty) return null;

    final now = DateTime.now();
    final futureDeadlines = _deadlines
        .where((d) => d.deadline.isAfter(now))
        .toList();

    if (futureDeadlines.isEmpty) return null;

    futureDeadlines.sort((a, b) => a.deadline.compareTo(b.deadline));
    return futureDeadlines.first;
  }

  // ==================== UTILITY OPERATIONS ====================

  List<String> getUniqueSemesters() {
    final semesters = _grades.map((g) => g.semester).toSet().toList();
    semesters.sort();
    return semesters;
  }

  List<String> getUniqueCourses() {
    final courses = _grades
        .map((g) => '${g.courseCode} - ${g.courseName}')
        .toSet()
        .toList();
    courses.sort();
    return courses;
  }

  List<String> getUniqueAssessmentTypes() {
    final types = _grades.map((g) => g.assessmentType).toSet().toList();
    types.sort();
    return types;
  }

  // ==================== STATISTICS ====================

  double getAverageGrade() {
    if (_grades.isEmpty) return 0.0;
    final total = _grades.fold<double>(
      0,
      (sum, grade) => sum + grade.percentage,
    );
    return total / _grades.length;
  }

  Grade? getHighestGrade() {
    if (_grades.isEmpty) return null;
    return _grades.reduce((a, b) => a.percentage > b.percentage ? a : b);
  }

  Grade? getLowestGrade() {
    if (_grades.isEmpty) return null;
    return _grades.reduce((a, b) => a.percentage < b.percentage ? a : b);
  }

  Map<String, int> getGradeDistribution() {
    Map<String, int> distribution = {
      'O': 0,
      'A+': 0,
      'A': 0,
      'B+': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'F': 0,
    };

    for (var grade in _grades) {
      distribution[grade.letterGrade] =
          (distribution[grade.letterGrade] ?? 0) + 1;
    }

    return distribution;
  }

  // ==================== GPA FORECASTING ====================

  double forecastGPA(String semester, Map<String, double> hypotheticalScores) {
    // Get current grades for the semester
    final currentGrades = getGradesBySemester(semester);

    // Group by course
    Map<String, List<Grade>> courseGrades = {};
    for (var grade in currentGrades) {
      if (!courseGrades.containsKey(grade.courseCode)) {
        courseGrades[grade.courseCode] = [];
      }
      courseGrades[grade.courseCode]!.add(grade);
    }

    double totalGradePoints = 0.0;
    int totalCredits = 0;

    for (var entry in courseGrades.entries) {
      final courseCode = entry.key;
      final grades = entry.value;

      double percentage;

      // Use hypothetical score if provided
      if (hypotheticalScores.containsKey(courseCode)) {
        percentage = hypotheticalScores[courseCode]!;
      } else {
        // Calculate average from existing grades
        double totalPercentage = 0.0;
        for (var grade in grades) {
          totalPercentage += grade.percentage;
        }
        percentage = totalPercentage / grades.length;
      }

      // Convert to grade point
      double gradePoint;
      if (percentage >= 90) {
        gradePoint = 10.0;
      } else if (percentage >= 80) {
        gradePoint = 9.0;
      } else if (percentage >= 70) {
        gradePoint = 8.0;
      } else if (percentage >= 60) {
        gradePoint = 7.0;
      } else if (percentage >= 50) {
        gradePoint = 6.0;
      } else if (percentage >= 45) {
        gradePoint = 5.0;
      } else if (percentage >= 40) {
        gradePoint = 4.0;
      } else {
        gradePoint = 0.0;
      }

      final credits = grades.first.credits;
      totalGradePoints += gradePoint * credits;
      totalCredits += credits;
    }

    return totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
  }
}
