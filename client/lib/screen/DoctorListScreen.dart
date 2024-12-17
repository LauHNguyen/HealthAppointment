import 'dart:convert';
import 'package:client/screen/Appointment_screen.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DoctorListScreen extends StatefulWidget {
  final String hospitalName;

  DoctorListScreen({required this.hospitalName});

  @override
  _DoctorListScreenState createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final SecureStorageService storage = SecureStorageService();
  List<dynamic> doctors = []; // Danh sách bác sĩ
  String? selectedDistrict;
  String? selectedHospitalName;
  String? userId;

  @override
  void initState() {
    super.initState();
    filterDoctors();
    fetchUserId();
  }

  Future<void> fetchUserId() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }
      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/user/id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userId = data['userId'];
          print(userId); // Trích xuất giá trị userId
        });
      } else {
        throw Exception('Failed to get user ID');
      }
    } catch (e) {
      print("Error fetching User Id: $e");
    }
  }

  Future<void> filterDoctors() async {
    try {
      // Địa chỉ API
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }

      String url = '${dotenv.env['LOCALHOST']}/doctor/filter';

      // Tạo Map chứa các tham số query
      List<String> queryParams = [];

      queryParams
          .add('hospitalName=${Uri.encodeComponent('${widget.hospitalName}')}');

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      // Kiểm tra phản hồi
      if (response.statusCode == 200) {
        setState(() {
          doctors = json.decode(response.body);
          print(doctors); // Cập nhật danh sách bác sĩ
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  void navigateToDoctorDetail(dynamic doctor) {
    // if (userId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Appointment(
          userId: userId!,
          doctorId: doctor['_id'],
          doctorName: doctor['name'],
          hospitalName: doctor['hospitalName'],
          workingHoursStart: doctor['startTime'],
          workingHoursEnd: doctor['endTime'],
          workingDays: List<String>.from(doctor['workingDays'] ?? []),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bác sĩ tại ${widget.hospitalName}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: doctors.isNotEmpty
            ? ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return InkWell(
                    onTap: () => navigateToDoctorDetail(doctor),
                    child: Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.teal[100],
                              child: Icon(
                                Icons.person,
                                color: Colors.teal,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doctor['name'] ?? "Tên bác sĩ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.teal[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Chuyên khoa: ${doctor['specialty'] ?? 'Không rõ'}",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            : Center(child: Text("Không có bác sĩ tại bệnh viện này")),
      ),
    );
  }
}
