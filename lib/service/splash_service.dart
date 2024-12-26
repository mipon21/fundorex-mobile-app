import 'package:flutter/material.dart';
import 'package:fundorex/service/auth_services/google_sign_service.dart';
import 'package:fundorex/service/auth_services/login_service.dart';
import 'package:fundorex/view/auth/login/login.dart';
import 'package:fundorex/view/home/landing_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view/utils/responsive.dart';

class SplashService {
  loginOrGoHome(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //that means user is opening the app for the first time.. so , show the intro
    Future.delayed(const Duration(seconds: 2), () {});
  }
}
