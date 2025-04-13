import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminDoctorManagementScreen extends StatefulWidget {
  @override
  _AdminDoctorManagementScreenState createState() =>
      _AdminDoctorManagementScreenState();
}

class _AdminDoctorManagementScreenState
    extends State<AdminDoctorManagementScreen> {
  final SecureStorageService storage = SecureStorageService();
  List<dynamic> doctors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }
      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/doctor'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          doctors = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() => isLoading = false);
    }
  }

  void _addDoctor() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminAddEditDoctorScreen()),
    ).then((_) => _fetchDoctors());
  }

  void _editDoctor(dynamic doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddEditDoctorScreen(doctor: doctor),
      ),
    ).then((_) => _fetchDoctors());
  }

  Future<void> _deleteDoctor(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('${dotenv.env['LOCALHOST']}/doctor/$id'));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa bác sĩ thành công')),
        );
        _fetchDoctors();
      } else {
        throw Exception('Failed to delete doctor');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa bác sĩ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản Lý Bác Sĩ',
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
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _addDoctor,
                    child: Text(
                      'Thêm Bác Sĩ',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: doctors.isEmpty
                        ? Center(child: Text('Không có bác sĩ'))
                        : ListView.builder(
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return Card(
                                elevation: 4,
                                margin: EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.teal[100],
                                    child:
                                        Icon(Icons.person, color: Colors.teal),
                                  ),
                                  title: Text(
                                    doctor['name'],
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      'Chuyên khoa: ${doctor['specialty']}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blueAccent),
                                        onPressed: () => _editDoctor(doctor),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            _deleteDoctor(doctor['_id']),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class AdminAddEditDoctorScreen extends StatefulWidget {
  final dynamic doctor;

  AdminAddEditDoctorScreen({this.doctor});

  @override
  _AdminAddEditDoctorScreenState createState() =>
      _AdminAddEditDoctorScreenState();
}

class _AdminAddEditDoctorScreenState extends State<AdminAddEditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String specialty = '';
  String hospitalName = '';
  String startTime = '6:00';
  String endTime = '18:00';
  List<String> workingDays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.doctor != null) {
      name = widget.doctor['name'];
      specialty = widget.doctor['specialty'];
      hospitalName = widget.doctor['hospitalName'];
      startTime = widget.doctor['startTime'];
      endTime = widget.doctor['endTime'];
      workingDays = List<String>.from(widget.doctor['workingDays']);
    }
  }

  Future<void> _saveDoctor() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final data = {
        'name': name,
        'specialty': specialty,
        'hospitalName': hospitalName,
        'startTime': startTime,
        'endTime': endTime,
        'workingDays': workingDays,
      };

      try {
        final uri = widget.doctor == null
            ? Uri.parse('${dotenv.env['LOCALHOST']}/doctor')
            : Uri.parse(
                '${dotenv.env['LOCALHOST']}/doctor/${widget.doctor['_id']}');
        final response = widget.doctor == null
            ? await http.post(uri,
                body: jsonEncode(data),
                headers: {'Content-Type': 'application/json'})
            : await http.put(uri,
                body: jsonEncode(data),
                headers: {'Content-Type': 'application/json'});

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.doctor == null
                    ? 'Thêm bác sĩ thành công'
                    : 'Cập nhật bác sĩ thành công')),
          );
          Navigator.pop(context);
        } else {
          throw Exception('Failed to save doctor');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu bác sĩ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.doctor == null ? 'Thêm Bác Sĩ' : 'Sửa Bác Sĩ',
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
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'Tên bác sĩ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập tên' : null,
                onSaved: (value) => name = value!,
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: specialty,
                decoration: InputDecoration(
                  labelText: 'Chuyên khoa',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập chuyên khoa' : null,
                onSaved: (value) => specialty = value!,
              ),
              SizedBox(height: 10),
              TextFormField(
                initialValue: hospitalName,
                decoration: InputDecoration(
                  labelText: 'Bệnh viện',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Vui lòng nhập bệnh viện' : null,
                onSaved: (value) => hospitalName = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _saveDoctor,
                child: Text(
                  widget.doctor == null ? 'Thêm' : 'Cập Nhật',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
