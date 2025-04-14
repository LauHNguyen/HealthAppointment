import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminPatientManagementScreen extends StatefulWidget {
  @override
  _AdminPatientManagementScreenState createState() =>
      _AdminPatientManagementScreenState();
}

class _AdminPatientManagementScreenState
    extends State<AdminPatientManagementScreen> {
  final SecureStorageService storage = SecureStorageService();
  List<dynamic> patients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }
      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          patients = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() => isLoading = false);
    }
  }

  // Future<void> _togglePatientStatus(String id, bool isActive) async {
  //   try {
  //     String? token = await storage.getAccessToken();
  //     if (token == null) {
  //       throw Exception('No token found');
  //     }
  //     final response = await http.patch(
  //       Uri.parse('${dotenv.env['LOCALHOST']}/user/$id'),
  //       body: jsonEncode({'isActive': !isActive}),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //             content: Text(isActive
  //                 ? 'Khóa tài khoản thành công'
  //                 : 'Mở tài khoản thành công')),
  //       );
  //       _fetchPatients();
  //     } else {
  //       throw Exception('Failed to toggle patient status');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Lỗi khi cập nhật trạng thái')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản Lý Bệnh Nhân',
          style: TextStyle(color: Colors.white),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(12.0),
              child: patients.isEmpty
                  ? Center(child: Text('Không có bệnh nhân'))
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        //final isActive = patient['isActive'] ?? true;
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal[100],
                              child: Icon(Icons.person, color: Colors.teal),
                            ),
                            title: Text(
                              patient['name'] ?? patient['username'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text('Email: ${patient['email'] ?? 'Chưa có'}'),
                            // trailing: IconButton(
                            //   icon: Icon(
                            //     isActive ? Icons.lock : Icons.lock_open,
                            //     color:
                            //         isActive ? Colors.redAccent : Colors.green,
                            //   ),
                            //   onPressed: () => _togglePatientStatus(
                            //       patient['_id'], isActive),
                            // ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
