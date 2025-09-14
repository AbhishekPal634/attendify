import 'package:flutter/material.dart';
import '../services/course_service.dart';
import '../models/course.dart';

class FacultyStudentsPage extends StatefulWidget {
  const FacultyStudentsPage({super.key});

  @override
  State<FacultyStudentsPage> createState() => _FacultyStudentsPageState();
}

class _FacultyStudentsPageState extends State<FacultyStudentsPage> {
  final CourseService _courseService = CourseService();
  Course? _selectedCourse;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Course && _selectedCourse != args) {
      _selectedCourse = args;
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;

    try {
      setState(() => _isLoading = true);
      final students = await _courseService.getCourseStudents(
        _selectedCourse!.id,
      );
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCourse?.courseName ?? 'Students'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedCourse == null
          ? const Center(child: Text('No class selected'))
          : _buildStudentsContent(),
      floatingActionButton: _selectedCourse != null
          ? FloatingActionButton.extended(
              onPressed: _showAddStudentDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
            )
          : null,
    );
  }

  Widget _buildStudentsContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCourse!.courseName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Course ID: ${_selectedCourse!.courseId}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Semester: ${_selectedCourse!.semester}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_students.length} students',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Students List
          Row(
            children: [
              Text(
                'Enrolled Students',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Student'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No students enrolled',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add students by their email address',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return _buildStudentCard(student);
        },
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final faceRegistered = student['faceRegistered'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: faceRegistered ? Colors.green : Colors.orange,
          child: Icon(
            faceRegistered ? Icons.verified_user : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          student['name'] ?? 'Unknown Student',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student['email'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: faceRegistered
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    faceRegistered ? 'Face Registered' : 'Face Not Registered',
                    style: TextStyle(
                      fontSize: 12,
                      color: faceRegistered ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleStudentAction(action, student),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text(
                  'Remove from Class',
                  style: TextStyle(color: Colors.red),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _showStudentDetails(student),
      ),
    );
  }

  void _showAddStudentDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the student\'s email address:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Student Email',
                  hintText: 'student@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The student must already be registered in the system with the role "student".',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                _addStudent(context, formKey, emailController.text),
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  Future<void> _addStudent(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    String email,
  ) async {
    if (!formKey.currentState!.validate()) return;

    try {
      // Check if student is already enrolled
      final isAlreadyEnrolled = await _courseService.isStudentAlreadyEnrolled(
        _selectedCourse!.id,
        email.trim(),
      );

      if (isAlreadyEnrolled) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(
              content: Text('Student is already enrolled in this class'),
            ),
          );
        }
        return;
      }

      await _courseService.addStudentToCourse(
        _selectedCourse!.id,
        email.trim(),
      );

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully')),
        );
      }

      _loadStudents();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Error adding student: $e')));
      }
    }
  }

  void _handleStudentAction(String action, Map<String, dynamic> student) {
    switch (action) {
      case 'view':
        _showStudentDetails(student);
        break;
      case 'remove':
        _showRemoveStudentDialog(student);
        break;
    }
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['name'] ?? 'Student Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', student['email'] ?? 'N/A'),
            _buildDetailRow('Student ID', student['id'] ?? 'N/A'),
            _buildDetailRow(
              'Face Registration',
              (student['faceRegistered'] ?? false) ? 'Completed' : 'Pending',
            ),
            _buildDetailRow(
              'Account Created',
              student['createdAt'] != null
                  ? _formatDateTime(student['createdAt'])
                  : 'N/A',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showRemoveStudentDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Are you sure you want to remove "${student['name']}" from this class?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _removeStudent(context, student),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeStudent(
    BuildContext dialogContext,
    Map<String, dynamic> student,
  ) async {
    try {
      await _courseService.removeStudentFromCourse(
        _selectedCourse!.id,
        student['id'],
      );

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed successfully')),
        );
      }

      _loadStudents();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Error removing student: $e')));
      }
    }
  }

  String _formatDateTime(dynamic timestamp) {
    try {
      if (timestamp == null) return 'N/A';
      DateTime dateTime;
      if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        // Handle Firestore Timestamp
        dateTime = timestamp.toDate();
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
