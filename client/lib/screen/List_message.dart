import 'dart:convert';
import 'package:client/screen/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';

class Listmessage extends StatefulWidget {
  final String userId;
  final String role;

  const Listmessage({
    required this.userId,
    required this.role,
  });

  @override
  _ListmessageState createState() => _ListmessageState();
}

class _ListmessageState extends State<Listmessage> {
  final SecureStorageService storage = SecureStorageService();
  Set<String> receiver = {};
  List<Map<String, dynamic>> userDetails = [];

  @override
  void initState() {
    super.initState();
    fetchMessage();
  }

  Future<void> fetchMessage() async {
    String? token = await storage.getAccessToken();
    if (token != null) {
      final messdata = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/chat/messages/${widget.userId}'),
      );

      if (messdata.statusCode == 200) {
        final data = jsonDecode(messdata.body);
        setState(() {
          receiver.addAll(
            // Lấy giá trị của 'receiver' từ mỗi object trong danh sách
            (data as List).map((item) => item['receiver'].toString()).toSet(),
          );
        });
        fetchUserDetails(token);
        final response = await http.get(
          Uri.parse(
              '${dotenv.env['LOCALHOST']}/${widget.role == 'doctor' ? 'user' : 'doctor'}'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            receiver.addAll(
              // Lấy giá trị của 'receiver' từ mỗi object trong danh sách
              (data as List).map((item) => item['receiver'].toString()).toSet(),
            );
          });
        }
      } else {
        print('Message not found in the response data');
      }
    } else {
      print('Failed to fetch message');
    }
  }

  Future<void> fetchUserDetails(String token) async {
    List<Map<String, dynamic>> fetchedUsers = [];

    for (String id in receiver) {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['LOCALHOST']}/${widget.role == 'doctor' ? 'user' : 'doctor'}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        fetchedUsers.add(userData); // Thêm thông tin người dùng vào danh sách
      } else {
        print('Failed to fetch user data for ID: $id');
      }
    }

    setState(() {
      userDetails = fetchedUsers; // Cập nhật danh sách thông tin người dùng
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Danh sách tin nhắn',
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
      body: userDetails.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: userDetails.length,
              itemBuilder: (context, index) {
                final user = userDetails[index];
                final userName = user['name'];
                final userID = user['_id'];
                print(userID);
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      widget.role == 'user'
                          ? 'Bác sĩ: $userName'
                          : 'Bệnh nhân: $userName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Hành động khi nhấn vào từng người dùng
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userId: widget.userId,
                            doctorId: userID,
                            userRole: widget.role,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
