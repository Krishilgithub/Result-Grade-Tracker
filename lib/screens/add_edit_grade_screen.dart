import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/grade.dart';
import '../providers/grade_provider.dart';

class AddEditGradeScreen extends StatefulWidget {
  final Grade? grade;

  const AddEditGradeScreen({Key? key, this.grade}) : super(key: key);

  @override
  State<AddEditGradeScreen> createState() => _AddEditGradeScreenState();
}

class _AddEditGradeScreenState extends State<AddEditGradeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _courseCodeController;
  late TextEditingController _courseNameController;
  late TextEditingController _maxMarksController;
  late TextEditingController _obtainedMarksController;
  late TextEditingController _remarksController;
  late TextEditingController _creditsController;

  String _selectedAssessmentType = 'Midterm';
  String _selectedSemester = 'Semester 1';
  DateTime _selectedDate = DateTime.now();
  String? _marksheetPath;

  final List<String> _assessmentTypes = [
    'Midterm',
    'Final',
    'Assignment',
    'Quiz',
    'Project',
    'Practical',
    'Lab',
    'Viva',
  ];

  @override
  void initState() {
    super.initState();

    _courseCodeController = TextEditingController(
      text: widget.grade?.courseCode ?? '',
    );
    _courseNameController = TextEditingController(
      text: widget.grade?.courseName ?? '',
    );
    _maxMarksController = TextEditingController(
      text: widget.grade?.maxMarks.toString() ?? '',
    );
    _obtainedMarksController = TextEditingController(
      text: widget.grade?.obtainedMarks.toString() ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.grade?.remarks ?? '',
    );
    _creditsController = TextEditingController(
      text: widget.grade?.credits.toString() ?? '3',
    );

    if (widget.grade != null) {
      _selectedAssessmentType = widget.grade!.assessmentType;
      _selectedSemester = widget.grade!.semester;
      _selectedDate = widget.grade!.date;
      _marksheetPath = widget.grade!.marksheetPath;
    }
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _maxMarksController.dispose();
    _obtainedMarksController.dispose();
    _remarksController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.grade != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Grade' : 'Add Grade'),
        actions: [
          if (isEditing)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteGrade),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Course Information Section
            _buildSectionTitle('Course Information'),
            const SizedBox(height: 8),

            TextFormField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter course code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Course Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter course name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _creditsController,
              decoration: const InputDecoration(
                labelText: 'Credits',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_score),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter credits';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter valid credits';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Assessment Details Section
            _buildSectionTitle('Assessment Details'),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedAssessmentType,
              decoration: const InputDecoration(
                labelText: 'Assessment Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assessment),
              ),
              items: _assessmentTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAssessmentType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                labelText: 'Semester',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_view_month),
              ),
              items: List.generate(8, (index) {
                return DropdownMenuItem(
                  value: 'Semester ${index + 1}',
                  child: Text('Semester ${index + 1}'),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),

            // Marks Section
            _buildSectionTitle('Marks'),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxMarksController,
                    decoration: const InputDecoration(
                      labelText: 'Max Marks',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.stars),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _obtainedMarksController,
                    decoration: const InputDecoration(
                      labelText: 'Obtained Marks',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final obtained = double.tryParse(value);
                      if (obtained == null) {
                        return 'Invalid';
                      }
                      final max = double.tryParse(_maxMarksController.text);
                      if (max != null && obtained > max) {
                        return 'Exceeds max';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Show calculated percentage and grade
            if (_maxMarksController.text.isNotEmpty &&
                _obtainedMarksController.text.isNotEmpty)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultIndicator(
                        'Percentage',
                        '${_calculatePercentage().toStringAsFixed(2)}%',
                      ),
                      _buildResultIndicator('Grade', _calculateLetterGrade()),
                      _buildResultIndicator(
                        'Grade Point',
                        _calculateGradePoint().toStringAsFixed(1),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Additional Information Section
            _buildSectionTitle('Additional Information'),
            const SizedBox(height: 8),

            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Marksheet Upload
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file),
              title: const Text('Scanned Marksheet'),
              subtitle: Text(_marksheetPath ?? 'No file selected'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_marksheetPath != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _marksheetPath = null;
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.upload_file),
                    onPressed: _pickFile,
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveGrade,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                isEditing ? 'Update Grade' : 'Add Grade',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildResultIndicator(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  double _calculatePercentage() {
    final max = double.tryParse(_maxMarksController.text) ?? 0;
    final obtained = double.tryParse(_obtainedMarksController.text) ?? 0;
    if (max == 0) return 0;
    return (obtained / max) * 100;
  }

  String _calculateLetterGrade() {
    final percentage = _calculatePercentage();
    if (percentage >= 90) return 'O';
    if (percentage >= 80) return 'A+';
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B+';
    if (percentage >= 50) return 'B';
    if (percentage >= 45) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  double _calculateGradePoint() {
    final percentage = _calculatePercentage();
    if (percentage >= 90) return 10.0;
    if (percentage >= 80) return 9.0;
    if (percentage >= 70) return 8.0;
    if (percentage >= 60) return 7.0;
    if (percentage >= 50) return 6.0;
    if (percentage >= 45) return 5.0;
    if (percentage >= 40) return 4.0;
    return 0.0;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _marksheetPath = result.files.single.path;
      });
    }
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<GradeProvider>(context, listen: false);

    final grade = Grade(
      id: widget.grade?.id,
      courseCode: _courseCodeController.text.trim(),
      courseName: _courseNameController.text.trim(),
      assessmentType: _selectedAssessmentType,
      maxMarks: double.parse(_maxMarksController.text),
      obtainedMarks: double.parse(_obtainedMarksController.text),
      date: _selectedDate,
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
      marksheetPath: _marksheetPath,
      semester: _selectedSemester,
      credits: int.parse(_creditsController.text),
    );

    try {
      if (widget.grade == null) {
        await provider.addGrade(grade);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grade added successfully')),
          );
        }
      } else {
        await provider.updateGrade(grade);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grade updated successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _deleteGrade() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Grade'),
        content: const Text('Are you sure you want to delete this grade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.grade != null) {
      final provider = Provider.of<GradeProvider>(context, listen: false);
      await provider.deleteGrade(widget.grade!.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade deleted successfully')),
        );
        Navigator.pop(context);
      }
    }
  }
}
