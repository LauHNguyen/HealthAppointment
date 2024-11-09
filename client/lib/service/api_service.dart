import 'dart:convert';
import 'package:client/service/token_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final TokenService tokenService = TokenService();
  final storage = FlutterSecureStorage();

  ApiService(this.baseUrl);

  // Hàm đăng nhập người dùng
  Future<Map<String, String>?> loginUser(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: jsonEncode({'username': username, 'password': password}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        String accessToken = data['access_token'];
        String refreshToken = data['refresh_token'];
        String userId = data['userId'];
        await storage.write(key: 'userId', value: userId);

        return {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        };
      } else {
        print('Login failed: ${response.body}');
      }
    } catch (e) {
      print('Error during login: $e');
    }
    return null; // Nếu đăng nhập thất bại
  }

  // Hàm lấy tỷ lệ hoàn thành
  Future<double?> getProfileCompletionbytoken(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile-completion'),
      headers: {
        'Authorization': 'Bearer $token', // Thêm token vào header
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Kiểm tra xem dữ liệu trả về có phải là một object hay không
      if (responseData is Map<String, dynamic>) {
        final completion = responseData['completion'];
        if (completion is int) {
          return completion.toDouble(); // Ép kiểu int sang double nếu cần
        } else if (completion is double) {
          return completion; // Trả về nếu đã là double
        } else {
          print('Unexpected data type for completion');
          return null;
        }
      } else {
        print('Unexpected response format');
        return null;
      }
    } else {
      print('Failed to fetch profile completion: ${response.statusCode}');
      return null;
    }
  }

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

  // Future<void> logout() async {
  //   try {
  //     await _secureStorageService.removeAccessToken();
  //     await _secureStorageService.removeRefreshToken();
  //     print('Logged out successfully');
  //   } catch (e) {
  //     print(' logout error: $e');
  //   }
  // }
}
