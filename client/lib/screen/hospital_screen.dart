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

  String? selectedDistrict;
  String? selectedHospitalName;

  @override
  void initState() {
    super.initState();
    fetchHospitals();
  }

  Future<void> fetchHospitals() async {
    try {
      final response =
          await http.get(Uri.parse('${dotenv.env['LOCALHOST']}/hospital'));
      if (response.statusCode == 200) {
        setState(() {
          hospitals = json.decode(response.body);

          // Lấy danh sách các quận/huyện từ danh sách bệnh viện
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
        selectedHospitalName = null; // Reset lựa chọn bệnh viện khi đổi quận
      });
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
            // Dropdown chọn Quận/Huyện
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

            // Dropdown chọn Tên Bệnh Viện (hiện sau khi chọn Quận/Huyện)
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

            // Hiển thị thông tin đã chọn
            if (selectedDistrict != null && selectedHospitalName != null)
              Text(
                'Bạn đã chọn: Quận/Huyện - $selectedDistrict, Bệnh viện - $selectedHospitalName',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
