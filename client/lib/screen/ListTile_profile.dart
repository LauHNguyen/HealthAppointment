import 'dart:convert';

import 'package:client/screen/appointment_list.dart';
import 'package:client/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

class ProfilePage extends StatefulWidget {
  final String role;
  final String userId;

  const ProfilePage({
    Key? key,
    required this.role,
    required this.userId,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  final SecureStorageService storage = SecureStorageService();

  String username = '';

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
      setState(() {
        username = userInfo['username'];
      });
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['LOCALHOST']}/${widget.role == 'doctor' ? 'doctor' : 'user'}'),
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
        title: const Text(
          'Trang Cá Nhân',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            const SizedBox(height: 20),
            // Ảnh đại diện và tên
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Người dùng: $username',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.role == 'doctor'
                        ? 'Bác sĩ'
                        : 'Người dùng thông thường',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),
            // Thông tin cá nhân
            ListTile(
              leading:
                  const Icon(Icons.account_circle, color: Colors.blueAccent),
              title: const Text(
                'Thông tin cá nhân',
                style: TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            // Danh sách lịch hẹn
            ListTile(
              leading:
                  const Icon(Icons.checklist_rounded, color: Colors.blueAccent),
              title: Text(
                widget.role == 'doctor'
                    ? 'Danh sách lịch hẹn bác sĩ'
                    : 'Danh sách lịch hẹn',
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentList(
                      userId: widget.userId,
                      role: widget.role,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),
            // Đăng xuất
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 18, color: Colors.grey),
              onTap: () async {
                await _apiService.logout();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            const Divider(height: 1, thickness: 0.5),
          ],
        ),
      ),
    );
  }
}
