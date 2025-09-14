import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/course_service.dart';
import '../models/course.dart';
import '../models/lecture_session.dart';

class FacultySchedulePage extends StatefulWidget {
  const FacultySchedulePage({super.key});

  @override
  State<FacultySchedulePage> createState() => _FacultySchedulePageState();
}

class _FacultySchedulePageState extends State<FacultySchedulePage> {
  final CourseService _courseService = CourseService();
  List<Course> _courses = [];
  List<LectureSession> _activeSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final facultyId = FirebaseAuth.instance.currentUser?.uid;
      if (facultyId != null) {
        final courses = await _courseService.getFacultyCourses(facultyId);
        final activeSessions = await _courseService.getFacultyActiveSessions(
          facultyId,
        );
        setState(() {
          _courses = courses;
          _activeSessions = activeSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildScheduleContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _courses.isNotEmpty ? _showScheduleLectureDialog : null,
        icon: const Icon(Icons.add),
        label: const Text('Schedule Lecture'),
      ),
    );
  }

  Widget _buildScheduleContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Sessions Section
          Text(
            'Active Sessions',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildActiveSessionsList(),

          const SizedBox(height: 32),

          // Schedule New Lecture Section
          Row(
            children: [
              Text(
                'Schedule New Lecture',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _courses.isNotEmpty
                    ? _showScheduleLectureDialog
                    : null,
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule'),
              ),
            ],
          ),

          if (_courses.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.class_, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No classes available',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a class first to schedule lectures',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveSessionsList() {
    if (_activeSessions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.schedule, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No active sessions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a lecture session to see it here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _activeSessions.length,
        itemBuilder: (context, index) {
          final session = _activeSessions[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: _buildActiveSessionCard(session),
          );
        },
      ),
    );
  }

  Widget _buildActiveSessionCard(LectureSession session) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Token: ${session.sessionToken}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Course?>(
              future: _courseService.getCourse(session.courseId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final courseName = snapshot.data?.courseName ?? 'Course';
                return Text(
                  courseName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Started: ${_formatTime(session.startTime)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Ends: ${_formatTime(session.endTime)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _endSession(session),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'End Session',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleLectureDialog() {
    final formKey = GlobalKey<FormState>();
    Course? selectedCourse;
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
      hour: TimeOfDay.now().hour + 1,
      minute: TimeOfDay.now().minute,
    );
    double? latitude;
    double? longitude;
    double radius = 100;
    bool useGeofence = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Lecture'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Selection
                    const Text('Select Class'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Course>(
                      value: selectedCourse,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose a class',
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem(
                          value: course,
                          child: Text(
                            '${course.courseName} (${course.courseId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (course) {
                        setDialogState(() {
                          selectedCourse = course;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a class';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date Selection
                    const Text('Date'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setDialogState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Text(_formatDate(selectedDate)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: startTime,
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      startTime = time;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time),
                                      const SizedBox(width: 8),
                                      Text(startTime.format(context)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time'),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: endTime,
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      endTime = time;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time),
                                      const SizedBox(width: 8),
                                      Text(endTime.format(context)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Geofence Option
                    CheckboxListTile(
                      title: const Text('Enable Geofence'),
                      subtitle: const Text(
                        'Restrict attendance to a specific location',
                      ),
                      value: useGeofence,
                      onChanged: (value) {
                        setDialogState(() {
                          useGeofence = value ?? false;
                        });
                      },
                    ),

                    if (useGeofence) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                latitude = double.tryParse(value);
                              },
                              validator: useGeofence
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                longitude = double.tryParse(value);
                              },
                              validator: useGeofence
                                  ? (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Radius (meters)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: radius.toString(),
                        onChanged: (value) {
                          radius = double.tryParse(value) ?? 100;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _createSession(
                context,
                formKey,
                selectedCourse,
                selectedDate,
                startTime,
                endTime,
                useGeofence
                    ? GeoLocation(
                        latitude: latitude!,
                        longitude: longitude!,
                        radius: radius,
                      )
                    : null,
              ),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createSession(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    Course? selectedCourse,
    DateTime selectedDate,
    TimeOfDay startTime,
    TimeOfDay endTime,
    GeoLocation? geofence,
  ) async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCourse == null) {
      ScaffoldMessenger.of(
        dialogContext,
      ).showSnackBar(const SnackBar(content: Text('Please select a class')));
      return;
    }

    try {
      final facultyId = FirebaseAuth.instance.currentUser?.uid;
      if (facultyId == null) throw Exception('User not authenticated');

      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime.hour,
        startTime.minute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime.hour,
        endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }

      final session = LectureSession(
        id: '', // Will be set by Firestore
        courseId: selectedCourse.id,
        facultyId: facultyId,
        date: selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        geofence: geofence,
        status: SessionStatus.scheduled,
        createdAt: DateTime.now(),
      );

      await _courseService.createSession(session);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture scheduled successfully')),
        );
      }

      _loadData();
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text('Error scheduling lecture: $e')));
      }
    }
  }

  Future<void> _endSession(LectureSession session) async {
    try {
      await _courseService.endSession(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ended successfully')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error ending session: $e')));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
