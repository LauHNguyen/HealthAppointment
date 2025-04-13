// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
      id: json['_id'] as String,
      userInfo: json['user'] as Map<String, dynamic>?,
      doctorInfo: json['doctor'] as Map<String, dynamic>,
      hospitalName: json['hospitalName'] as String,
      appointmentDate:
          Appointment._dateFromJson(json['appointmentDate'] as String),
      appointmentTime: json['appointmentTime'] as String,
      createdAt: Appointment._dateFromJson(json['createdAt'] as String),
    );

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'user': instance.userInfo,
      'doctor': instance.doctorInfo,
      'hospitalName': instance.hospitalName,
      'appointmentDate': Appointment._dateToJson(instance.appointmentDate),
      'appointmentTime': instance.appointmentTime,
      'createdAt': Appointment._dateToJson(instance.createdAt),
    };
