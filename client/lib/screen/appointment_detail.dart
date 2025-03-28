import 'dart:convert';

import 'package:client/screen/Appointment_edit.dart';
import 'package:client/screen/appointment_list.dart';
import 'package:client/screen/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AppointmentDetail extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final String userRole;

  const AppointmentDetail({
    required this.appointment,
    required this.userRole,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final doctor = appointment['doctor'];
    final user = appointment['user'];
    final hospital = appointment['hospitalName'];
    final appointmentDate = appointment['appointmentDate'];
    final appointmentTime = appointment['appointmentTime'];

    bool isAppointmentUpcoming(String appointmentDate, String appointmentTime) {
      try {
        final DateTime date = DateTime.parse(appointmentDate);
        final String startTime = appointmentTime.split(' - ')[0];
        final List<String> timeParts = startTime.split(':');
        final DateTime appointmentEndDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
        return appointmentEndDateTime.isAfter(DateTime.now());
      } catch (e) {
        print('Lỗi khi kiểm tra thời gian: $e');
        return false;
      }
    }

    final bool canModify = isAppointmentUpcoming(
          appointment['appointmentDate'],
          appointment['appointmentTime'],
        ) &&
        userRole == 'user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch hẹn',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent], // Các màu gradient
              begin: Alignment.topLeft, // Hướng gradient bắt đầu
              end: Alignment.bottomRight, // Hướng gradient kết thúc
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bác sĩ: ${doctor['name']} (${doctor['specialty']})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bệnh nhân: ${user['name']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bệnh viện: $hospital',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const Divider(height: 20),
                            Text(
                              'Ngày: ${formatDate(appointmentDate)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Giờ: $appointmentTime',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (userRole == 'user') ...[
                      if (canModify) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _cancelAppointment(context),
                                icon: const Icon(Icons.cancel_outlined),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                                label: const Text('Hủy lịch hẹn'),
                              ),
                            ),
                            const SizedBox(
                                width: 10), // Khoảng cách giữa hai nút
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditAppointment(
                                        appointment: appointment,
                                        doctorId: doctor['_id'],
                                        doctorName: doctor['name'],
                                        hospitalName: hospital,
                                        workingHoursStart: doctor['startTime'],
                                        workingHoursEnd: doctor['endTime'],
                                        workingDays: List<String>.from(
                                            doctor['workingDays']),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                ),
                                label: const Text('Chỉnh sửa lịch hẹn'),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        const Text(
                          'Bạn không thể hủy hoặc chỉnh sửa lịch hẹn đã qua.',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                    if (userRole == 'doctor')
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _confirmAppointment(context),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Xác nhận đã khám'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      userId: userRole == 'user'
                          ? appointment['user']['_id']
                          : doctor['_id'],
                      doctorId: userRole == 'doctor'
                          ? appointment['user']['_id']
                          : doctor['_id'],
                      userRole: userRole,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message_outlined),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              label: Text(userRole == 'user'
                  ? 'Nhắn tin với bác sĩ'
                  : 'Nhắn tin với bệnh nhân'),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  void _cancelAppointment(BuildContext context) async {
    final appointmentId = appointment['_id'];

    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['LOCALHOST']}/appointment/$appointmentId'),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/home');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lịch hẹn đã được hủy thành công.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hủy lịch hẹn thất bại: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  void _editAppointment(
      BuildContext context, Map<String, dynamic> appointment) async {
    final appointmentId = appointment['_id'];

    try {
      final response = await http.patch(
        Uri.parse('${dotenv.env['LOCALHOST']}/appointment/$appointmentId'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lịch hẹn đã được chỉnh sửa thành công.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Chỉnh sửa lịch hẹn thất bại: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  void _confirmAppointment(BuildContext context) async {
    final appointmentId = appointment['_id'];
    final appointmentStatus = appointment['status'];
    final doctorId = appointment['doctor'];
    try {
      final response = await http.patch(
        Uri.parse(
            '${dotenv.env['LOCALHOST']}/appointment/$appointmentId/status'),
        body: jsonEncode({'status': appointmentStatus == false ? true : false}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentList(
              userId: doctorId['_id'],
              role: userRole,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(appointmentStatus == false
                  ? 'Xác nhận thành công.'
                  : 'Hủy xác nhận thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Không thể thực hiện : ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }
}
