import 'dart:convert';
import 'dart:core';
import 'package:brownskin_app/common/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/login/login_page.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  int? selectedReason;
  bool agreed = false;
  final _pwController = TextEditingController();

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('회원탈퇴')
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start, // <-- 좌측 정렬
          children: [
            const Text(
              '탈퇴 시 유의사항',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('탈퇴 시 유의사항 내용'),
            ),
            const SizedBox(height: 20),

            CheckboxListTile(
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text('위 내용을 모두 확인하였으며 이에 동의합니다'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 20),
            const Text(
              '탈퇴사유',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // 탈퇴 사유 목록
            for (int i = 0; i < 5; i++)
              RadioListTile(
                title: Text(i < 4 ? '탈퇴사유' : '기타'),
                value: i,
                groupValue: selectedReason,
                onChanged: (v) => setState(() => selectedReason = v),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),

            if (selectedReason == 4)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '기타 사유 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 24),
            TextField(
              controller: _pwController,
              decoration: const InputDecoration(
                labelText: '비밀번호 확인',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // 비밀번호니까 숨김 처리
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_valid()) {
                    await _deleteUser();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Text('회원탈퇴'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse("$BASE_URL/auth/api-account-delete");

    final request = http.MultipartRequest('DELETE', uri)
      ..fields['password'] = _pwController.text
      ..headers['Authorization'] = 'Token $token';

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("DELETE USER RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      _showMessage('탈퇴가 완료되었습니다.', isSuccess: true, onClose: () async {
        await prefs.remove('token');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
              (route) => false,
        );
      });
    } else {
      String errorMessage = '탈퇴에 실패했습니다.';
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          if (decoded.values.first is List) {
            errorMessage = decoded.values.first[0];
          } else if (decoded.containsKey("detail")) {
            errorMessage = decoded["detail"];
          } else if (decoded.containsKey("error")) {
            errorMessage = decoded["error"][0];
          }
        }
      _showMessage(errorMessage);
    }
  }

  bool _valid() {
    if (agreed == false) {
      _showMessage('유의사항을 체크해주세요.');
      return false;
    }
    if (selectedReason == null) {
      _showMessage('탈퇴사유를 선택하세요.');
      return false;
    }
    if (_pwController.text == null) {
      _showMessage('비밀번호를 입력하세요.');
      return false;
    }
    return true;
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
}