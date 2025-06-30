import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart';//이거 두 개 경로 그대로 가능. 내장 라이브러리
import 'package:http/http.dart' as http; 
import 'package:brownskin_app/constants.dart';
import 'dart:convert'; 
import 'signup_page.dart'; 
import 'home_agriculture.dart';
import 'home_admin.dart';

class LoginPage extends StatefulWidget { 
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController(); 

  void _login() async {
    var url = Uri.parse('$BASE_URL/auth/api-token');

    //서버로 아이디비번 전송하고 post  요청
    try { 
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      //200이면 성공, 토큰 출력, 실패 시 실패
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String token = data['token'];

        if (kDebugMode) print('로그인 성공, 토큰: $token');

        await _checkRoleAndMove(token); // 역할에 따라 화면 분기
      } else {
        _showMessage('로그인 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('네트워크 오류: $e');
      _showMessage('네트워크 오류 발생');
    }
  }

  Future<void> _checkRoleAndMove(String token) async {
    var url = Uri.parse('$BASE_URL/auth/api-profile');
    try {
      var response = await http.get(
        url,
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String role = data['role'];

        if (!mounted) return;

        if (role == 'disposer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AgriHome(token: token)),
          );
        } else if (role == 'other') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminHomePage(token: token)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        _showMessage('프로필 조회 실패: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('프로필 조회 오류: $e');
      _showMessage('네트워크 오류 발생');
    }
  }

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          )
        ],
      ),
    );
  }

//여기부터는 디자인툴
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(204),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        '로그인',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '계정에 로그인하여 시작하세요',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      _buildLabeledField('아이디', _usernameController, false, Icons.person),
                      _buildLabeledField('비밀번호', _passwordController, true, Icons.lock),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _login,
                          child: const Text('로그인', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.black26)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('또는', style: TextStyle(color: Colors.black54)),
                          ),
                          Expanded(child: Divider(color: Colors.black26)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          );
                        },
                        child: const Text('계정이 없으신가요? 회원가입', style: TextStyle(color: Colors.brown)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('© 2025 BrownSkin. All rights reserved.', style: TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller, bool obscure, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.brown),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
//여기까지 디자인

//로그인 성공 후 이동하는 Homepage-각 화면 구현되면 없앨 예정
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈 화면')),
      body: const Center(
        child: Text('로그인 성공! 홈 화면입니다.'),
      ),
    );
  }
}
