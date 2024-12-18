import 'package:client/screen/appointment_list.dart';

import 'package:client/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:client/service/flutter_secure_storage.dart';

import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'dart:convert';

class AppTaskbar extends StatefulWidget {
  final String token; // Thêm token làm tham số của widget

  AppTaskbar({required this.token});
  @override
  _TaskbarState createState() => _TaskbarState();
}

class _TaskbarState extends State<AppTaskbar> {
  final SecureStorageService storage = SecureStorageService();
  final ApiService _apiService = ApiService();
  String username = '';
  String email = '';
  double completionPercentage = 0;
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
        print('Received ${data.length} users from API');

        // Debug: Print all user IDs
        print(
            'User IDs in response: ${data.map((user) => user['username']).toList()}');
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
    //Map<String, dynamic> userInfo = Jwt.parseJwt(widget.token);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(username),
            accountEmail: Text(email),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Thông tin cá nhân'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: Icon(Icons.checklist_rounded),
            title: Text(role == 'doctor'
                ? 'Danh sách lịch hẹn bác sĩ'
                : 'Danh sách lịch hẹn'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AppointmentList(userId: userId, role: role),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Đăng xuất'),
            onTap: () async {
              await _apiService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
