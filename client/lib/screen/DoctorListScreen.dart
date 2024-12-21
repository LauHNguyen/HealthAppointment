import 'dart:convert';
import 'package:client/screen/Appointment_screen.dart';
import 'package:client/screen/BottomNavigationBar.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:diacritic/diacritic.dart';
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
  List<dynamic> specialty = []; // Danh sách các khoa
  List<dynamic> filteredDoctors = [];
  String? selectedSpecialty;
  String? userId;

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    filterDoctors();
    fetchUserId();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
      if (widget.hospitalName != '') {
        String url = '${dotenv.env['LOCALHOST']}/doctor/filter';
        List<String> queryParams = [];
        queryParams.add(
            'hospitalName=${Uri.encodeComponent('${widget.hospitalName}')}');
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
            specialty =
                doctors.map((doctor) => doctor['specialty']).toSet().toList();
            filteredDoctors = doctors;
          });
        } else {
          throw Exception('Failed to load doctors form ${widget.hospitalName}');
        }
      } else {
        String url = '${dotenv.env['LOCALHOST']}/doctor';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          setState(() {
            doctors = json.decode(response.body);
            specialty =
                doctors.map((doctor) => doctor['specialty']).toSet().toList();
            filteredDoctors = doctors;
          });
        } else {
          throw Exception('Failed to load doctors');
        }
      }
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  Future<void> filterDoctorsBySpecial(String specialty) async {
    try {
      // Kiểm tra phản hồi
      setState(() {
        if (specialty == 'Tất cả') {
          // Nếu chọn "Tất cả", hiển thị tất cả bệnh viện
          filteredDoctors = doctors;
        } else {
          // Lọc bệnh viện theo quận
          filteredDoctors = doctors
              .where((doctor) => doctor['specialty'] == specialty)
              .toList();
        }
      });
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
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: widget.hospitalName != ''
            ? Text('Bác sĩ tại ${widget.hospitalName}',
                style: TextStyle(color: Colors.white))
            : Text('Danh sách bác sĩ', style: TextStyle(color: Colors.white)),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                // Thanh tìm kiếm
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm bác sĩ",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      value = value
                          .trim()
                          .toLowerCase(); // Xử lý chuỗi tìm kiếm, loại bỏ khoảng trắng và chuyển thành chữ thường
                      setState(() {
                        filteredDoctors = doctors.where((doctor) {
                          final name =
                              removeDiacritics(doctor['name'].toLowerCase());
                          final query = removeDiacritics(value.toLowerCase());

                          return name.contains(query);
                        }).toList();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                // Dropdown cho quận
                DropdownButton<String>(
                  hint: Text("Chọn chuyên khoa"),
                  value: selectedSpecialty,
                  onChanged: (value) {
                    setState(() {
                      selectedSpecialty = value;
                      filterDoctorsBySpecial(value!);
                    });
                  },
                  items: [
                    // Thêm giá trị "Tất cả"
                    DropdownMenuItem<String>(
                      value: 'Tất cả',
                      child: Text('Tất cả'),
                    ),
                    // Thêm các quận từ danh sách districts
                    ...specialty.toSet().map((specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty,
                        child: Text(specialty),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: filteredDoctors.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: TextStyle(
                                              color: Colors.grey[600]),
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
                  : Center(child: Text("Không có bác sĩ phù hợp")),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
