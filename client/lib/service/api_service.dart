import 'dart:convert';
import 'package:client/service/token_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final TokenService tokenService = TokenService();

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

  Future<bool> checkIfAnswerExists(
      String userId, String diseaseId, String questionId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['LOCALHOST']}/answer/check?userId=$userId&diseaseId=$diseaseId&questionId=$questionId'),
      );

      if (response.statusCode == 200) {
        // Giả định rằng API trả về một object JSON với một field `exists`
        final data = jsonDecode(response.body);
        return data['exists'] ??
            false; // Nếu `exists` là null, mặc định trả về false
      } else {
        return false; // Trả về false nếu API không thành công
      }
    } catch (e) {
      print('Lỗi khi kiểm tra câu trả lời: $e');
      return false; // Trả về false nếu có lỗi xảy ra
    }
  }

  Future<String> getExistingAnswer(
      String userID, String diseaseID, String questionID) async {
    final response = await http.get(
      Uri.parse(
          '${dotenv.env['LOCALHOST']}/answer/by-ids?userID=$userID&diseaseID=$diseaseID&questionID=$questionID'),
      headers: {
        'Authorization': 'Bearer ${await tokenService.getValidAccessToken()}',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return ""; // Nếu phản hồi là chuỗi rỗng, trả về chuỗi rỗng
      }
      print('Response body: ${response.body}'); // Kiểm tra phản hồi
      final result = json.decode(response.body);
      return result['answer'] ?? ""; // Trả về answer hoặc chuỗi rỗng
    } else if (response.statusCode == 404) {
      return ""; // Không tìm thấy câu trả lời
    } else {
      print('Error: ${response.statusCode} - ${response.body}'); // Ghi nhận lỗi
      throw Exception('Failed to fetch existing answer');
    }
  }

  Future<void> createAnswer(
      String questionId, String answer, String userId, String diseaseId) async {
    final response = await http.post(
      Uri.parse('${dotenv.env['LOCALHOST']}/answer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${await tokenService.getValidAccessToken()}', // Đặt token
      },
      body: json.encode({
        'questionID': questionId,
        'answer': answer,
        'userID': userId, // Thêm userId
        'diseaseID': diseaseId, // Thêm diseaseId
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create answer: ${response.body}');
    }
  }

  // Hàm cập nhật câu trả lời
  Future<void> updateAnswer(String userId, String diseaseId, String questionId,
      String newAnswer) async {
    final response = await http.put(
      Uri.parse(
          '${dotenv.env['LOCALHOST']}/answer/update?userID=$userId&diseaseID=$diseaseId&questionID=$questionId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${await tokenService.getValidAccessToken()}', // Đặt token
      },
      body: json.encode({
        'answer': newAnswer, // Cập nhật câu trả lời mới
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update answer: ${response.body}');
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
