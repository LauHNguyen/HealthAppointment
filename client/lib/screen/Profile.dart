import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class UserInfo extends StatefulWidget {
  @override
  _UserProfile createState() => _UserProfile();
}

class _UserProfile extends State<UserInfo> {
  final SecureStorageService storage = SecureStorageService();
  Map<String, dynamic>? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Chưa cung cấp';
    }
    try {
      final parsedDate =
          DateTime.parse(date); // Chuyển chuỗi ngày thành DateTime
      return DateFormat('dd/MM/yyyy')
          .format(parsedDate); // Định dạng theo dd/MM/yyyy
    } catch (e) {
      return 'Sai định dạng ngày'; // Xử lý lỗi nếu không parse được ngày
    }
  }

  Future<void> _fetchUserInfo() async {
    String? token = await storage.getAccessToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('${dotenv.env['LOCALHOST']}/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = json.decode(response.body);

        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load user info');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Thông Tin Cá Nhân',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.tealAccent], // Các màu gradient
              begin: Alignment.topLeft, // Hướng gradient bắt đầu
              end: Alignment.bottomRight, // Hướng gradient kết thúc
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
              ? Center(
                  child: Text(
                    'Không có dữ liệu người dùng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20),

                        // Username
                        _buildInputField(
                          label: 'Tên người dùng',
                          value: userData?['name'] ?? 'Không có dữ liệu',
                        ),

                        // Email
                        _buildInputField(
                          label: 'Email',
                          value: userData?['email'] ?? 'Không có dữ liệu',
                        ),

                        // Gender
                        _buildInputField(
                          label: 'Giới tính',
                          value: userData?['gender'] ?? 'Không xác định',
                        ),

                        // Birth of Date
                        _buildInputField(
                          label: 'Ngày sinh',
                          value: _formatDate(userData?['birthOfDate']) ??
                              'Chưa cung cấp',
                        ),

                        SizedBox(height: 20),

                        // Update Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14.0, horizontal: 24.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/update');
                          },
                          child: Text(
                            'Cập Nhật Thông Tin',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInputField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: value,
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 12.0,
          ),
        ),
        style: TextStyle(fontSize: 16, color: Colors.black),
      ),
    );
  }
}
