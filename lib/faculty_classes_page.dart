import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/course_service.dart';
import '../models/course.dart';

class FacultyClassesPage extends StatefulWidget {
  const FacultyClassesPage({super.key});

  @override
  State<FacultyClassesPage> createState() => _FacultyClassesPageState();
}

class _FacultyClassesPageState extends State<FacultyClassesPage> {
  final CourseService _courseService = CourseService();
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() => _isLoading = true);
      final facultyId = FirebaseAuth.instance.currentUser?.uid;
      if (facultyId != null) {
        final courses = await _courseService.getFacultyCourses(facultyId);
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading courses: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildClassesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClassDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create New Class'),
      ),
    );
  }

  Widget _buildClassesList() {
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.class_, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No classes created yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first class to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCourses,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Classes (${_courses.length})',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 800
                      ? 3
                      : 1,
                  childAspectRatio: MediaQuery.of(context).size.width > 800
                      ? 3
                      : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return _buildClassCard(course);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(Course course) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _navigateToStudents(course),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Course ID: ${course.courseId}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleClassAction(action, course),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'students',
                        child: ListTile(
                          leading: Icon(Icons.people),
                          title: Text('View Students'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Class'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete Class',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    course.semester,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.studentCount} students',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToStudents(course),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateClassDialog() {
    final formKey = GlobalKey<FormState>();
    final courseNameController = TextEditingController();
    final courseIdController = TextEditingController();
    final semesterController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    hintText: 'e.g., Data Structures and Algorithms',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Course name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: courseIdController,
                  decoration: const InputDecoration(
                    labelText: 'Course ID',
                    hintText: 'e.g., CS201',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Course ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: semesterController,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    hintText: 'e.g., Fall 2024',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Semester is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createClass(
              context,
              formKey,
              courseNameController.text,
              courseIdController.text,
              semesterController.text,
            ),
            child: const Text('Create Class'),
          ),
        ],
      ),
    );
  }

  Future<void> _createClass(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    String courseName,
    String courseId,
    String semester,
  ) async {
    if (!formKey.currentState!.validate()) return;

    try {
      final facultyId = FirebaseAuth.instance.currentUser?.uid;
      if (facultyId == null) throw Exception('User not authenticated');

      // Check if course ID is unique for this faculty
      final isUnique = await _courseService.isCourseIdUnique(
        courseId,
        facultyId,
      );
      if (!isUnique) {
        if (dialogContext.mounted) {
          ScaffoldMessenger.of(dialogContext).showSnackBar(
            const SnackBar(content: Text('Course ID already exists')),
          );
        }
        return;
      }

      final course = Course(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courseId: courseId.trim(),
        courseName: courseName.trim(),
        semester: semester.trim(),
        facultyId: facultyId,
        enrolledStudentIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _courseService.createCourse(course);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class created successfully')),
        );
      }

      _loadCourses();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Error creating class: $e')));
      }
    }
  }

  void _handleClassAction(String action, Course course) {
    switch (action) {
      case 'students':
        _navigateToStudents(course);
        break;
      case 'edit':
        _showEditClassDialog(course);
        break;
      case 'delete':
        _showDeleteConfirmation(course);
        break;
    }
  }

  void _navigateToStudents(Course course) {
    Navigator.pushNamed(context, '/faculty-students', arguments: course);
  }

  void _showEditClassDialog(Course course) {
    final formKey = GlobalKey<FormState>();
    final courseNameController = TextEditingController(text: course.courseName);
    final courseIdController = TextEditingController(text: course.courseId);
    final semesterController = TextEditingController(text: course.semester);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Class'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: courseNameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Course name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: courseIdController,
                  decoration: const InputDecoration(
                    labelText: 'Course ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Course ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: semesterController,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Semester is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateClass(
              context,
              formKey,
              course,
              courseNameController.text,
              courseIdController.text,
              semesterController.text,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateClass(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    Course originalCourse,
    String courseName,
    String courseId,
    String semester,
  ) async {
    if (!formKey.currentState!.validate()) return;

    try {
      final updatedCourse = originalCourse.copyWith(
        courseName: courseName.trim(),
        courseId: courseId.trim(),
        semester: semester.trim(),
        updatedAt: DateTime.now(),
      );

      await _courseService.updateCourse(updatedCourse);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class updated successfully')),
        );
      }

      _loadCourses();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Error updating class: $e')));
      }
    }
  }

  void _showDeleteConfirmation(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete "${course.courseName}"?\n\n'
          'This will also delete all associated sessions and attendance records. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteClass(context, course),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(BuildContext dialogContext, Course course) async {
    try {
      await _courseService.deleteCourse(course.id);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      }

      _loadCourses();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Error deleting class: $e')));
      }
    }
  }
}
