import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class UpdateUserInfo extends StatefulWidget {
  @override
  _UpdateUserInfoState createState() => _UpdateUserInfoState();
}

class _UpdateUserInfoState extends State<UpdateUserInfo> {
  final SecureStorageService storage = SecureStorageService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedGender = '';
  final TextEditingController _birthOfDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserInfo();
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

  Future<void> _fetchCurrentUserInfo() async {
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
      final data = json.decode(response.body);
      print('up user $data');
      setState(() {
        _usernameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _selectedGender = data['gender'] ?? '';
        _birthOfDateController.text = _formatDate(data?['birthOfDate'] ?? '');
      });
    } else {
      throw Exception('Failed to load user info');
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? token = await storage.getAccessToken();
    if (token == null) {
      throw Exception('No token found');
    }

    String formattedBirthDate = '';
    try {
      DateTime parsedDate =
          DateFormat('dd/MM/yyyy').parse(_birthOfDateController.text);
      formattedBirthDate = DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ngày sinh không hợp lệ!')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final response = await http.put(
      Uri.parse('${dotenv.env['LOCALHOST']}/user/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': _usernameController.text,
        'email': _emailController.text,
        'gender': _selectedGender,
        'birthOfDate': formattedBirthDate,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thông tin thành công!')),
      );
      Navigator.pop(context);
      Navigator.pushNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thất bại. Vui lòng thử lại!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cập Nhật Thông Tin',
          style: TextStyle(color: Colors.white),
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildInputField(
                        label: 'Tên người dùng',
                        controller: _usernameController,
                      ),
                      _buildInputField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildGenderSelection(),
                      _buildInputField(
                        label: 'Ngày sinh',
                        controller: _birthOfDateController,
                        keyboardType: TextInputType.datetime,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 24.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: _updateUserInfo,
                        child: Text(
                          'Lưu Thay Đổi',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'Không có dữ liệu';

    try {
      DateTime dateTime = DateTime.parse(rawDate);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Không hợp lệ';
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (value) =>
            value == null || value.isEmpty ? 'Vui lòng nhập $label' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
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

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giới tính',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ListTile(
          title: const Text('Nam'),
          leading: Radio<String>(
            value: 'Nam',
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
          ),
        ),
        ListTile(
          title: const Text('Nữ'),
          leading: Radio<String>(
            value: 'Nữ',
            groupValue: _selectedGender,
            onChanged: (value) {
              setState(() {
                _selectedGender = value!;
              });
            },
          ),
        ),
      ],
    );
  }
}
