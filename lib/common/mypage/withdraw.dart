import 'dart:convert';
import 'dart:core';
import 'package:brownskin_app/common/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/login/login_page.dart';
import '../themes.dart';
import '../widgets.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  int? selectedReason;
  bool agreed = false;
  final _pwController = TextEditingController();

  static const Color mediumbackgroundBrown = Color(0xFF4A3429); // 짙은 갈색
  static const Color lightbackgroundBrown = Color(0xFF433228); // 중간 갈색
  static const Color lightBackground = Color(0xFFF8F6F4); // 매우 옅은 배경색

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(
        context: context,
        title: '회원 탈퇴',
        showBackButton: true,
        showActions: false,
      ),
      backgroundColor: lightBackground, // 옅은 배경색으로 변경
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '탈퇴 시 유의사항',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mediumbackgroundBrown), // 텍스트 색상 변경
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // 흰색 배경으로 변경
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: lightbackgroundBrown.withOpacity(0.3), width: 1), // 테두리 추가
                boxShadow: [
                  BoxShadow(
                    color: mediumbackgroundBrown.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '탈퇴 시 유의사항 내용', // 실제 유의사항 내용으로 교체 필요
                style: TextStyle(fontSize: 14, height: 1.6, color: mediumbackgroundBrown.withOpacity(0.8)), // 텍스트 색상 변경
              ),
            ),
            const SizedBox(height: 20),
            Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: mediumbackgroundBrown.withOpacity(0.6), // 체크박스 테두리 색상
              ),
              child: CheckboxListTile(
                value: agreed,
                onChanged: (v) => setState(() => agreed = v ?? false),
                title: const Text(
                  '위 내용을 모두 확인하였으며 이에 동의합니다',
                  style: TextStyle(color: mediumbackgroundBrown), // 텍스트 색상 변경
                ),
                activeColor: mediumbackgroundBrown, // 체크박스 활성화 색상
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '탈퇴사유',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: mediumbackgroundBrown), // 텍스트 색상 변경
            ),
            const SizedBox(height: 8),
            // 탈퇴 사유 목록
            for (int i = 0; i < 5; i++)
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: mediumbackgroundBrown.withOpacity(0.6), // 라디오 버튼 테두리 색상
                ),
                child: RadioListTile(
                  title: Text(
                    i < 4 ? '탈퇴사유 ${i + 1}' : '기타', // 예시 텍스트
                    style: TextStyle(color: mediumbackgroundBrown), // 텍스트 색상 변경
                  ),
                  value: i,
                  groupValue: selectedReason,
                  onChanged: (v) => setState(() => selectedReason = v),
                  activeColor: mediumbackgroundBrown, // 라디오 버튼 활성화 색상
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            if (selectedReason == 4)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '기타 사유 입력',
                    hintStyle: TextStyle(color: mediumbackgroundBrown.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white, // 흰색 배경
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: lightbackgroundBrown.withOpacity(0.3), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: lightbackgroundBrown.withOpacity(0.3), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: mediumbackgroundBrown, width: 1.5),
                    ),
                  ),
                  style: TextStyle(color: mediumbackgroundBrown), // 입력 텍스트 색상
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _pwController,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                labelStyle: TextStyle(color: mediumbackgroundBrown.withOpacity(0.8)), // 라벨 텍스트 색상
                filled: true,
                fillColor: Colors.white, // 흰색 배경
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: lightbackgroundBrown.withOpacity(0.3), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: lightbackgroundBrown.withOpacity(0.3), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: mediumbackgroundBrown, width: 1.5),
                ),
              ),
              obscureText: true, // 비밀번호니까 숨김 처리
              style: TextStyle(color: mediumbackgroundBrown), // 입력 텍스트 색상
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
                  backgroundColor: AppColors.primaryBrown, // 기존 primaryBrown 유지
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('회원탈퇴', style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (_pwController.text.isEmpty) {
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