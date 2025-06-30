import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';
import 'dart:convert';
import 'login_page.dart';
import 'package:flutter/foundation.dart'; //회원가입 성공 시 로그인 화면으로 이동

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

//입력창
class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _companyController = TextEditingController();
  final _addr1Controller = TextEditingController(); // 시도
  final _addr2Controller = TextEditingController(); // 시군구
  final _addrDetailController = TextEditingController(); // 상세주소

  //드롭다운, 비번가리기 등등
  String? _selectedRole;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  //회원가입 처리 함수
  void _register() async {
    if (_passwordController.text != _password2Controller.text) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }
    if (_selectedRole == null) {
      _showMessage('역할을 선택하세요.');
      return;
    }
    //서버로 데이터 전송
    var url = Uri.parse('$BASE_URL/auth/api-register');

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'password2': _password2Controller.text,
          'company_name': _companyController.text,
          'addr1': _addr1Controller.text,
          'addr2': _addr2Controller.text,
          'addrDetail': _addrDetailController.text,
          'role': _selectedRole!,
        },
      );

      if (!mounted) return; // context 안전 처리
      //응답 결과 처리
      if (response.statusCode == 201) {
        _showMessage('회원가입 성공');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        String errorMsg = response.body;
        try {
          var jsonData = jsonDecode(response.body);
          errorMsg = jsonData.toString();
        } catch (e) {
          if (kDebugMode) {
            print('JSON 파싱 실패: $e');
          }
        }
        _showMessage('회원가입 실패: $errorMsg');
      }
    } catch (e) {
      if (kDebugMode) {
        print('네트워크 오류: $e');
      }
      if (mounted) {
        _showMessage('네트워크 오류 발생');
      }
    }
  }

  //팝업메시지
  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  //여기부터는 디자인툴
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white54,
      body: Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(242), // withOpacity 대체
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.brown,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.person_add, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Join BrownSkin',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLabeledField(
                      '아이디',
                      _usernameController,
                      TextInputType.text,
                    ),
                    _buildLabeledField(
                      '이메일',
                      _emailController,
                      TextInputType.emailAddress,
                    ),
                    _buildPasswordField(
                      '비밀번호',
                      _passwordController,
                      _showPassword,
                      () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    _buildPasswordField(
                      '비밀번호 확인',
                      _password2Controller,
                      _showConfirmPassword,
                      () {
                        setState(
                          () => _showConfirmPassword = !_showConfirmPassword,
                        );
                      },
                    ),
                    _buildLabeledField(
                      '회사명',
                      _companyController,
                      TextInputType.text,
                    ),
                    _buildLabeledField(
                      '시도',
                      _addr1Controller,
                      TextInputType.text,
                    ),
                    _buildLabeledField(
                      '시군구',
                      _addr2Controller,
                      TextInputType.text,
                    ),
                    _buildLabeledField(
                      '상세 주소',
                      _addrDetailController,
                      TextInputType.text,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: '역할 선택',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'disposer', child: Text('배출사')),
                        DropdownMenuItem(
                          value: 'distributor',
                          child: Text('유통사'),
                        ),
                        DropdownMenuItem(
                          value: 'preprocessor',
                          child: Text('전처리사'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedRole = value),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _register,
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        '회원가입',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledField(
    String label,
    TextEditingController controller,
    TextInputType type,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool visible,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }
}
