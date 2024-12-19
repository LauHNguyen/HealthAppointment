import 'dart:convert';

import 'package:client/screen/Home_screen.dart';
import 'package:client/screen/ListTile_profile.dart';
import 'package:client/screen/hospital_screen.dart';
import 'package:client/service/api_service.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decode/jwt_decode.dart';

import 'package:http/http.dart' as http;

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  @override
  _CustomBottomNavState createState() => _CustomBottomNavState();
  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  final SecureStorageService storage = SecureStorageService();
  String userId = '';
  String role = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  //get api user
  Future<void> _fetchUserInfo() async {
    String? token = await storage.getAccessToken();
    if (token != null) {
      Map<String, dynamic> userInfo = Jwt.parseJwt(token);
      print(userInfo);
      setState(() {
        print(userInfo);
        role = userInfo['role'] ?? '';
        userId = userInfo['userId'] ?? '';
      });
    } else {
      print('Failed to fetch user id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        } else if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChooseHospital(),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
            ),
          );
        }
        // Kiểm tra nếu mục là 'Hồ sơ' (index == 3), điều hướng đến trang profile
        if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                role: role,
                userId: userId,
              ),
            ),
          );
        } else {
          widget.onTap(index); // Chỉ gọi onTap nếu không phải là Hồ sơ
        }
      },
      selectedItemColor: Colors.blue, // Màu cho mục được chọn
      unselectedItemColor: Colors.grey, // Màu cho mục chưa được chọn
      iconSize: 30.0, // Kích thước biểu tượng lớn hơn
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_hospital), // Biểu tượng bệnh viện
          label: 'Bệnh viện',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contact_mail), // Biểu tượng liên hệ
          label: 'Liên hệ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person), // Biểu tượng hồ sơ
          label: 'Hồ sơ',
        ),
      ],
    );
  }
}