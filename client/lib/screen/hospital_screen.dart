import 'dart:convert';

import 'package:client/screen/BottomNavigationBar.dart';
import 'package:client/screen/DoctorListScreen.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:diacritic/diacritic.dart';

class ChooseHospital extends StatefulWidget {
  @override
  _ChooseHospitalState createState() => _ChooseHospitalState();
}

class _ChooseHospitalState extends State<ChooseHospital> {
  final SecureStorageService storage = SecureStorageService();

  List<dynamic> hospitals = []; // Danh sách bệnh viện
  List<dynamic> doctors = []; // Danh sách bác sĩ
  List<dynamic> districts = []; // Danh sách quận/huyện
  List<dynamic> filteredHospitals = []; // Danh sách bệnh viện đã lọc

  String? userId;
  String? selectedDistrict; // Quận được chọn
  String? selectedHospitalName; // Bệnh viện được chọn

  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    loadInitialData(); // Gọi hàm tải dữ liệu ban đầu
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> loadInitialData() async {
    await fetchHospitals();
    await fetchUserId();
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
          userId = data['userId']; // Trích xuất giá trị userId
        });
      } else {
        throw Exception('Failed to get user ID');
      }
    } catch (e) {
      print("Error fetching User Id: $e");
    }
  }

  Future<void> fetchHospitals() async {
    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['LOCALHOST']}/hospital/load'));
      if (response.statusCode == 200) {
        setState(() {
          hospitals = json.decode(response.body);
          districts = hospitals
              .map((hospital) => hospital['district'] ?? 'Unknown District')
              .toSet()
              .toList();
          filteredHospitals = hospitals; // Khởi tạo danh sách bệnh viện đã lọc
        });
      } else {
        throw Exception('Failed to load hospitals');
      }
    } catch (e) {
      print("Error fetching hospitals: $e");
    }
  }

  void filterHospitalsByDistrict(String? district) {
    setState(() {
      if (district == 'Tất cả') {
        // Nếu chọn "Tất cả", hiển thị tất cả bệnh viện
        filteredHospitals = hospitals;
      } else {
        // Lọc bệnh viện theo quận
        filteredHospitals = hospitals
            .where((hospital) => hospital['district'] == district)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title:
            Text("Danh sách Bệnh Viện", style: TextStyle(color: Colors.white)),
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
            // Thanh tìm kiếm và Dropdown cho quận
            Row(
              children: [
                // Thanh tìm kiếm
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Nhập tên bệnh viện",
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
                        filteredHospitals = hospitals.where((hospital) {
                          final name =
                              removeDiacritics(hospital['name'].toLowerCase());
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
                  hint: Text("Chọn quận"),
                  value: selectedDistrict,
                  onChanged: (value) {
                    setState(() {
                      selectedDistrict = value;
                      filterHospitalsByDistrict(value);
                    });
                  },
                  items: [
                    // Thêm giá trị "Tất cả"
                    DropdownMenuItem<String>(
                      value: 'Tất cả',
                      child: Text('Tất cả'),
                    ),
                    // Thêm các quận từ danh sách districts
                    ...districts.toSet().map((district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),

            // Danh sách bệnh viện
            Expanded(
              child: filteredHospitals.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredHospitals.length,
                      itemBuilder: (context, index) {
                        final hospital = filteredHospitals[index];
                        return InkWell(
                          onTap: () {
                            // Chuyển đến màn hình danh sách bác sĩ của bệnh viện này
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorListScreen(
                                  hospitalName:
                                      hospital['name'], // Truyền tên bệnh viện
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.teal[100],
                                    child: Icon(
                                      Icons.local_hospital,
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
                                          hospital['name'] ?? "Tên bệnh viện",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.teal[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Chuyên khoa: ${hospital['specialty'] ?? 'Không rõ'}",
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Địa chỉ: ${hospital['address'] ?? 'Không rõ'}",
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
                  : Center(child: Text("Không tìm thấy bệnh viện")),
            )
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
