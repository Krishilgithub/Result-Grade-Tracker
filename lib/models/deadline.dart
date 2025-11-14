class ReEvaluationDeadline {
  final int? id;
  final String courseCode;
  final DateTime deadline;
  final String? description;
  final bool isCompleted;

  ReEvaluationDeadline({
    this.id,
    required this.courseCode,
    required this.deadline,
    this.description,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCode': courseCode,
      'deadline': deadline.toIso8601String(),
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory ReEvaluationDeadline.fromMap(Map<String, dynamic> map) {
    return ReEvaluationDeadline(
      id: map['id'],
      courseCode: map['courseCode'],
      deadline: DateTime.parse(map['deadline']),
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
    );
  }

  int get daysUntilDeadline {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays;
  }

  ReEvaluationDeadline copyWith({
    int? id,
    String? courseCode,
    DateTime? deadline,
    String? description,
    bool? isCompleted,
  }) {
    return ReEvaluationDeadline(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
