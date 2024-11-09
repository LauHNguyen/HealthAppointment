import 'dart:convert';
import 'package:client/screen/appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ChooseDoctor extends StatefulWidget {
  @override
  _ChooseDoctorState createState() => _ChooseDoctorState();
}

class _ChooseDoctorState extends State<ChooseDoctor> {
  final storage = FlutterSecureStorage();

  List<dynamic> hospitals = [];
  List<dynamic> districts = [];
  List<dynamic> hospitalNames = [];
  List<dynamic> doctors = [];

  String? selectedDistrict;
  String? selectedHospitalName;
  String? userId = '67233bfb196c0855e66d87a0';

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    // await fetchUserId();
    await fetchHospitals();
    await fetchDoctors();
  }

  // Future<void> fetchUserId() async {
  //   userId = await storage.read(key: 'userId');
  // }

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
        ),
      ),
    );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Không tìm thấy userId!')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Danh sách Bệnh Viện")),
      body: Padding(
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
    );
  }
}
