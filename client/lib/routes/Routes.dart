import 'package:client/screen/Home_screen.dart';
import 'package:client/screen/Login_Screen.dart';
import 'package:client/screen/Profile_doctor.dart';
import 'package:client/screen/Register_Screen.dart';
import 'package:client/screen/UpdateDoctor.dart';
import 'package:client/screen/UpdateUserInfo.dart';
import 'package:client/screen/Hospital_screen.dart';
import 'package:client/screen/Profile.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String docprofile = '/docprofile';
  static const String updateProfile = '/update';
  static const String updateDocProfile = '/docupdate';
  static const String hospital = '/hospital';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => LoginPage(),
      register: (context) => RegisterPage(),
      home: (context) => HomeScreen(),
      hospital: (context) => ChooseHospital(),
      profile: (context) => UserInfo(),
      docprofile: (context) => DoctorInfo(),
      updateProfile: (context) => UpdateUserInfo(),
      updateDocProfile: (context) => UpdateDoctorInfo(),
    };
  }
}
