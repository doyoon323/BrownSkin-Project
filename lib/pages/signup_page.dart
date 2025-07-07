import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';
import 'dart:convert';
import 'login_page.dart';
import 'package:flutter/foundation.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

//입력창
class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _controllers = <String, TextEditingController>{
    'username': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'password2': TextEditingController(),
    'company': TextEditingController(),
    'addr1': TextEditingController(),
    'addr2': TextEditingController(),
    'addrDetail': TextEditingController(),
  };

  String? _selectedRole;
  String? _selectedType;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false; //요청 중 로딩 상태

//배송사, 전처리사 세부 타입
  static const Map<String, List<String>> _typeOptions = {
    'transporter': ['clean', 'normal'],
    'preprocessor': ['A', 'B', 'C', 'D'],
  };

//역할 선택 드롭다운 아이템
  static const List<DropdownMenuItem<String>> _roleItems = [
    DropdownMenuItem(value: 'disposer', child: Text('배출사')),
    DropdownMenuItem(value: 'transporter', child: Text('유통사')),
    DropdownMenuItem(value: 'preprocessor', child: Text('전처리사')),
  ];

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

//회원가입 요청 함수
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _submitRegistration();
      if (!mounted) return;

      if (response.statusCode == 201) { //회원가입 성공
        _showMessage('회원가입이 완료되었습니다!', isSuccess: true, onClose: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        });
      } else { //실패처리
        _handleRegistrationError(response);
      }
    } catch (e) {
      if (kDebugMode) print('네트워크 오류: $e');
      if (mounted) _showMessage('네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
//추가 폼 검증
  bool _validateForm() {
    if (_controllers['password']!.text != _controllers['password2']!.text) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return false;
    }
    if (_selectedRole == null) {
      _showMessage('역할을 선택하세요.');
      return false;
    }
    if (_typeOptions.containsKey(_selectedRole) && _selectedType == null) {
      _showMessage('세부 유형을 선택하세요.');
      return false;
    }
    return true;
  }

//서버에 회원가입 요청 보내기
  Future<http.Response> _submitRegistration() async {
    final body = <String, String>{
      'username': _controllers['username']!.text,
      'email': _controllers['email']!.text,
      'password': _controllers['password']!.text,
      'password2': _controllers['password2']!.text,
      'company_name': _controllers['company']!.text,
      'addr1': _controllers['addr1']!.text,
      'addr2': _controllers['addr2']!.text,
      'addrDetail': _controllers['addrDetail']!.text,
      'role': _selectedRole!,
    };

    if (_typeOptions.containsKey(_selectedRole)) {
      body['type'] = _selectedType!;
    }

    return await http.post(
      Uri.parse('$BASE_URL/auth/api-register'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: body,
    );
  }

//서버 에러처리
  void _handleRegistrationError(http.Response response) {
    String errorMsg = '회원가입에 실패했습니다.';
    try {
      final jsonData = jsonDecode(response.body);
      errorMsg = jsonData.toString();
    } catch (e) {
      if (kDebugMode) print('JSON 파싱 실패: $e');
    }
    _showMessage(errorMsg);
  }

//팝업 메시지 표시
  void _showMessage(String message, {bool isSuccess = false, VoidCallback? onClose}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 32,
        ),
        title: Text(isSuccess ? '성공' : '오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onClose != null) onClose();
            },
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
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.brown, Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: const [
          Icon(Icons.person_add_rounded, color: Colors.white, size: 40),
          SizedBox(height: 12),
          Text('회원가입', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text('Join BrownSkin', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField('아이디', 'username', TextInputType.text),
            _buildTextField('이메일', 'email', TextInputType.emailAddress),
            _buildPasswordField('비밀번호', 'password', _showPassword, () {
              setState(() => _showPassword = !_showPassword);
            }),
            _buildPasswordField('비밀번호 확인', 'password2', _showConfirmPassword, () {
              setState(() => _showConfirmPassword = !_showConfirmPassword);
            }),
            _buildTextField('회사명', 'company', TextInputType.text),
            _buildTextField('시도', 'addr1', TextInputType.text),
            _buildTextField('시군구', 'addr2', TextInputType.text),
            _buildTextField('상세 주소', 'addrDetail', TextInputType.text),
            const SizedBox(height: 8),
            _buildRoleDropdown(),
            if (_typeOptions.containsKey(_selectedRole)) _buildTypeDropdown(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label을(를) 입력하세요.';
          if (key == 'email' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(value)) {
            return '올바른 이메일 형식을 입력하세요.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(String label, String key, bool visible, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: !visible,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label을(를) 입력하세요.';
          if (key == 'password' && value.length < 6) {
            return '비밀번호는 6자 이상이어야 합니다.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '역할 선택',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
        ),
        value: _selectedRole,
        items: _roleItems,
        onChanged: (value) {
          setState(() {
            _selectedRole = value;
            _selectedType = null;
          });
        },
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '세부 유형 선택',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
        ),
        value: _selectedType,
        items: _typeOptions[_selectedRole]!
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) => setState(() => _selectedType = value),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: _isLoading ? null : _register,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_add_rounded),
                  SizedBox(width: 8),
                  Text('회원가입', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
