class User {
  final String username;
  // final String email;
  final String password;

  User({required this.username, /*required this.email,*/ required this.password});

  // Chuyển đổi từ object thành JSON để gửi tới server
  Map<String, dynamic> toJson() {
    return {
      "username": username,
      // "email": email,
      "password": password,
    };
  }
}
