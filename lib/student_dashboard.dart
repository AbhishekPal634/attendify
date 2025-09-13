import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/custom_button.dart';
import 'facial_verification_page.dart';
import 'profile_page.dart';
import 'services/firestore_service.dart';
import 'models/student.dart' as student_model;
import 'models/session.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  student_model.Student? _currentStudent;
  List<Session> _todaySessions = [];
  List<Session> _activeSessions = [];
  List<Session> _upcomingSessions = [];
  Map<String, double> _attendancePercentages = {};
  double _overallAttendance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }

      print('👤 Loading dashboard for user: ${user.email}');

      // Get current student data (creates dummy data if none exists)
      final student = await _firestoreService.getOrCreateStudentByEmail(
        user.email!,
        user.displayName ?? 'Student',
      );

      if (student == null) {
        print('❌ Failed to get or create student data');
        return;
      }

      print('✅ Student loaded successfully: ${student.name}');

      // Get sessions data
      final allSessions = await _firestoreService.getStudentSessions(
        student.id,
      );
      final activeSessions = await _firestoreService.getActiveSessions(
        student.id,
      );

      // Filter today's sessions
      final today = DateTime.now();
      final todaySessions = allSessions.where((session) {
        return session.startTime.year == today.year &&
            session.startTime.month == today.month &&
            session.startTime.day == today.day;
      }).toList();

      // Filter upcoming sessions (next 7 days)
      final weekFromNow = today.add(const Duration(days: 7));
      final upcomingSessions = allSessions.where((session) {
        return session.startTime.isAfter(today) &&
            session.startTime.isBefore(weekFromNow) &&
            session.status == 'scheduled';
      }).toList();

      // Get attendance data
      final attendancePercentages = await _firestoreService
          .getAttendancePercentage(student.id);
      final overallAttendance = await _firestoreService
          .getOverallAttendancePercentage(student.id);

      setState(() {
        _currentStudent = student;
        _todaySessions = todaySessions;
        _activeSessions = activeSessions;
        _upcomingSessions = upcomingSessions;
        _attendancePercentages = attendancePercentages;
        _overallAttendance = overallAttendance;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentStudent == null) {
      return const Scaffold(
        body: Center(child: Text('Student data not found')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header / Top Bar
              _buildHeader(context),

              // Dashboard Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Summary
                    _buildTodaysSummary(),

                    const SizedBox(height: 20),

                    // Active Session Section
                    if (_activeSessions.isNotEmpty)
                      _buildActiveSession(context),

                    const SizedBox(height: 20),

                    // Upcoming Sessions
                    _buildUpcomingSessions(),

                    const SizedBox(height: 20),

                    // Quick Analytics
                    _buildQuickAnalytics(),

                    const SizedBox(height: 20),

                    // Quick Links
                    _buildQuickLinks(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  _currentStudent?.name ?? 'Student',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'ID: ${_currentStudent?.studentId ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 24,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSummary() {
    final totalClassesToday = _todaySessions.length;
    final attendedToday = _todaySessions
        .where(
          (session) => session.attendedStudents.contains(_currentStudent?.id),
        )
        .length;
    final pendingToday = totalClassesToday - attendedToday;

    return _buildCard(
      title: "Today's Summary",
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Classes',
                  totalClassesToday.toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Attended',
                  attendedToday.toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  pendingToday.toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overall Attendance: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '${_overallAttendance.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSession(BuildContext context) {
    if (_activeSessions.isEmpty) return const SizedBox();

    final session = _activeSessions.first;
    return _buildCard(
      title: "Active Session",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${session.remainingMinutes} min left',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.subjectName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            session.facultyName,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${session.formattedStartTime} - ${session.formattedEndTime}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Mark Attendance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FacialVerificationPage(
                    subjectName: session.subjectName,
                    facultyName: session.facultyName,
                  ),
                ),
              );
            },
            backgroundColor: Colors.green,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessions() {
    return _buildCard(
      title: "Upcoming Sessions",
      child: _upcomingSessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No upcoming sessions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          : Column(
              children: _upcomingSessions.map((session) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.subjectName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.facultyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${session.formattedStartTime} - ${session.formattedEndTime}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          session.status,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildQuickAnalytics() {
    // Get critical subjects (attendance < 75%)
    final criticalSubjects = _attendancePercentages.entries
        .where((entry) => entry.value < 75.0)
        .toList();

    return _buildCard(
      title: "Quick Analytics",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${_overallAttendance.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (criticalSubjects.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: Colors.red[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Critical Subjects',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...criticalSubjects.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All subjects have good attendance!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks() {
    return _buildCard(
      title: "Quick Links",
      child: Column(
        children: [
          _buildQuickLinkItem(
            icon: Icons.history,
            title: 'History',
            subtitle: 'View detailed past records',
            onTap: () {
              // TODO: Navigate to history page
            },
          ),
          const SizedBox(height: 12),
          _buildQuickLinkItem(
            icon: Icons.support_agent,
            title: 'Requests',
            subtitle: 'Raise issue or correction',
            onTap: () {
              // TODO: Navigate to requests page
            },
          ),
          const SizedBox(height: 12),
          _buildQuickLinkItem(
            icon: Icons.analytics,
            title: 'Analytics',
            subtitle: 'Full detailed statistics',
            onTap: () {
              // TODO: Navigate to analytics page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinkItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
