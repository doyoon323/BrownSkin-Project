import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/themes.dart';
import '../../common/widgets.dart';

class FindAccountPage extends StatefulWidget {
  const FindAccountPage({super.key});

  @override
  State<FindAccountPage> createState() => _FindAccountPageState();
}

class _FindAccountPageState extends State<FindAccountPage> {
  int selectedTabIndex = 0;
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  List<String> foundUsernames = [];
  bool isLoading = false;

  void _switchTab(int index) {
    setState(() {
      selectedTabIndex = index;
      foundUsernames = [];
    });
  }

  Future<void> _findUsername() async {
    setState(() => isLoading = true);
    final url = Uri.parse('$BASE_URL/auth/api-find-username');
    final response = await http.post(url, body: {
      'email': emailController.text.trim(),
    });
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accounts = data['accounts'] as List;
      setState(() {
        foundUsernames = accounts.map((a) => a['username'].toString()).toList();
      });
    } else {
      _showMessage('아이디를 찾을 수 없습니다.');
    }
  }

  Future<void> _resetPassword() async {
    setState(() => isLoading = true);
    final url = Uri.parse('$BASE_URL/auth/api-password-reset-req');
    final response = await http.post(url, body: {
      'username': usernameController.text.trim(),
    });
    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _showMessage('이메일이 발송되었습니다: ${data['email_sent_to']}');
    } else {
      _showMessage('비밀번호 재설정 요청에 실패했습니다.');
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
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBrown : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBrown,
      appBar: buildCustomAppBar(
        context: context,
        title: '아이디/비밀번호 찾기',
        showBackButton: true,
        showActions: false,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildTabButton('아이디 찾기', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('비밀번호 찾기', 1),
                  ],
                ),
                const SizedBox(height: 24),
                if (selectedTabIndex == 0) ...[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일 주소',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _findUsername,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      '아이디 찾기', 
                      style: TextStyle(
                      color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (foundUsernames.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('가입된 아이디:'),
                        ...foundUsernames.map((u) => Text('• $u')).toList(),
                      ],
                    ),
                ] else ...[
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: '아이디',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      '비밀번호 재설정 메일 보내기', 
                      style: TextStyle(
                      color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
