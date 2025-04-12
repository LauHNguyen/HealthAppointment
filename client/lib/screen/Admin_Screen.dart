import 'package:client/screen/AdminDoctorManage_Screen.dart';
import 'package:client/screen/AdminUserManage_Screen.dart';
import 'package:flutter/material.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final SecureStorageService storage = SecureStorageService();
  String username = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAndFetchInfo();
  }

  Future<void> _checkAdminAndFetchInfo() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      Map<String, dynamic> userInfo = Jwt.parseJwt(token);
      String role = userInfo['role'] ?? '';
      if (role != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chỉ admin mới có quyền truy cập!')),
        );
        Navigator.pushReplacementNamed(context, '/');
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data.firstWhere(
          (u) => u['username'] == userInfo['username'],
          orElse: () => null,
        );
        if (user != null) {
          setState(() {
            username = user['name'] ?? userInfo['username'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching admin info: $e');
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _logout() async {
    await storage.removeAccessToken();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản Trị Phòng Khám',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.tealAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Xin chào, $username',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Quản trị viên',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Colors.blueAccent),
              title: Text('Quản Lý Lịch Hẹn'),
              // onTap: () {
              //   Navigator.push(context,
              //       MaterialPageRoute(
              //         builder: (context) => AdminAppointmentFilterScreen(),
              //       ),
              //       );
              // },
            ),
            ListTile(
              leading: Icon(Icons.medical_services, color: Colors.blueAccent),
              title: Text('Quản Lý Bác Sĩ'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDoctorManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.blueAccent),
              title: Text('Quản Lý Bệnh Nhân'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPatientManagementScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: Colors.blueAccent),
              title: Text('Báo Cáo'),
              // onTap: () {
              //   Navigator.push(context,
              //       MaterialPageRoute(
              //         builder: (context) => AdminReportScreen(),
              //       ),
              //       );
              // },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.blueAccent),
              title: Text('Cài Đặt'),
              // onTap: () {
              //   Navigator.push(context,
              //       MaterialPageRoute(
              //         builder: (context) => AdminSettingsScreen(),
              //       ),
              //       );
              // },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Đăng Xuất'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[100],
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chào mừng đến với bảng điều khiển quản trị',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sử dụng menu bên trái để quản lý lịch hẹn, bác sĩ, bệnh nhân, báo cáo và cài đặt hệ thống.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Hành động nhanh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      // _buildQuickActionCard(
                      //   icon: Icons.calendar_today,
                      //   title: 'Lịch Hẹn',
                      //   onTap: () => Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) =>
                      //           AdminAppointmentFilterScreen(),
                      //     ),
                      //   ),
                      // ),
                      _buildQuickActionCard(
                        icon: Icons.medical_services,
                        title: 'Bác Sĩ',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminDoctorManagementScreen(),
                          ),
                        ),
                      ),
                      _buildQuickActionCard(
                        icon: Icons.person,
                        title: 'Bệnh Nhân',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AdminPatientManagementScreen(),
                          ),
                        ),
                      ),
                      // _buildQuickActionCard(
                      //   icon: Icons.bar_chart,
                      //   title: 'Báo Cáo',
                      //   onTap: () => Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => AdminReportScreen(),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.teal),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal[900],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
