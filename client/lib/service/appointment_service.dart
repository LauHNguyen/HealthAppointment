import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/appointment.dart';
import './flutter_secure_storage.dart';

class AppointmentService {
  final _storage = SecureStorageService();

  final String baseUrl = '${dotenv.env['LOCALHOST']}';

  Future<List<Appointment>> getAppointmentsByMonth(int month, int year) async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      throw Exception('Không tìm thấy token xác thực');
    }

    try {
      print('Calling API with month: $month, year: $year');
      final response = await http.get(
        Uri.parse('$baseUrl/appointment/filter/month?month=$month&year=$year'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final data = responseData['data'];

        if (data is List) {
          return data
              .map((json) {
                try {
                  return Appointment.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing appointment: $e');
                  print('Problematic JSON: $json');
                  return null;
                }
              })
              .where((appointment) => appointment != null)
              .cast<Appointment>()
              .toList();
        } else {
          print('Data is not a list: $data');
          return [];
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không thể tải danh sách cuộc hẹn');
      }
    } catch (e) {
      print('Error in getAppointmentsByMonth: $e');
      throw Exception('Lỗi khi tải danh sách cuộc hẹn: ${e.toString()}');
    }
  }

  Future<List<Appointment>> filterAppointments(
    int? month,
    int? year,
    int? date,
    String? doctor,
  ) async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      throw Exception('Không tìm thấy token xác thực');
    }

    try {
      final body = {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        if (date != null) 'date': date,
        if (doctor != null) 'doctor': doctor,
      };
      print('Calling POST $baseUrl/admin/appointment/filter');
      final response = await http.post(
        Uri.parse('$baseUrl/admin/appointment/filter'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final data = responseData['data'];

        if (data is List) {
          return data
              .map((json) {
                try {
                  return Appointment.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing appointment: $e');
                  print('Problematic JSON: $json');
                  return null;
                }
              })
              .where((appointment) => appointment != null)
              .cast<Appointment>()
              .toList();
        } else {
          print('Data is not a list: $data');
          return [];
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Không thể tải danh sách cuộc hẹn');
      }
    } catch (e) {
      print('Error in filterAppointments: $e');
      throw Exception('Lỗi khi tải danh sách cuộc hẹn: ${e.toString()}');
    }
  }
}
