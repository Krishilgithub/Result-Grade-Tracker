class CourseGrade {
  final String courseCode;
  final String courseName;
  final String semester;
  final int credits;
  final List<Map<String, dynamic>> assessments; // List of all assessments
  final double finalGrade;
  final String letterGrade;
  final double gradePoint;

  CourseGrade({
    required this.courseCode,
    required this.courseName,
    required this.semester,
    required this.credits,
    required this.assessments,
    required this.finalGrade,
    required this.letterGrade,
    required this.gradePoint,
  });

  factory CourseGrade.fromGrades(
    String courseCode,
    String courseName,
    String semester,
    int credits,
    List<Map<String, dynamic>> assessments,
  ) {
    // Calculate weighted final grade if multiple assessments exist
    double totalPercentage = 0.0;
    double totalWeight = 0.0;

    for (var assessment in assessments) {
      double percentage =
          (assessment['obtainedMarks'] / assessment['maxMarks']) * 100;
      totalPercentage += percentage;
      totalWeight += 1.0;
    }

    double finalGrade = totalWeight > 0 ? totalPercentage / totalWeight : 0.0;

    // Calculate grade point
    double gradePoint;
    String letterGrade;

    if (finalGrade >= 90) {
      gradePoint = 10.0;
      letterGrade = 'O';
    } else if (finalGrade >= 80) {
      gradePoint = 9.0;
      letterGrade = 'A+';
    } else if (finalGrade >= 70) {
      gradePoint = 8.0;
      letterGrade = 'A';
    } else if (finalGrade >= 60) {
      gradePoint = 7.0;
      letterGrade = 'B+';
    } else if (finalGrade >= 50) {
      gradePoint = 6.0;
      letterGrade = 'B';
    } else if (finalGrade >= 45) {
      gradePoint = 5.0;
      letterGrade = 'C';
    } else if (finalGrade >= 40) {
      gradePoint = 4.0;
      letterGrade = 'D';
    } else {
      gradePoint = 0.0;
      letterGrade = 'F';
    }

    return CourseGrade(
      courseCode: courseCode,
      courseName: courseName,
      semester: semester,
      credits: credits,
      assessments: assessments,
      finalGrade: finalGrade,
      letterGrade: letterGrade,
      gradePoint: gradePoint,
    );
  }
}
