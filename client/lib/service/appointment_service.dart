import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment.dart';
import './flutter_secure_storage.dart';

class AppointmentService {
  final String baseUrl;
  final _storage = SecureStorageService();

  AppointmentService({required this.baseUrl});

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
}
