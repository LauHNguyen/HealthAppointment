import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HospitalDemo extends StatefulWidget {
  @override
  _HospitalDemoState createState() => _HospitalDemoState();
}

class _HospitalDemoState extends State<HospitalDemo> {
  List<dynamic> hospitals = [];
  List<dynamic> districts = [];
  List<dynamic> hospitalNames = [];
  List<dynamic> doctors = [];

  String? selectedDistrict;
  String? selectedHospitalName;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await fetchHospitals();
    await fetchDoctors();
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
      // Xây dựng URL động dựa trên giá trị của district và hospitalName
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
                      subtitle:
                          Text(doctor['specialty'] ?? 'Unknown Specialty'),
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
