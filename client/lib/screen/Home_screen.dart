import 'dart:convert';

import 'package:client/screen/BottomNavigationBar.dart';
import 'package:client/service/api_service.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final SecureStorageService storage = SecureStorageService();
  final ApiService _apiService = ApiService();
  String username = '';
  String email = '';
  double completionPercentage = 0;
  String userId = '';
  String role = '';
  String token = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  final List<Map<String, String>> articles = [
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'Hiện tượng ngực chảy xệ sau khi sinh',
      'author': 'Bác sĩ Nguyễn Quang Hiếu',
      'date': '18/12/2024',
      'category': 'Sản - Phụ Khoa'
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'U thần kinh nội tiết: Nhóm ung thư dễ bỏ sót',
      'author': 'Bác sĩ Lương Sỹ Bắc',
      'date': '18/12/2024',
      'category': 'Ung thư'
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'Tiền sản giật trong thai kỳ: Vấn đề sức khỏe cần được quan tâm',
      'author': 'Bác sĩ Đoàn Thị Hoài Trang',
      'date': '18/12/2024',
      'category': 'Sản - Phụ Khoa'
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'Viêm động mạch thái dương: Căn bệnh lạ với nguy cơ tiềm tàng',
      'author': 'Bác sĩ Nguyễn Văn Tùng',
      'date': '18/12/2024',
      'category': 'Thần kinh'
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Fetch user info from API
  Future<void> _fetchUserInfo() async {
    String? token = await storage.getAccessToken();
    if (token != null) {
      Map<String, dynamic> userInfo = Jwt.parseJwt(token);
      print(userInfo);
      setState(() {
        print(userInfo);
        role = userInfo['role'] ?? '';
        userId = userInfo['userId'] ?? '';
        username = userInfo['username'];
      });
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['LOCALHOST']}/${role == 'doctor' ? 'doctor' : 'user'}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data.firstWhere(
          (user) => user['username'].toString() == username.toString(),
          orElse: () => null,
        );
        if (user != null) {
          setState(() {
            username = user['name'] ?? '';
            email = user['email'] ?? '';
          });
        } else {
          print('User not found in the response data');
        }
      } else {
        print('Fetched user ID does not match token ID');
        return null;
      }
    } else {
      print('Failed to fetch user id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Ẩn nút quay lại
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services,
                color: Colors.white), // Thêm biểu tượng
            SizedBox(width: 8),
            Text('Xin chào, $username', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 0, // Bỏ bóng dưới appbar
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Tab Trang chủ
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: NetworkImage(article['image']!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article['category']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    article['title']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    article['author']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    article['date']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Tab Tìm kiếm
          Center(
            child: Text('Tìm kiếm'),
          ),
          // Tab Hồ sơ
          Center(
            child: Text('Hồ sơ cá nhân'),
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