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
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('Không tìm thấy token truy cập');
      }

      await fetchMessagesAndUserDetails(token);
    } catch (e) {
      print('Lỗi khi tải dữ liệu: $e');
    }
  }

  Future<void> fetchMessagesAndUserDetails(String token) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['LOCALHOST']}/chat/messages/${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      Set<String> uniqueReceiverIds =
          Set<String>.from(data.map((item) => item['receiver'].toString()));

      List<Map<String, dynamic>> fetchedUsers = [];

      for (String id in uniqueReceiverIds) {
        if (id != widget.userId) {
          // Không lấy thông tin của chính người dùng hiện tại
          final userResponse = await http.get(
            Uri.parse(
                '${dotenv.env['LOCALHOST']}/${widget.role == 'doctor' ? 'user' : 'doctor'}/$id'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            fetchedUsers.add(userData);
          } else {
            print('Không thể lấy thông tin người dùng cho ID: $id');
          }
        }
      }

      setState(() {
        userDetails = fetchedUsers;
      });
    } else {
      throw Exception('Không thể tải tin nhắn');
    }
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
