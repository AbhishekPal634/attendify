import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/course_service.dart';
import '../models/course.dart';
import '../models/lecture_session.dart';
import '../models/attendance_record.dart';

class FacultyAttendancePage extends StatefulWidget {
  const FacultyAttendancePage({super.key});

  @override
  State<FacultyAttendancePage> createState() => _FacultyAttendancePageState();
}

class _FacultyAttendancePageState extends State<FacultyAttendancePage> {
  final CourseService _courseService = CourseService();
  List<Course> _courses = [];
  List<LectureSession> _sessions = [];
  List<AttendanceRecord> _attendanceRecords = [];
  List<Map<String, dynamic>> _studentDetails = [];

  Course? _selectedCourse;
  LectureSession? _selectedSession;
  AttendanceFilter _currentFilter = AttendanceFilter.all;
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

  Future<void> _loadSessions(String courseId) async {
    try {
      setState(() => _isLoading = true);
      final sessions = await _courseService.getCourseSessions(courseId);
      setState(() {
        _sessions = sessions;
        _selectedSession = null;
        _attendanceRecords = [];
        _studentDetails = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading sessions: $e')));
      }
    }
  }

  Future<void> _loadAttendance(String sessionId) async {
    try {
      setState(() => _isLoading = true);
      final records = await _courseService.getSessionAttendance(sessionId);
      final students = await _courseService.getCourseStudents(
        _selectedCourse!.id,
      );

      setState(() {
        _attendanceRecords = records;
        _studentDetails = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading attendance: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAttendanceContent(),
    );
  }

  Widget _buildAttendanceContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection Controls
          _buildSelectionControls(),

          if (_selectedCourse != null && _selectedSession != null) ...[
            const SizedBox(height: 24),
            _buildSessionInfo(),
            const SizedBox(height: 24),
            _buildAttendanceStats(),
            const SizedBox(height: 16),
            _buildFilterControls(),
            const SizedBox(height: 16),

            // Attendance Table
            Expanded(child: _buildAttendanceTable()),
          ] else ...[
            const SizedBox(height: 64),
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Class and Session',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // Course Selection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Class'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Course>(
                        value: _selectedCourse,
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
                          setState(() {
                            _selectedCourse = course;
                            _selectedSession = null;
                            _attendanceRecords = [];
                            _studentDetails = [];
                          });
                          if (course != null) {
                            _loadSessions(course.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Session Selection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Session'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LectureSession>(
                        value: _selectedSession,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a session',
                        ),
                        items: _sessions.map((session) {
                          return DropdownMenuItem(
                            value: session,
                            child: Text(
                              '${_formatDate(session.date)} - ${session.statusDisplayName}',
                            ),
                          );
                        }).toList(),
                        onChanged: _selectedCourse == null
                            ? null
                            : (session) {
                                setState(() {
                                  _selectedSession = session;
                                });
                                if (session != null) {
                                  _loadAttendance(session.id);
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    final session = _selectedSession!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Session Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.statusDisplayName,
                    style: TextStyle(
                      color: _getStatusColor(session.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.calendar_today, _formatDate(session.date)),
                const SizedBox(width: 16),
                _buildInfoChip(
                  Icons.access_time,
                  '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                ),
                if (session.sessionToken != null) ...[
                  const SizedBox(width: 16),
                  _buildInfoChip(Icons.key, 'Token: ${session.sessionToken}'),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final stats = AttendanceStats.fromRecords(_attendanceRecords);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total', stats.totalStudents, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Present', stats.presentCount, Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Absent', stats.absentCount, Colors.red),
                const SizedBox(width: 16),
                _buildStatCard('Pending', stats.pendingCount, Colors.orange),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats.attendancePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'Attendance Rate',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Row(
      children: [
        Text('Filter:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(width: 16),
        ...AttendanceFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilter = filter;
                });
              },
            ),
          );
        }),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _exportAttendance,
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  Widget _buildAttendanceTable() {
    final filteredRecords = _getFilteredRecords();

    if (filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_list, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No records match the current filter',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Card(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student Name')),
            DataColumn(label: Text('Student ID')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Timestamp')),
            DataColumn(label: Text('Actions')),
          ],
          rows: filteredRecords.map((record) {
            final student = _studentDetails.firstWhere(
              (s) => s['id'] == record.studentId,
              orElse: () => {'name': 'Unknown', 'email': ''},
            );

            return DataRow(
              cells: [
                DataCell(Text(student['name'] ?? 'Unknown')),
                DataCell(Text(student['email'] ?? '')),
                DataCell(_buildStatusChip(record.status)),
                DataCell(
                  Text(
                    record.markedAt != null
                        ? _formatDateTime(record.markedAt!)
                        : '-',
                  ),
                ),
                DataCell(_buildActionButtons(record)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color color;
    switch (status) {
      case AttendanceStatus.present:
        color = Colors.green;
        break;
      case AttendanceStatus.absent:
        color = Colors.red;
        break;
      case AttendanceStatus.pending:
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildActionButtons(AttendanceRecord record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: record.status != AttendanceStatus.present
              ? () => _markAttendance(record, AttendanceStatus.present)
              : null,
          tooltip: 'Mark Present',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: record.status != AttendanceStatus.absent
              ? () => _markAttendance(record, AttendanceStatus.absent)
              : null,
          tooltip: 'Mark Absent',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.checklist, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Select a class and session',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a class and session to view attendance records',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<AttendanceRecord> _getFilteredRecords() {
    switch (_currentFilter) {
      case AttendanceFilter.present:
        return _attendanceRecords.where((r) => r.isPresent).toList();
      case AttendanceFilter.absent:
        return _attendanceRecords.where((r) => r.isAbsent).toList();
      case AttendanceFilter.pending:
        return _attendanceRecords.where((r) => r.isPending).toList();
      case AttendanceFilter.all:
        return _attendanceRecords;
    }
  }

  Future<void> _markAttendance(
    AttendanceRecord record,
    AttendanceStatus status,
  ) async {
    try {
      await _courseService.markAttendance(record.id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance marked as ${status.toString().split('.').last}',
          ),
        ),
      );
      _loadAttendance(_selectedSession!.id);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error marking attendance: $e')));
    }
  }

  void _exportAttendance() {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Colors.green;
      case SessionStatus.ended:
        return Colors.grey;
      case SessionStatus.scheduled:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}

enum AttendanceFilter { all, present, absent, pending }

extension AttendanceFilterExtension on AttendanceFilter {
  String get displayName {
    switch (this) {
      case AttendanceFilter.all:
        return 'All';
      case AttendanceFilter.present:
        return 'Present Only';
      case AttendanceFilter.absent:
        return 'Absent Only';
      case AttendanceFilter.pending:
        return 'Pending Only';
    }
  }
}
