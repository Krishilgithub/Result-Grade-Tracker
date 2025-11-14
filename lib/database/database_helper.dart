import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/grade.dart';
import '../models/deadline.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grades.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Create grades table
    await db.execute('''
      CREATE TABLE grades (
        id $idType,
        courseCode $textType,
        courseName $textType,
        assessmentType $textType,
        maxMarks $realType,
        obtainedMarks $realType,
        date $textType,
        remarks TEXT,
        marksheetPath TEXT,
        semester $textType,
        credits $intType
      )
    ''');

    // Create deadlines table
    await db.execute('''
      CREATE TABLE deadlines (
        id $idType,
        courseCode $textType,
        deadline $textType,
        description TEXT,
        isCompleted $intType
      )
    ''');

    // Create GPA cache table
    await db.execute('''
      CREATE TABLE gpa_cache (
        id $idType,
        semester $textType,
        gpa $realType,
        lastUpdated $textType
      )
    ''');
  }

  // ==================== GRADE OPERATIONS ====================

  Future<int> insertGrade(Grade grade) async {
    final db = await database;
    final id = await db.insert('grades', grade.toMap());

    // Update GPA cache after inserting new grade
    await _updateGPACache(grade.semester);

    return id;
  }

  Future<List<Grade>> getAllGrades() async {
    final db = await database;
    final result = await db.query('grades', orderBy: 'date DESC');
    return result.map((map) => Grade.fromMap(map)).toList();
  }

  Future<Grade?> getGrade(int id) async {
    final db = await database;
    final maps = await db.query('grades', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Grade.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Grade>> getGradesByCourse(String courseCode) async {
    final db = await database;
    final result = await db.query(
      'grades',
      where: 'courseCode = ?',
      whereArgs: [courseCode],
      orderBy: 'date DESC',
    );
    return result.map((map) => Grade.fromMap(map)).toList();
  }

  Future<List<Grade>> getGradesBySemester(String semester) async {
    final db = await database;
    final result = await db.query(
      'grades',
      where: 'semester = ?',
      whereArgs: [semester],
      orderBy: 'date DESC',
    );
    return result.map((map) => Grade.fromMap(map)).toList();
  }

  Future<List<Grade>> getGradesByAssessmentType(String assessmentType) async {
    final db = await database;
    final result = await db.query(
      'grades',
      where: 'assessmentType = ?',
      whereArgs: [assessmentType],
      orderBy: 'date DESC',
    );
    return result.map((map) => Grade.fromMap(map)).toList();
  }

  Future<List<Grade>> searchGrades(String query) async {
    final db = await database;
    final result = await db.query(
      'grades',
      where: 'courseCode LIKE ? OR courseName LIKE ? OR assessmentType LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return result.map((map) => Grade.fromMap(map)).toList();
  }

  Future<int> updateGrade(Grade grade) async {
    final db = await database;
    final result = await db.update(
      'grades',
      grade.toMap(),
      where: 'id = ?',
      whereArgs: [grade.id],
    );

    // Update GPA cache after updating grade
    await _updateGPACache(grade.semester);

    return result;
  }

  Future<int> deleteGrade(int id) async {
    final db = await database;

    // Get grade to know which semester to update
    final grade = await getGrade(id);

    final result = await db.delete('grades', where: 'id = ?', whereArgs: [id]);

    // Update GPA cache after deleting grade
    if (grade != null) {
      await _updateGPACache(grade.semester);
    }

    return result;
  }

  // ==================== GPA CALCULATIONS ====================

  Future<double> calculateSemesterGPA(String semester) async {
    final grades = await getGradesBySemester(semester);

    if (grades.isEmpty) return 0.0;

    // Group by course
    Map<String, List<Grade>> courseGrades = {};
    for (var grade in grades) {
      if (!courseGrades.containsKey(grade.courseCode)) {
        courseGrades[grade.courseCode] = [];
      }
      courseGrades[grade.courseCode]!.add(grade);
    }

    double totalGradePoints = 0.0;
    int totalCredits = 0;

    for (var entry in courseGrades.entries) {
      final courseGradesList = entry.value;

      // Calculate average percentage for the course
      double totalPercentage = 0.0;
      for (var grade in courseGradesList) {
        totalPercentage += grade.percentage;
      }
      double avgPercentage = totalPercentage / courseGradesList.length;

      // Convert to grade point
      double gradePoint;
      if (avgPercentage >= 90) {
        gradePoint = 10.0;
      } else if (avgPercentage >= 80) {
        gradePoint = 9.0;
      } else if (avgPercentage >= 70) {
        gradePoint = 8.0;
      } else if (avgPercentage >= 60) {
        gradePoint = 7.0;
      } else if (avgPercentage >= 50) {
        gradePoint = 6.0;
      } else if (avgPercentage >= 45) {
        gradePoint = 5.0;
      } else if (avgPercentage >= 40) {
        gradePoint = 4.0;
      } else {
        gradePoint = 0.0;
      }

      final credits = courseGradesList.first.credits;
      totalGradePoints += gradePoint * credits;
      totalCredits += credits;
    }

    return totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;
  }

  Future<double> calculateOverallGPA() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT semester FROM grades ORDER BY semester',
    );

    if (result.isEmpty) return 0.0;

    double totalGPA = 0.0;
    int semesterCount = 0;

    for (var row in result) {
      final semester = row['semester'] as String;
      final gpa = await calculateSemesterGPA(semester);
      if (gpa > 0) {
        totalGPA += gpa;
        semesterCount++;
      }
    }

    return semesterCount > 0 ? totalGPA / semesterCount : 0.0;
  }

  Future<void> _updateGPACache(String semester) async {
    final db = await database;
    final gpa = await calculateSemesterGPA(semester);

    // Check if cache exists for this semester
    final existing = await db.query(
      'gpa_cache',
      where: 'semester = ?',
      whereArgs: [semester],
    );

    if (existing.isEmpty) {
      await db.insert('gpa_cache', {
        'semester': semester,
        'gpa': gpa,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'gpa_cache',
        {'gpa': gpa, 'lastUpdated': DateTime.now().toIso8601String()},
        where: 'semester = ?',
        whereArgs: [semester],
      );
    }
  }

  Future<Map<String, double>> getAllSemesterGPAs() async {
    final db = await database;
    final result = await db.query('gpa_cache', orderBy: 'semester');

    Map<String, double> gpaMap = {};
    for (var row in result) {
      gpaMap[row['semester'] as String] = row['gpa'] as double;
    }

    return gpaMap;
  }

  // ==================== DEADLINE OPERATIONS ====================

  Future<int> insertDeadline(ReEvaluationDeadline deadline) async {
    final db = await database;
    return await db.insert('deadlines', deadline.toMap());
  }

  Future<List<ReEvaluationDeadline>> getAllDeadlines() async {
    final db = await database;
    final result = await db.query(
      'deadlines',
      where: 'isCompleted = 0',
      orderBy: 'deadline ASC',
    );
    return result.map((map) => ReEvaluationDeadline.fromMap(map)).toList();
  }

  Future<ReEvaluationDeadline?> getNextDeadline() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'deadlines',
      where: 'deadline >= ? AND isCompleted = 0',
      whereArgs: [now],
      orderBy: 'deadline ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return ReEvaluationDeadline.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateDeadline(ReEvaluationDeadline deadline) async {
    final db = await database;
    return await db.update(
      'deadlines',
      deadline.toMap(),
      where: 'id = ?',
      whereArgs: [deadline.id],
    );
  }

  Future<int> deleteDeadline(int id) async {
    final db = await database;
    return await db.delete('deadlines', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<List<String>> getUniqueSemesters() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT semester FROM grades ORDER BY semester',
    );
    return result.map((row) => row['semester'] as String).toList();
  }

  Future<List<String>> getUniqueCourses() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT courseCode, courseName FROM grades ORDER BY courseCode',
    );
    return result
        .map((row) => '${row['courseCode']} - ${row['courseName']}')
        .toList();
  }

  Future<List<String>> getUniqueAssessmentTypes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT assessmentType FROM grades ORDER BY assessmentType',
    );
    return result.map((row) => row['assessmentType'] as String).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
