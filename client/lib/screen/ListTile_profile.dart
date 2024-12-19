import 'package:client/screen/appointment_list.dart';
import 'package:client/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:client/service/flutter_secure_storage.dart';

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
                    'Người dùng: ${widget.userId}',
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
