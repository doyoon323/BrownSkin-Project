import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../themes.dart';


class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPWController = TextEditingController();
  final _newPWController = TextEditingController();
  final _checkPWController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureCheck = true;

  static const Color backgroundBrown = Color(0xFFD7CCC8);

  @override
  void dispose() {
    _oldPWController.dispose();
    _newPWController.dispose();
    _checkPWController.dispose();
    super.dispose();
  }

  bool _validPW() {
    final newPW = _newPWController.text;
    final checkPW = _checkPWController.text;

    if (newPW.length < 8) {
      _showMessage("비밀번호는 최소 8자 이상이어야 합니다.");
      return false;
    }
    if (newPW != checkPW) {
      _showMessage("새 비밀번호가 일치하지 않습니다.");
      return false;
    }
    return true;
  }

  Future<void> _postPW() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$BASE_URL/auth/api-password-change');

    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Token $token'
      ..fields['current_password'] = _oldPWController.text
      ..fields['new_password'] = _newPWController.text
      ..fields['new_password_confirm'] = _checkPWController.text;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _showMessage('비밀번호가 성공적으로 변경되었습니다.', isSuccess: true, onClose: () {
          Navigator.pop(context); // 뒤로가기
        });
      } else {
        String errorMessage = '비밀번호 변경에 실패했습니다.';
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            if (data.values.first is List) {
              errorMessage = data.values.first[0];
            } else if (data.containsKey("detail")) {
              errorMessage = data["detail"];
            } else if (data.containsKey("error")) {
              errorMessage = data["error"][0];
            }
          }
        } catch (e) {
          debugPrint("파싱 실패: $e");
        }
        _showMessage(errorMessage);
      }
    } catch (e) {
      _showMessage("네트워크 오류가 발생했습니다.");
    }
  }

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

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),);
  }

  Widget _buildPasswordField(TextEditingController controller, {required bool obscure, required VoidCallback toggle}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBrown,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrown,
        title: const Text('비밀번호 변경', style: TextStyle(color: Colors.white),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('현재 비밀번호'),
            const SizedBox(height: 14),
            _buildPasswordField(
              _oldPWController,
              obscure: _obscureOld,
              toggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 25),

            _buildLabel('새 비밀번호'),
            const SizedBox(height: 14),
            _buildPasswordField(
              _newPWController,
              obscure: _obscureNew,
              toggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 25),

            _buildLabel('새 비밀번호 확인'),
            const SizedBox(height: 14),
            _buildPasswordField(
              _checkPWController,
              obscure: _obscureCheck,
              toggle: () => setState(() => _obscureCheck = !_obscureCheck),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_validPW()) _postPW();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('수정 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}