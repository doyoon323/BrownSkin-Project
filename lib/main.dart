import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:brownskin_app/pages/login/login_page.dart'; 
import 'package:brownskin_app/pages/agriculture/home_agriculture.dart';
import 'package:brownskin_app/pages/transporter/home_transporter.dart';
import 'package:brownskin_app/pages/preprocessor/home_preprocessor.dart';
import 'package:brownskin_app/pages/admin/admin_home.dart';
import 'package:brownskin_app/common/constants.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 비동기 초기화

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token'); // 저장된 토큰 읽기

  runApp(MyApp(initialToken: token));
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  const MyApp({super.key, required this.initialToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brownskin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: initialToken == null
          ? const LoginPage()
          : FutureBuilder<Widget>(
              future: _checkTokenAndNavigate(initialToken!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return snapshot.data!;
                } else {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
              },
            ),
    );
  }

  // 토큰으로 유저 정보 조회 → 역할 따라 홈 이동
  Future<Widget> _checkTokenAndNavigate(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/auth/api-profile'),
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final role = data['role'];

        if (role == 'disposer') return AgriHome(token: token);
        if (role == 'transporter') return TransporterHomePage(token: token);
        if (role == 'preprocessor') return PreprocessorHomePage(token: token);
        if (role == 'other') return AdminHomePage(token: token);
      }
    } catch (e) {
      debugPrint('자동 로그인 실패: $e');
    }

    // 실패했으면 로그인 페이지로 돌아감
    return const LoginPage();
  }
}
