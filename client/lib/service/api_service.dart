import 'dart:convert';
import 'package:client/models/Login.dto.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final SecureStorageService storage = SecureStorageService();

  final String baseUrl = '${dotenv.env['LOCALHOST']}'; // Đặt URL của server API

  // Hàm đăng nhập người dùng
  Future<Map<String, String>?> loginUser(
      String username, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: jsonEncode(
            {'username': username, 'password': password, 'role': role}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];
        //String refreshToken = data['refresh_token'];

        return {
          'accessToken': accessToken,
          //'refreshToken': refreshToken,
        };
      } else {
        print('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Error during login: $e');
    }

    return null; // Nếu đăng nhập thất bại
  }

  Future<bool> registerUser(User user) async {
    final String endpoint = '/auth/register'; // Endpoint của API đăng ký

    final Uri url = Uri.parse('$baseUrl$endpoint');

    try {
      // Gửi yêu cầu POST tới server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user.toJson()), // Chuyển dữ liệu thành JSON
      );

      // Kiểm tra phản hồi từ server
      if (response.statusCode == 201) {
        print('Đăng ký thành công');
        return true; // Thành công
      } else {
        print('Lỗi: ${response.body}');
        return false; // Lỗi
      }
    } catch (error) {
      print('Lỗi khi kết nối tới server: $error');
      return false; // Lỗi kết nối
    }
  }

  Future<Map<String, String>?> loginWithGoogle(
      String? username, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        body: jsonEncode({'username': username, 'email': email}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];
        // String refreshToken = data['refresh_token'];

        // await storage.write(key: 'accessToken', value: accessToken);

        return {
          'accessToken': accessToken,
          // 'refreshToken': refreshToken,
        };
      } else {
        print('Google login failed: ${response.body}');
      }
    } catch (e) {
      print('Error during Google login: $e');
    }

    return null; // Nếu đăng nhập thất bại
  }

  // Kiểm tra xem dữ liệu trả về có phải là một object hay không
  //     if (responseData is Map<String, dynamic>) {
  //       final completion = responseData['completion'];
  //       if (completion is int) {
  //        // Hàm lấy tỷ lệ hoàn thành
  // Future<double?> getProfileCompletionbytoken(String token) async {
  //   final response = await http.get(
  //     Uri.parse('$baseUrl/user/profile-completion'),
  //     headers: {
  //       'Authorization': 'Bearer $token', // Thêm token vào header
  //     },
  //   );

  //   if (response.statusCode == 200) {
  //     final responseData = json.decode(response.body);
  //    return completion.toDouble(); // Ép kiểu int sang double nếu cần
  //       } else if (completion is double) {
  //         return completion; // Trả về nếu đã là double
  //       } else {
  //         print('Unexpected data type for completion');
  //         return null;
  //       }
  //     } else {
  //       print('Unexpected response format');
  //       return null;
  //     }
  //   } else {
  //     print('Failed to fetch profile completion: ${response.statusCode}');
  //     return null;
  //   }
  // }

  Future<void> updateUser(
      String token, Map<String, dynamic> updatedUserData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updatedUserData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  Future<void> logout() async {
    try {
      await storage.removeAccessToken();

      print('Logged out successfully');
    } catch (e) {
      print(' logout error: $e');
    }
  }
}
