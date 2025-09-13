// Dummy data for the dashboard
class DummyData {
  static const String studentName = "John Doe";
  static const String studentId = "ST2024001";
  static const double overallAttendance = 85.5;

  static const int totalClassesToday = 4;
  static const int attendedToday = 2;
  static const int pendingToday = 2;

  static const Map<String, dynamic> activeSession = {
    'subject': 'Data Structures',
    'faculty': 'Dr. Smith',
    'startTime': '14:00',
    'endTime': '15:30',
    'remainingMinutes': 15,
    'isActive': true,
  };

  static const List<Map<String, dynamic>> upcomingSessions = [
    {
      'subject': 'Mobile App Development',
      'faculty': 'Prof. Johnson',
      'startTime': '15:45',
      'endTime': '17:15',
      'status': 'Not started yet',
    },
    {
      'subject': 'Database Management',
      'faculty': 'Dr. Williams',
      'startTime': '17:30',
      'endTime': '19:00',
      'status': 'Not started yet',
    },
  ];

  static const List<Map<String, dynamic>> criticalSubjects = [
    {'subject': 'Operating Systems', 'attendance': 68.5},
    {'subject': 'Computer Networks', 'attendance': 72.0},
  ];
}
