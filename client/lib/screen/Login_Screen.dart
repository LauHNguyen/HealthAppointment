import 'package:client/service/api_service.dart';
import 'package:client/service/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme:
          ColorScheme.fromSeed(seedColor: Color.fromRGBO(75, 173, 232, 1)),
      useMaterial3: true,
    ),
    home: LoginPage(),
  ));
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final SecureStorageService _secureStorageService = SecureStorageService();
  final ApiService _apiService = ApiService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = true;
  String _role = 'user';
  Future<void> login() async {
    // Lấy dữ liệu từ TextField
    final username = _usernameController.text;
    final password = _passwordController.text;
    // print('Username: $username');
    // print('Password: $password');
    Map<String, String>? tokens;
    if (_role == 'doctor') {
      tokens = await _apiService.loginUser(username, password, _role);
      print('Đăng nhập với vai trò bác sĩ');
    } else {
      tokens = await _apiService.loginUser(username, password, _role);
      print('Đăng nhập với vai trò người dùng');
    }

    if (tokens != null) {
      //   // Lấy access token và refresh token từ phản hồi của API
      String? accessToken = tokens['accessToken']!;
      //String refreshToken = tokens['refreshToken']!;

      //   // Hiển thị thông báo đăng nhập thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thành công!')),
      );

      //   // Lưu cả access token và refresh token vào storage
      await _secureStorageService.saveAccessToken(accessToken);
      //await _secureStorageService.saveRefreshToken(refreshToken);

      Navigator.pushNamed(context, '/home');
    } else {
      // Xử lý khi đăng nhập thất bại
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại!')),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn(
        scopes: <String>[
          'email',
        ],
      );
      var account = await _googleSignIn.signIn();
      print(account);
      Map<String, String>? tokens = await _apiService.loginWithGoogle(
          account?.displayName, account!.email);

      if (tokens != null) {
        String accessToken = tokens['accessToken']!;
        await _secureStorageService.saveAccessToken(accessToken);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login Successful!')),
        );

        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login Failed!')),
        );
      }
    } catch (e) {
      print('Error during Google login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, colors: [
          Colors.teal,
          Colors.tealAccent,
        ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                      duration: Duration(milliseconds: 1000),
                      child: Text(
                        "Đăng Nhập",
                        style: TextStyle(color: Colors.white, fontSize: 40),
                      )),
                  SizedBox(height: 10),
                  FadeInUp(
                      duration: Duration(milliseconds: 1300),
                      child: Text(
                        "Chào mừng trở lại!",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      )),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60))),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 60),
                        FadeInUp(
                          duration: Duration(milliseconds: 1400),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Color.fromRGBO(225, 95, 27, .3),
                                      blurRadius: 20,
                                      offset: Offset(0, 10))
                                ]),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200))),
                                  child: TextField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                        hintText: "Email hoặc số điện thoại",
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        border: InputBorder.none),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200))),
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: _isPasswordVisible,
                                    decoration: InputDecoration(
                                      hintText: "Mật Khẩu",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: InputBorder.none,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  height: 60,
                                  child: DropdownButtonHideUnderline(
                                    // Ẩn đường gạch dưới mặc định của DropdownButton
                                    child: DropdownButton<String>(
                                      value: _role,
                                      icon: SizedBox.shrink(),
                                      isExpanded:
                                          true, // Đảm bảo dropdown sử dụng toàn bộ chiều rộng
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _role = newValue!;
                                        });
                                      },
                                      items: <String>['user', 'doctor']
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          alignment: Alignment.center,
                                          value: value,
                                          child: Text(
                                            value == 'user'
                                                ? 'Bệnh Nhân'
                                                : 'Bác Sĩ',
                                            style: TextStyle(
                                                color: Colors.grey.shade800),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 60),
                        FadeInUp(
                          duration: Duration(milliseconds: 1500),
                          child: MaterialButton(
                            onPressed: login, // Gọi hàm đăng nhập thông thường
                            height: 50,
                            color: Colors.teal[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                "Đăng Nhập",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        FadeInUp(
                          duration: Duration(milliseconds: 1600),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              "Chưa có tài khoản ? Đăng ký",
                              style: TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        FadeInUp(
                          duration: Duration(milliseconds: 1700),
                          child: MaterialButton(
                            onPressed:
                                loginWithGoogle, // Thêm hàm đăng nhập với Google
                            height: 50,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Image.asset(
                                //   'assets/images/google_logo.png', // Đảm bảo hình ảnh logo Google đã được thêm vào
                                //   height: 24,
                                //   width: 24,
                                // ),
                                SizedBox(width: 10),
                                Text(
                                  "Đăng nhập với Google",
                                  style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
