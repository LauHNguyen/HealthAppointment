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

  final List<String> _symptoms = [
    'Biếng ăn ở trẻ', // Nhi khoa
    'Buồn nôn', // Tiêu hóa
    'Chảy máu', // Tiêu hóa / Cấp cứu / Huyết học
    'Chảy máu chân răng', // Nha khoa
    'Chảy máu kéo dài', // Huyết học
    'Chảy máu nghiêm trọng', // Cấp cứu
    'Chảy nước mắt nhiều', // Mắt
    'Chóng mặt', // Thần kinh
    'Da khô', // Thẩm mỹ
    'Da xỉn màu', // Thẩm mỹ / Da liễu
    'Dễ bầm tím', // Huyết học
    'Đau bụng', // Tiêu hóa
    'Đau cơ', // Chấn thương chỉnh hình / Vật lý trị liệu
    'Đau do tai nạn', // Ngoại tổng hợp
    'Đau đầu', // Thần kinh
    'Đau họng', // Tai-Mũi-Họng
    'Đau khớp', // Chấn thương chỉnh hình
    'Đau lưng', // Chấn thương chỉnh hình
    'Đau kéo dài không rõ nguyên nhân', // Ung Bướu
    'Đau ngực', // Hô Hấp / Tim mạch
    'Đau răng', // Nha khoa
    'Đau vùng bụng dưới', // Phụ khoa
    'Dễ bầm tím', // Huyết học
    'Gãy xương', // Ngoại tổng hợp
    'Hạn chế vận động', // Chấn thương chỉnh hình / Vật lý trị liệu
    'Ho', // Nội tổng hợp / Hô Hấp
    'Ho dai dẳng', // Hô Hấp
    'Hơi thở có mùi', // Nha khoa
    'Khó cử động', // Vật lý trị liệu
    'Khó nuốt', // Tai-Mũi-Họng
    'Khó thở', // Hô Hấp / Tim mạch
    'Khó thở cấp tính', // Cấp cứu
    'Khó thở khi vận động', // Tim mạch
    'Khó tiểu', // Thận
    'Khối u bất thường', // Ung Bướu
    'Mắt đỏ', // Mắt
    'Mất giọng', // Tai-Mũi-Họng
    'Mất ngủ', // Thần kinh
    'Mất ý thức', // Cấp cứu
    'Mệt mỏi', // Nội tổng hợp / Phụ khoa
    'Ngứa da', // Da liễu
    'Ngứa mắt', // Mắt
    'Nổi mụn nước', // Da liễu
    'Phát ban', // Da liễu
    'Phù chân', // Thận
    'Quấy khóc không rõ nguyên nhân', // Nhi khoa
    'Rối loạn chức năng tình dục', // Nam khoa
    'Rối loạn kinh nguyệt', // Phụ khoa
    'Rối loạn nội tiết', // Y học cổ truyền
    'Rối loạn thị lực', // Thần kinh / Mắt
    'Rối loạn tiêu hóa', // Tiêu hóa
    'Rụng tóc', // Thẩm mỹ / Y học cổ truyền
    'Sốt', // Nội tổng hợp / Nhi khoa
    'Sưng khớp', // Chấn thương chỉnh hình
    'Sưng tấy', // Da liễu
    'Sụt cân', // Nội tổng hợp
    'Tăng cân', // Nội tổng hợp
    'Tiểu buốt', // Nam khoa
    'Trầy xước nặng', // Ngoại tổng hợp
    'Ù tai', // Tai-Mũi-Họng
    'Xuất hiện nếp nhăn sớm', // Thẩm mỹ
  ];

  final List<String> _selectedSymptoms = [];
  String _suggestedDepartment = '';

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
            print(specialty);
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
          filteredDoctors = doctors;
        } else {
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

  void _showSymptomChecker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                return Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chọn các triệu chứng của bạn:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          controller: controller,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _symptoms.map((symptom) {
                                return FilterChip(
                                  label: Text(symptom),
                                  selected: _selectedSymptoms.contains(symptom),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedSymptoms.add(symptom);
                                      } else {
                                        _selectedSymptoms.remove(symptom);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              child: Text(
                                  'Gợi ý chuyên khoa (${_selectedSymptoms.length})'),
                              onPressed: () {
                                _suggestDepartment();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            child: Text('Xóa'),
                            onPressed: () {
                              setModalState(() {
                                _selectedSymptoms.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: Size(80, 50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _suggestDepartment() {
    setState(() {
      if (_selectedSymptoms.isEmpty) {
        _suggestedDepartment = '';
        filteredDoctors = doctors;
        return;
      }

      Map<String, int> departmentScores = {
        'Tiêu hóa': 0,
        'Hô Hấp': 0,
        'Tim mạch': 0,
        'Thần kinh': 0,
        'Tai-Mũi-Họng': 0,
        'Nha khoa': 0,
        'Da liễu': 0,
        'Thận': 0,
        'Chấn thương chỉnh hình': 0,
        'Vật lý trị liệu': 0,
        'Thẩm mỹ': 0,
        'Y học cổ truyền': 0,
        'Ung bướu': 0,
        'Mắt': 0,
        'Nhi khoa': 0,
        'Cấp cứu': 0,
        'Huyết học': 0,
        'Nam khoa': 0,
        'Phụ khoa': 0,
        'Ngoại tổng hợp': 0,
        'Nội tổng hợp': 0,
      };

      for (String symptom in _selectedSymptoms) {
        switch (symptom) {
          case 'Đau bụng':
          case 'Buồn nôn':
          case 'Rối loạn tiêu hóa':
            departmentScores['Tiêu hóa'] =
                (departmentScores['Tiêu hóa'] ?? 0) + 1;
            break;
          case 'Chảy máu':
            departmentScores['Tiêu hóa'] =
                (departmentScores['Tiêu hóa'] ?? 0) + 1;
            departmentScores['Cấp cứu'] =
                (departmentScores['Cấp cứu'] ?? 0) + 1;
            departmentScores['Huyết học'] =
                (departmentScores['Huyết học'] ?? 0) + 1;
            break;
          case 'Sốt':
          case 'Ho':
          case 'Mệt mỏi':
          case 'Sụt cân':
          case 'Tăng cân':
            departmentScores['Nội tổng hợp'] =
                (departmentScores['Nội tổng hợp'] ?? 0) + 1;
            break;
          case 'Khó thở':
          case 'Đau ngực':
            departmentScores['Hô Hấp'] = (departmentScores['Hô Hấp'] ?? 0) + 1;
            departmentScores['Tim mạch'] =
                (departmentScores['Tim mạch'] ?? 0) + 1;
            break;
          case 'Ho dai dẳng':
            departmentScores['Hô Hấp'] = (departmentScores['Hô Hấp'] ?? 0) + 1;
            break;
          case 'Đau đầu':
          case 'Chóng mặt':
          case 'Mất ngủ':
            departmentScores['Thần kinh'] =
                (departmentScores['Thần kinh'] ?? 0) + 1;
            break;
          case 'Rối loạn thị lực':
            departmentScores['Thần kinh'] =
                (departmentScores['Thần kinh'] ?? 0) + 1;
            departmentScores['Mắt'] = (departmentScores['Mắt'] ?? 0) + 1;
            break;
          case 'Ù tai':
          case 'Khó nuốt':
          case 'Đau họng':
          case 'Mất giọng':
            departmentScores['Tai-Mũi-Họng'] =
                (departmentScores['Tai-Mũi-Họng'] ?? 0) + 1;
            break;
          case 'Đau răng':
          case 'Chảy máu chân răng':
          case 'Hơi thở có mùi':
            departmentScores['Nha khoa'] =
                (departmentScores['Nha khoa'] ?? 0) + 1;
            break;
          case 'Ngứa da':
          case 'Phát ban':
          case 'Sưng tấy':
          case 'Nổi mụn nước':
            departmentScores['Da liễu'] =
                (departmentScores['Da liễu'] ?? 0) + 1;
            break;
          case 'Khó tiểu':
          case 'Phù chân':
            departmentScores['Thận'] = (departmentScores['Thận'] ?? 0) + 1;
            break;
          case 'Đau khớp':
          case 'Đau lưng':
          case 'Sưng khớp':
            departmentScores['Chấn thương chỉnh hình'] =
                (departmentScores['Chấn thương chỉnh hình'] ?? 0) + 1;
            break;
          case 'Đau cơ':
          case 'Hạn chế vận động':
          case 'Khó cử động':
          case 'Chấn thương cơ':
            departmentScores['Chấn thương chỉnh hình'] =
                (departmentScores['Chấn thương chỉnh hình'] ?? 0) + 1;
            departmentScores['Vật lý trị liệu'] =
                (departmentScores['Vật lý trị liệu'] ?? 0) + 1;
            break;
          case 'Rụng tóc':
            departmentScores['Thẩm mỹ'] =
                (departmentScores['Thẩm mỹ'] ?? 0) + 1;
            departmentScores['Y học cổ truyền'] =
                (departmentScores['Y học cổ truyền'] ?? 0) + 1;
            break;
          case 'Da xỉn màu':
            departmentScores['Thẩm mỹ'] =
                (departmentScores['Thẩm mỹ'] ?? 0) + 1;
            departmentScores['Da liễu'] =
                (departmentScores['Da liễu'] ?? 0) + 1;
            break;
          case 'Da khô':
          case 'Xuất hiện nếp nhăn sớm':
            departmentScores['Thẩm mỹ'] =
                (departmentScores['Thẩm mỹ'] ?? 0) + 1;
            break;
          case 'Rối loạn nội tiết':
            departmentScores['Y học cổ truyền'] =
                (departmentScores['Y học cổ truyền'] ?? 0) + 1;
            departmentScores['Nội tổng hợp'] =
                (departmentScores['Nội tổng hợp'] ?? 0) + 1;
            break;
          case 'Khối u bất thường':
          case 'Đau kéo dài không rõ nguyên nhân':
            departmentScores['Ung bướu'] =
                (departmentScores['Ung bướu'] ?? 0) + 1;
            break;
          case 'Mắt đỏ':
          case 'Ngứa mắt':
          case 'Chảy nước mắt nhiều':
            departmentScores['Mắt'] = (departmentScores['Mắt'] ?? 0) + 1;
            break;
          case 'Quấy khóc không rõ nguyên nhân':
          case 'Biếng ăn ở trẻ':
            departmentScores['Nhi khoa'] =
                (departmentScores['Nhi khoa'] ?? 0) + 1;
            break;
          case 'Khó thở cấp tính':
          case 'Mất ý thức':
          case 'Chảy máu nghiêm trọng':
            departmentScores['Cấp cứu'] =
                (departmentScores['Cấp cứu'] ?? 0) + 1;
            break;
          case 'Dễ bầm tím':
          case 'Chảy máu kéo dài':
            departmentScores['Huyết học'] =
                (departmentScores['Huyết học'] ?? 0) + 1;
            break;
          case 'Nam giới đau vùng háng':
          case 'Rối loạn chức năng tình dục':
          case 'Tiểu buốt':
            departmentScores['Nam khoa'] =
                (departmentScores['Nam khoa'] ?? 0) + 1;
            break;
          case 'Rối loạn kinh nguyệt':
          case 'Đau vùng bụng dưới':
            departmentScores['Phụ khoa'] =
                (departmentScores['Phụ khoa'] ?? 0) + 1;
            break;
          case 'Đau do tai nạn':
          case 'Gãy xương':
          case 'Trầy xước nặng':
            departmentScores['Ngoại tổng hợp'] =
                (departmentScores['Ngoại tổng hợp'] ?? 0) + 1;
            break;
        }
      }

      var maxScore = departmentScores.values.reduce((a, b) => a > b ? a : b);
      var suggestedDepartments = departmentScores.entries
          .where((entry) => entry.value == maxScore)
          .map((entry) => entry.key)
          .toList();

      if (suggestedDepartments.length > 1) {
        _suggestedDepartment = 'Có thể là: ${suggestedDepartments.join(", ")}';
        filteredDoctors = doctors
            .where(
                (doctor) => suggestedDepartments.contains(doctor['specialty']))
            .toList();
      } else {
        _suggestedDepartment = suggestedDepartments.first;
        filteredDoctors = doctors
            .where((doctor) => doctor['specialty'] == _suggestedDepartment)
            .toList();
      }

      if (filteredDoctors.isEmpty) {
        _suggestedDepartment += ' (Không có bác sĩ phù hợp)';
        filteredDoctors = doctors;
      }
    });
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
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.lightbulb_outline),
            onPressed: _showSymptomChecker,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
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
                      value = value.trim().toLowerCase();
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
                    DropdownMenuItem<String>(
                      value: 'Tất cả',
                      child: Text('Tất cả'),
                    ),
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
          ),
          if (_suggestedDepartment.isNotEmpty &&
              _suggestedDepartment !=
                  'Vui lòng tham khảo ý kiến bác sĩ để được tư vấn chính xác')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Chuyên khoa được gợi ý: $_suggestedDepartment',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
            ),
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
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
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
                                        style:
                                            TextStyle(color: Colors.grey[600]),
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
