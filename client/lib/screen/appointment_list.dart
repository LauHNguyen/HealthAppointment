import 'dart:convert';
import 'package:client/screen/appointment_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AppointmentList extends StatefulWidget {
  final String userId;

  const AppointmentList({required this.userId});

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
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['LOCALHOST']}/appointment/user/${widget.userId}',
        ),
      );

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
        title: const Text('Lịch hẹn của bạn'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('Không có lịch hẹn nào.'))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final doctor = appointment['doctor'];
                    final hospital = appointment['hospitalName'];
                    final appointmentDate = appointment['appointmentDate'];
                    final appointmentTime = appointment['appointmentTime'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title:
                            //Text('${doctor['name']} (${doctor['specialty']})'),
                            Text(
                                'Ngày: ${formatDate(appointmentDate)}\nGiờ: $appointmentTime'),
                        //Text('Giờ: $appointmentTime'),
                        // subtitle: Column(
                        //   crossAxisAlignment: CrossAxisAlignment.start,
                        //   children: [
                        //     Text('Bệnh viện: $hospital'),
                        //     Text('Ngày: ${formatDate(appointmentDate)}'),
                        //     Text('Giờ: $appointmentTime'),
                        //   ],
                        // ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AppointmentDetail(appointment: appointment),
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
