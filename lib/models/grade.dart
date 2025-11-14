class Grade {
  final int? id;
  final String courseCode;
  final String courseName;
  final String assessmentType; // Midterm, Final, Assignment, Quiz, etc.
  final double maxMarks;
  final double obtainedMarks;
  final DateTime date;
  final String? remarks;
  final String? marksheetPath; // Path to scanned marksheet
  final String semester;
  final int credits;

  Grade({
    this.id,
    required this.courseCode,
    required this.courseName,
    required this.assessmentType,
    required this.maxMarks,
    required this.obtainedMarks,
    required this.date,
    this.remarks,
    this.marksheetPath,
    required this.semester,
    required this.credits,
  });

  // Calculate percentage
  double get percentage => (obtainedMarks / maxMarks) * 100;

  // Calculate grade point based on percentage
  double get gradePoint {
    if (percentage >= 90) return 10.0;
    if (percentage >= 80) return 9.0;
    if (percentage >= 70) return 8.0;
    if (percentage >= 60) return 7.0;
    if (percentage >= 50) return 6.0;
    if (percentage >= 45) return 5.0;
    if (percentage >= 40) return 4.0;
    return 0.0;
  }

  // Get letter grade
  String get letterGrade {
    if (percentage >= 90) return 'O'; // Outstanding
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B+';
    if (percentage >= 50) return 'B';
    if (percentage >= 45) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCode': courseCode,
      'courseName': courseName,
      'assessmentType': assessmentType,
      'maxMarks': maxMarks,
      'obtainedMarks': obtainedMarks,
      'date': date.toIso8601String(),
      'remarks': remarks,
      'marksheetPath': marksheetPath,
      'semester': semester,
      'credits': credits,
    };
  }

  factory Grade.fromMap(Map<String, dynamic> map) {
    return Grade(
      id: map['id'],
      courseCode: map['courseCode'],
      courseName: map['courseName'],
      assessmentType: map['assessmentType'],
      maxMarks: map['maxMarks'],
      obtainedMarks: map['obtainedMarks'],
      date: DateTime.parse(map['date']),
      remarks: map['remarks'],
      marksheetPath: map['marksheetPath'],
      semester: map['semester'],
      credits: map['credits'],
    );
  }

  Grade copyWith({
    int? id,
    String? courseCode,
    String? courseName,
    String? assessmentType,
    double? maxMarks,
    double? obtainedMarks,
    DateTime? date,
    String? remarks,
    String? marksheetPath,
    String? semester,
    int? credits,
  }) {
    return Grade(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      assessmentType: assessmentType ?? this.assessmentType,
      maxMarks: maxMarks ?? this.maxMarks,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      date: date ?? this.date,
      remarks: remarks ?? this.remarks,
      marksheetPath: marksheetPath ?? this.marksheetPath,
      semester: semester ?? this.semester,
      credits: credits ?? this.credits,
    );
  }
}
