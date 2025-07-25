import 'package:daum_postcode_view/daum_postcode_view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/widgets.dart';
import 'package:brownskin_app/pages/signup/complete_page.dart';

class SignUpFormPage extends StatefulWidget {
  final String selectedRole;
  final String? selectedType;

  const SignUpFormPage({super.key, required this.selectedRole, this.selectedType});

  @override
  State<SignUpFormPage> createState() => _SignUpFormPageState();
}

class _SignUpFormPageState extends State<SignUpFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _controllers = <String, TextEditingController>{
    'username': TextEditingController(),
    'email': TextEditingController(),
    'password': TextEditingController(),
    'password2': TextEditingController(),
    'company': TextEditingController(),
    'address': TextEditingController(),
  };

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_controllers['password']!.text != _controllers['password2']!.text) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _submitRegistration();
      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignUpCompletePage()),
        );
      } else {
        _handleRegistrationError(response);
      }
    } catch (e) {
      if (kDebugMode) print('네트워크 오류: $e');
      if (mounted) _showError('네트워크 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<http.Response> _submitRegistration() async {
    final address = (_controllers['address']!.text.trim()).split(RegExp(r'\s+'));

    final body = <String, String>{
      'username': _controllers['username']!.text,
      'email': _controllers['email']!.text,
      'password': _controllers['password']!.text,
      'password2': _controllers['password2']!.text,
      'company_name': _controllers['company']!.text,
      'addr1': address.isNotEmpty ? address[0] : '',
      'addr2': address.length > 1 ? address[1] : '',
      'addrDetail': address.length > 2 ? address.sublist(2).join(' ') : '',
      'role': widget.selectedRole,
    };

    if (widget.selectedType != null) {
      body['type'] = widget.selectedType!;
    }

    return await http.post(
      Uri.parse('$BASE_URL/auth/api-register'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: body,
    );
  }

  void _handleRegistrationError(http.Response response) {
    String errorMsg = '회원가입에 실패했습니다.';
    try {
      final jsonData = jsonDecode(response.body);
      errorMsg = jsonData.toString();
    } catch (e) {
      if (kDebugMode) print('JSON 파싱 실패: $e');
    }
    _showError(errorMsg);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('회원 정보 입력')),
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
            _buildPostcodeField('주소','address',TextInputType.text),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostcodeField(String label,String key,  TextInputType type){
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Flexible(fit: FlexFit.tight, flex : 3, child: _buildTextField(label, key, type) ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            child: ActionButtonGroup(
              buttons: [ ActionButtonData(
                  label: '주소 검색',
                  backgroundColor: Colors.brown,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => DaumPostcodeView(
                        onComplete: (DaumPostcodeModel result) {
                          Navigator.of(context).pop({'address': result.address,});
                        }))
                    );
                    if (result != null) _controllers[key]!.text = result['address'];
                  })
              ]),
          ),
        ],
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
          if (key == 'email' && !RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w]{2,}$').hasMatch(value)) {
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