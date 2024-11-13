// import 'dart:convert';

// import 'package:client/models/Login.dto.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// import 'package:http/http.dart' as http;

// class LoginService {
//   final storage = FlutterSecureStorage();
//   final String baseUrl = '${dotenv.env['LOCALHOST']}'; // Đặt URL của server API

//   // Phương thức đăng ký
//   Future<bool> registerUser(User user) async {
//     final String endpoint = '/auth/register'; // Endpoint của API đăng ký

//     final Uri url = Uri.parse('$baseUrl$endpoint');

//     try {
//       // Gửi yêu cầu POST tới server
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(user.toJson()), // Chuyển dữ liệu thành JSON
//       );

//       // Kiểm tra phản hồi từ server
//       if (response.statusCode == 201) {
//         print('Đăng ký thành công');
//         return true; // Thành công
//       } else {
//         print('Lỗi: ${response.body}');
//         return false; // Lỗi
//       }
//     } catch (error) {
//       print('Lỗi khi kết nối tới server: $error');
//       return false; // Lỗi kết nối
//     }
//   }

//   // Future<bool> loginUser(User user) async {
//   //   final String endpoint = '/auth/login'; // Endpoint của API đăng nhập
//   //   final Uri url = Uri.parse('$baseUrl$endpoint');

//   //   try {
//   //     final response = await http.post(
//   //       url,
//   //       headers: {
//   //         'Content-Type': 'application/json',
//   //       },
//   //       body: jsonEncode(user.toJson()), // Chuyển dữ liệu thành JSON
//   //     );

//   //     if (response.statusCode == 200) {
//   //       print('Đăng nhập thành công');
//   //       return true; // Thành công
//   //     } else {
//   //       print('Lỗi: ${response.body}');
//   //       return false; // Lỗi
//   //     }
//   //   } catch (error) {
//   //     print('Lỗi khi kết nối tới server: $error');
//   //     return false; // Lỗi kết nối
//   //   }
//   // }

//   Future<Map<String, String>?> loginUser(User user) async {
//     final String endpoint = '/auth/login'; // Endpoint của API đăng nhập
//     final Uri url = Uri.parse('$baseUrl$endpoint');

//     try {
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(user.toJson()), // Chuyển dữ liệu thành JSON
//       );

//       if (response.statusCode == 200) {
//         // Phân tích phản hồi từ server
//         final data = jsonDecode(response.body);
//         String accessToken = data['access_token'];
//         String refreshToken = data['refresh_token'];
//         String userId = data['userId'];

//         await storage.write(key: 'userId', value: userId);

//         print('Đăng nhập thành công $userId');
//         return {
//           'accessToken': accessToken,
//           'refreshToken': refreshToken,
//         }; // Trả về token
//       } else {
//         print('Lỗi: ${response.body}');
//         return null; // Lỗi đăng nhập
//       }
//     } catch (error) {
//       print('Lỗi khi kết nối tới server: $error');
//       return null; // Lỗi kết nối
//     }
//   }
// }
