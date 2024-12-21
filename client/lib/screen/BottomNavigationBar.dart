import 'dart:convert';

import 'package:client/screen/DoctorListScreen.dart';
import 'package:client/screen/Home_screen.dart';
import 'package:client/screen/ListTile_profile.dart';
import 'package:client/screen/hospital_screen.dart';
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
  String username = '';
  String userId = '';
  String role = '';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    String? token = await storage.getAccessToken();
    if (token != null) {
      Map<String, dynamic> userInfo = Jwt.parseJwt(token);
      print(userInfo);
      setState(() {
        role = userInfo['role'] ?? '';
        username = userInfo['username'] ?? '';
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
        final user = role == 'user'
            ? data.firstWhere(
                (user) => user['username'].toString() == username.toString(),
                orElse: () => null,
              )
            : data.firstWhere(
                (doctor) => doctor['name'].toString() == username.toString(),
                orElse: () => null,
              );
        if (user != null) {
          setState(() {
            userId = user['_id'] ?? '';
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
              builder: (context) => DoctorListScreen(
                hospitalName: '',
              ),
            ),
          );
        }
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
          widget.onTap(index);
        }
      },
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
      ),
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 8.0,
      iconSize: 28.0,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_hospital),
          label: 'Bệnh viện',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.healing_rounded),
          label: 'Bác sĩ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Hồ sơ',
        ),
      ],
    );
  }
}
