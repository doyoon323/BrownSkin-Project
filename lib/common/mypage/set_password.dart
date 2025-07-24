import 'package:brownskin_app/common/mypage/profile.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatelessWidget {
   ChangePasswordPage({super.key});

  final _oldPWcontroller = TextEditingController();
  final _newPWController = TextEditingController();
  final _checkPWController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('비밀번호 변경'))
      ,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [

            _buildLabel('현재 비밀번호'),
            const SizedBox(height: 14),
            _buildTextField(_oldPWcontroller, hint: ''),
            const SizedBox(height: 25),

            _buildLabel('새 비밀번호'),
            const SizedBox(height: 14),
            _buildTextField(_newPWController, hint: ''),
            const SizedBox(height: 25),

            _buildLabel('새 비밀번호 확인'),
            const SizedBox(height: 14),
            _buildTextField(_checkPWController, hint: ''),
            const SizedBox(height: 25),


            SizedBox(height: 20),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Text('수정 완료'),
              ),
            ),

          ],
        ),
      ),
    );
  }


  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
  }


  Widget _buildTextField(TextEditingController controller, {String? hint}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

}