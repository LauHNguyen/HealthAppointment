import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class DoctorInfo extends StatefulWidget {
  @override
  _DoctorProfile createState() => _DoctorProfile();
}

class _DoctorProfile extends State<DoctorInfo> {
  final SecureStorageService storage = SecureStorageService();
  Map<String, dynamic>? doctorData;
  var WorkDay;
  bool _isLoading = true;

  List<String> weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  Future<void> _fetchDoctorInfo() async {
    String? token = await storage.getAccessToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('${dotenv.env['LOCALHOST']}/doctor/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        doctorData = json.decode(response.body);
        print(doctorData);
        WorkDay = doctorData?['workingDays'];
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load doctor info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Thông Tin Bác Sĩ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent], // Các màu gradient
              begin: Alignment.topLeft, // Hướng gradient bắt đầu
              end: Alignment.bottomRight, // Hướng gradient kết thúc
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : doctorData == null
              ? Center(
                  child: Text(
                    'Không có dữ liệu bác sĩ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20),

                        // Username
                        Text(
                          'Tên bác sĩ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          initialValue: doctorData?['name'],
                          enabled: false, // Không cho phép chỉnh sửa
                          style: TextStyle(color: Colors.grey[700]), // Màu chữ
                        ),

                        Text(
                          'Làm việc tại',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          initialValue: doctorData?['hospitalName'],
                          enabled: false, // Không cho phép chỉnh sửa
                          style: TextStyle(color: Colors.grey[700]), // Màu chữ
                        ),

                        Text(
                          'Chuyên khoa',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          initialValue: doctorData?['specialty'],
                          enabled: false, // Không cho phép chỉnh sửa
                          style: TextStyle(color: Colors.grey[700]), // Màu chữ
                        ),
                        Text(
                          'Thời gian làm việc',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextFormField(
                          initialValue:
                              'Bắt đầu: ${doctorData?['startTime']} --- Kết thúc:${doctorData?['endTime']}',
                          enabled: false, // Không cho phép chỉnh sửa
                          style: TextStyle(color: Colors.grey[700]), // Màu chữ
                        ),

                        Text(
                          'Ngày làm việc trong tuần',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              (doctorData?['workingDays'] as List<dynamic>)
                                  .map((day) => Chip(
                                        label: Text(
                                          day,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.teal,
                                      ))
                                  .toList(),
                        ),
                        SizedBox(height: 20),

                        // Update Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/docupdate');
                          },
                          child: Text(
                            'Cập Nhật Thông Tin',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
