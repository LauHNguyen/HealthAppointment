import 'dart:convert';

import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UpdateDoctorInfo extends StatefulWidget {
  @override
  _UpdateDoctorInfoState createState() => _UpdateDoctorInfoState();
}

class _UpdateDoctorInfoState extends State<UpdateDoctorInfo> {
  final SecureStorageService storage = SecureStorageService();
  bool isLoading = true;
  Map<String, dynamic>? doctorData;
  late List<String> weekdays;
  List<String> selectedDays = [];
  String startTime = '';
  String endTime = '';

  @override
  void initState() {
    super.initState();
    weekdays = [
      // 'Thứ Hai',
      // 'Thứ Ba',
      // 'Thứ Tư',
      // 'Thứ Năm',
      // 'Thứ Sáu',
      // 'Thứ Bảy',
      // 'Chủ Nhật'
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
        selectedDays = (doctorData?['workingDays'] as List<dynamic>)
            .map((workingDays) => workingDays.toString())
            .toList();
        startTime = doctorData?['startTime'];
        endTime = doctorData?['endTime'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load user info');
    }
  }

  // Hàm chuyển đổi thời gian thành danh sách
  List<String> _generateTimeList() {
    List<String> timeList = [];
    for (int hour = 6; hour <= 18; hour++) {
      if (hour != 12) {
        timeList.add('${hour.toString()}:00');
      }
    }
    return timeList;
  }

  // Hàm xử lý logic khi chọn giờ làm việc
  bool _isValidTime(String start, String end) {
    int startHour = int.parse(start.split(':')[0]);
    int endHour = int.parse(end.split(':')[0]);
    return (endHour - startHour) >= 8;
  }

  // Hàm cập nhật thông tin
  Future<void> _updateDoctorInfo() async {
    if (_isValidTime(startTime, endTime)) {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.put(
        Uri.parse('${dotenv.env['LOCALHOST']}/doctor/update'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'workingDays': selectedDays,
          'startTime': startTime,
          'endTime': endTime,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thông tin thành công!')),
        );
        Navigator.pop(context);
        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại. Vui lòng thử lại!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thời gian làm việc phải cách nhau ít nhất 8 tiếng!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cập Nhật Thông Tin',
          style: TextStyle(color: Colors.white),
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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày Làm Việc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    children: weekdays.map((day) {
                      bool isSelected = selectedDays.contains(day);
                      return ChoiceChip(
                        label: Text(day, style: TextStyle(color: Colors.white)),
                        selected: isSelected,
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.red,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Giờ Làm Việc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: startTime ?? doctorData?['startTime'],
                          items: _generateTimeList()
                              .map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                startTime = newValue;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: DropdownButton<String>(
                          value: endTime ?? doctorData?['endTime'],
                          items: _generateTimeList()
                              .map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                endTime = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: _updateDoctorInfo,
                    child: Text('Lưu Thay Đổi'),
                  ),
                ],
              ),
            ),
    );
  }
}
