import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _secureStorage = FlutterSecureStorage();
  // Lưu token vào Secure Storage
  Future<void> saveAccessToken(String accessToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
  }

  // Lấy token từ Secure Storage
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  // Xóa token khỏi Secure Storage
  Future<void> removeAccessToken() async {
    await _secureStorage.delete(key: 'access_token');
  }

  Future<void> removeRefreshToken() async {
    await _secureStorage.delete(key: 'refresh_token');
  }

  //lưu id người dùng khi đăng nhập
  // Future<void> saveUserId(String userId) async {
  //   await _secureStorage.write(key: 'userId', value: userId);
  // }

  // Future<String?> getUserId() async {
  //   return await _secureStorage.read(key: 'userId');
  // }

  //đăng xuất => xóa hết các token và id trong storage ||| này tham khảo !
  // Future<void> deleteAll() async {
  //   await _secureStorage.deleteAll();
  // }
}
