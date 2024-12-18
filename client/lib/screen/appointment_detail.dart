import 'package:client/screen/Appointment_edit.dart';
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
    final hospital = appointment['hospitalName'];
    final appointmentDate = appointment['appointmentDate'];
    final appointmentTime = appointment['appointmentTime'];

    // Parse ngày và giờ hẹn
    bool isAppointmentUpcoming(String appointmentDate, String appointmentTime) {
      try {
        // Parse ngày từ chuỗi ISO-8601
        final DateTime date = DateTime.parse(appointmentDate);

        final String startTime = appointmentTime.split(' - ')[0];
        final List<String> timeParts = startTime.split(':');

        // Tạo DateTime hoàn chỉnh (ngày + giờ kết thúc)
        final DateTime appointmentEndDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]), // Giờ
          int.parse(timeParts[1]), // Phút
        );

        // So sánh với thời gian hiện tại
        return appointmentEndDateTime.isAfter(DateTime.now());
      } catch (e) {
        // Xử lý lỗi (nếu dữ liệu không hợp lệ)
        print('Lỗi khi kiểm tra thời gian: $e');
        return false;
      }
    }

    // Kiểm tra nếu lịch hẹn chưa qua
    final bool canModify = isAppointmentUpcoming(
          appointment['appointmentDate'],
          appointment['appointmentTime'],
        ) &&
        userRole == 'user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch hẹn'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bác sĩ: ${doctor['name']} (${doctor['specialty']})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Bệnh viện: $hospital'),
                    const SizedBox(height: 8),
                    Text('Ngày: ${formatDate(appointmentDate)}'),
                    const SizedBox(height: 8),
                    Text('Giờ: $appointmentTime'),
                    if (userRole == 'user') ...[
                      if (canModify) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _cancelAppointment(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text('Hủy lịch hẹn'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
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
                                  workingDays:
                                      List<String>.from(doctor['workingDays']),
                                ),
                              ),
                            );
                          },
                          child: const Text('Chỉnh sửa lịch hẹn'),
                        ),
                      ] else
                        const Text(
                          'Bạn không thể hủy hoặc chỉnh sửa lịch hẹn đã qua.',
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: Text(userRole == 'user'
                    ? 'Nhắn tin với bác sĩ'
                    : 'Nhắn tin với bệnh nhân'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                  print(
                      'Mở chức năng nhắn tin với ${userRole == 'user' ? 'bác sĩ' : 'bệnh nhân'} ${userRole == 'user' ? doctor['name'] : appointment['user']['username']}');
                },
              ),
            ),
          ),
        ],
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
}
