import 'dart:convert';
import 'package:client/screen/appointment_screen.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChooseDoctor extends StatefulWidget {
  @override
  _ChooseDoctorState createState() => _ChooseDoctorState();
}

class _ChooseDoctorState extends State<ChooseDoctor> {
  final SecureStorageService storage = SecureStorageService();

  List<dynamic> hospitals = [];
  List<dynamic> districts = [];
  List<dynamic> hospitalNames = [];
  List<dynamic> doctors = [];

  String? selectedDistrict;
  String? selectedHospitalName;
  String? userId; // = '67233bfb196c0855e66d87a0';

  bool isChatOpen = false;
  List<Map<String, String>> _messages = [];
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await fetchUserId();
    await fetchHospitals();
    await fetchDoctors();
  }

  Future<void> fetchUserId() async {
    try {
      String? token = await storage.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }
      final response = await http.get(
        Uri.parse('${dotenv.env['LOCALHOST']}/user/id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userId = data['userId']; // Trích xuất giá trị userId
        });
      } else {
        throw Exception('Failed to get user ID');
      }
    } catch (e) {
      print("Error fetching User Id: $e");
    }
  }

  Future<void> fetchDoctors() async {
    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['LOCALHOST']}/doctor/load'));
      if (response.statusCode == 200) {
        setState(() {
          doctors = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  Future<void> fetchHospitals() async {
    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['LOCALHOST']}/hospital/load'));
      if (response.statusCode == 200) {
        setState(() {
          hospitals = json.decode(response.body);

          districts = hospitals
              .map((hospital) => hospital['district'] ?? 'Unknown District')
              .toSet()
              .toList();
        });
      } else {
        throw Exception('Failed to load hospitals');
      }
    } catch (e) {
      print("Error fetching hospitals: $e");
    }
  }

  void updateHospitalNames() {
    if (selectedDistrict != null) {
      setState(() {
        hospitalNames = hospitals
            .where((hospital) => hospital['district'] == selectedDistrict)
            .map((hospital) => hospital['name'] ?? 'Unknown Hospital')
            .toList();
        selectedHospitalName = null;
      });
    }
  }

  Future<void> filterDoctors() async {
    try {
      String url = '${dotenv.env['LOCALHOST']}/doctor/filter';
      List<String> queryParams = [];

      if (selectedDistrict != null && selectedDistrict!.isNotEmpty) {
        queryParams.add('district=${Uri.encodeComponent(selectedDistrict!)}');
      }
      if (selectedHospitalName != null && selectedHospitalName!.isNotEmpty) {
        queryParams
            .add('hospitalName=${Uri.encodeComponent(selectedHospitalName!)}');
      }

      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          doctors = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  void navigateToDoctorDetail(dynamic doctor) {
    // if (userId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Appointment(
          userId: userId!,
          doctorId: doctor['_id'],
          doctorName: doctor['name'],
          hospitalName: doctor['hospitalName'],
          workingHoursStart: doctor['startTime'],
          workingHoursEnd: doctor['endTime'],
          workingDays: List<String>.from(doctor['workingDays'] ?? []),
        ),
      ),
    );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Không tìm thấy userId!')),
    //   );
    // }
  }

  // Future<void> _sendMessage() async {
  //   String question = _controller.text;
  //   _controller.clear();

  //   setState(() {
  //     _messages.add({"sender": "user", "text": question});
  //   });

  //   final response = await http.post(
  //     Uri.parse('${dotenv.env['LOCALHOST']}/ask-ai'),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode({"question": question}),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     setState(() {
  //       _messages.add({"sender": "ai", "text": data['answer']});
  //     });
  //   } else {
  //     setState(() {
  //       _messages.add(
  //           {"sender": "ai", "text": "Xin lỗi, không thể trả lời lúc này."});
  //     });
  //   }
  // }

  // void toggleChat() {
  //   setState(() {
  //     isChatOpen = !isChatOpen;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Danh sách Bệnh Viện")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selectedDistrict,
                  hint: Text("Hãy chọn Quận/Huyện"),
                  isExpanded: true,
                  items: districts.map((district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDistrict = value;
                      updateHospitalNames();
                    });
                  },
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedHospitalName,
                  hint: Text("Hãy chọn Bệnh viện"),
                  isExpanded: true,
                  items: hospitalNames.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: selectedDistrict == null
                      ? null
                      : (value) {
                          setState(() {
                            selectedHospitalName = value;
                          });
                        },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: filterDoctors,
                  child: Text("Lọc"),
                ),
                const SizedBox(height: 20),
                if (doctors.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return ListTile(
                          title: Text(doctor['name'] ?? 'Unknown Doctor'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctor['specialty'] ?? 'Unknown Specialty'),
                              Text(
                                  "Giờ làm: ${doctor['startTime'] ?? 'N/A'} - ${doctor['endTime'] ?? 'N/A'}"),
                              Text(
                                  "Ngày làm: ${(doctor['workingDays'] ?? []).join(', ')}"),
                            ],
                          ),
                          onTap: () => navigateToDoctorDetail(doctor),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Nút mở hộp chat ở góc dưới
          //   Positioned(
          //     right: 16,
          //     bottom: 16,
          //     child: FloatingActionButton(
          //       onPressed: toggleChat,
          //       child: Icon(Icons.chat),
          //     ),
          //   ),

          //   // Hộp chat hiển thị khi bật isChatOpen
          //   if (isChatOpen)
          //     Positioned(
          //       right: 16,
          //       bottom: 80,
          //       child: Container(
          //         width: MediaQuery.of(context).size.width * 0.8,
          //         height: MediaQuery.of(context).size.height * 0.5,
          //         padding: EdgeInsets.all(8.0),
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(10),
          //           boxShadow: [
          //             BoxShadow(
          //               color: Colors.black26,
          //               blurRadius: 10,
          //               spreadRadius: 5,
          //             ),
          //           ],
          //         ),
          //         child: Column(
          //           children: [
          //             Row(
          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //               children: [
          //                 Text(
          //                   "Chat AI",
          //                   style: TextStyle(
          //                     fontSize: 18,
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //                 ),
          //                 IconButton(
          //                   icon: Icon(Icons.close),
          //                   onPressed: toggleChat,
          //                 ),
          //               ],
          //             ),
          //             Divider(),
          //             Expanded(
          //               child: ListView.builder(
          //                 itemCount: _messages.length,
          //                 itemBuilder: (context, index) {
          //                   return ListTile(
          //                     title: Text(_messages[index]["text"]!),
          //                     subtitle: Text(_messages[index]["sender"] == "user"
          //                         ? "Bạn"
          //                         : "AI"),
          //                   );
          //                 },
          //               ),
          //             ),
          //             Padding(
          //               padding: const EdgeInsets.only(top: 8.0),
          //               child: Row(
          //                 children: [
          //                   Expanded(
          //                     child: TextField(
          //                       controller: _controller,
          //                       decoration: InputDecoration(
          //                         hintText: "Nhập câu hỏi...",
          //                         border: OutlineInputBorder(),
          //                       ),
          //                     ),
          //                   ),
          //                   IconButton(
          //                     icon: Icon(Icons.send),
          //                     onPressed: _sendMessage,
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
        ],
      ),
    );
  }
}
