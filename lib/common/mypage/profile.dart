import 'package:brownskin_app/common/mypage/set_password.dart';
import 'package:brownskin_app/common/mypage/withdraw.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _idController = TextEditingController(text: '아이디');
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bizNumberController = TextEditingController();
  final _corpNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _bizTypeController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: const Text('정보 수정', style: TextStyle(color: Colors.black)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),


      body:
      SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('아이디'),
            const SizedBox(height: 14),

            _buildReadOnlyBox(_idController),
            const SizedBox(height: 20),
            _buildLabel('비밀번호'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>  ChangePasswordPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Text('비밀번호 변경'),
              ),
            ),
            const SizedBox(height: 24),


            _buildLabel('이름'),
            const SizedBox(height: 14),
            _buildTextField(_nameController, hint: '이름'),
            const SizedBox(height: 20),

            _buildLabel('전화번호'),
            const SizedBox(height: 14),
            _buildTextField(_phoneController, hint: '전화번호'),
            const SizedBox(height: 32),

            const Text('기업정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _buildLabel('사업자등록번호'),
            const SizedBox(height: 14),
            _buildTextField(_bizNumberController, hint: '123-45-67890'),
            const SizedBox(height: 20),

            _buildLabel('상호(법인명)'),
            const SizedBox(height: 14),
            _buildTextField(_corpNameController, hint: '상호명'),
            const SizedBox(height: 20),

            _buildLabel('사업장주소'),
            const SizedBox(height: 14),
            _buildTextField(_addressController, hint: '주소'),
            const SizedBox(height: 20),

            _buildLabel('업태'),
            const SizedBox(height: 14),
            _buildTextField(_bizTypeController, hint: '도소매업'),
            const SizedBox(height: 20),

            _buildLabel('종목'),
            const SizedBox(height: 14),
            _buildTextField(_categoryController, hint: '식품 소매업'),
            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WithdrawalPage()),
                  );
                },
                child: const Text(
                  '회원탈퇴',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    decoration: TextDecoration.underline, // (선택) 밑줄 강조
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100), // 하단 버튼 가려지지 않도록 여유 여백
          ],
        ),
      ),

      // ✔ 수정완료 버튼은 고정
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // 수정 완료 처리
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: const Text('수정완료', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500));
  }


  Widget _buildReadOnlyBox(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black12,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3), // 둥글기 정도 조절
          borderSide: BorderSide.none, // 테두리 없음
        ),
      ),
    );
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