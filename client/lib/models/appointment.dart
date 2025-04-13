import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

@JsonSerializable()
class Appointment {
  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'user')
  final Map<String, dynamic>? userInfo;

  @JsonKey(name: 'doctor')
  final Map<String, dynamic> doctorInfo;

  final String hospitalName;

  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime appointmentDate;

  final String appointmentTime;

  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime createdAt;

  String get doctorId => doctorInfo['_id'] as String;
  String get doctorName {
    final name = doctorInfo['name'] as String?;
    if (name != null) {
      return name;
    }
    return 'N/A';
  }

  String? get userId => userInfo?['_id'] as String?;
  String get userName {
    if (userInfo != null) {
      final username = userInfo!['username'] as String?;
      if (username != null) {
        return username;
      }
    }
    return 'N/A';
  }

  String get doctorSpecialty => doctorInfo['specialty'] as String? ?? 'N/A';
  String get doctorHospital =>
      doctorInfo['hospitalName'] as String? ?? hospitalName;

  Appointment({
    required this.id,
    this.userInfo,
    required this.doctorInfo,
    required this.hospitalName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.createdAt,
  });

  static DateTime _dateFromJson(String date) => DateTime.parse(date);
  static String _dateToJson(DateTime date) => date.toIso8601String();

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentToJson(this);
}
