import 'dart:convert';
import 'package:client/screen/Appointment_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AppointmentList extends StatefulWidget {
  final String userId;
  final String role;

  const AppointmentList({required this.userId, required this.role, Key? key})
      : super(key: key);

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  List<dynamic> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final String endpoint = widget.role == 'doctor'
          ? '${dotenv.env['LOCALHOST']}/appointment/doctor/${widget.userId}'
          : '${dotenv.env['LOCALHOST']}/appointment/user/${widget.userId}';

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        setState(() {
          appointments = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải lịch hẹn.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải lịch hẹn: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.role == 'doctor'
                ? 'Lịch hẹn của bác sĩ'
                : 'Lịch hẹn của bạn',
            style: TextStyle(color: Colors.white)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('Không có lịch hẹn nào.'))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final appointmentDate = appointment['appointmentDate'];
                    final appointmentTime = appointment['appointmentTime'];
                    final otherName = widget.role == 'doctor'
                        ? appointment['user']['name']
                        : appointment['doctor']['name'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                            'Ngày: ${formatDate(appointmentDate)}\nGiờ: $appointmentTime'),
                        subtitle: Text(widget.role == 'doctor'
                            ? 'Bệnh nhân: $otherName'
                            : 'Bác sĩ: $otherName'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetail(
                                  appointment: appointment,
                                  userRole: widget.role),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return date; // Trả về chuỗi gốc nếu không thể parse
    }
  }
}
