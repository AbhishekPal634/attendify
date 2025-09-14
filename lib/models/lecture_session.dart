import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { active, ended, scheduled }

class LectureSession {
  final String id;
  final String courseId;
  final String facultyId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? sessionToken;
  final GeoLocation? geofence;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime? endedAt;

  LectureSession({
    required this.id,
    required this.courseId,
    required this.facultyId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.sessionToken,
    this.geofence,
    required this.status,
    required this.createdAt,
    this.endedAt,
  });

  factory LectureSession.fromMap(Map<String, dynamic> map) {
    return LectureSession(
      id: map['id'] ?? '',
      courseId: map['courseId'] ?? '',
      facultyId: map['facultyId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionToken: map['sessionToken'],
      geofence: map['geofence'] != null
          ? GeoLocation.fromMap(map['geofence'] as Map<String, dynamic>)
          : null,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseId': courseId,
      'facultyId': facultyId,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'sessionToken': sessionToken,
      'geofence': geofence?.toMap(),
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    };
  }

  LectureSession copyWith({
    String? id,
    String? courseId,
    String? facultyId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? sessionToken,
    GeoLocation? geofence,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? endedAt,
  }) {
    return LectureSession(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      facultyId: facultyId ?? this.facultyId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionToken: sessionToken ?? this.sessionToken,
      geofence: geofence ?? this.geofence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  bool get isActive => status == SessionStatus.active;
  bool get isEnded => status == SessionStatus.ended;
  bool get isScheduled => status == SessionStatus.scheduled;

  String get statusDisplayName {
    switch (status) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.ended:
        return 'Ended';
      case SessionStatus.scheduled:
        return 'Scheduled';
    }
  }

  Duration get duration => endTime.difference(startTime);
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final double radius; // in meters

  GeoLocation({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory GeoLocation.fromMap(Map<String, dynamic> map) {
    return GeoLocation(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      radius: (map['radius'] ?? 100.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude, 'radius': radius};
  }

  GeoLocation copyWith({double? latitude, double? longitude, double? radius}) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }
}
