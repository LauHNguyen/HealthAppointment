import 'package:client/screen/Login_Screen.dart';
import 'package:client/screen/Register_Screen.dart';
// import 'package:client/screen/appointment_screen.dart';
import 'package:client/screen/hospital_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  // static const String appointment = '/appointment';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => LoginPage(),
      register: (context) => RegisterPage(),
      home: (context) => ChooseDoctor(),
    };
  }
}
