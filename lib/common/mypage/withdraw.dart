import 'package:flutter/material.dart';

class WithdrawalPage extends StatefulWidget {
  const WithdrawalPage({super.key});

  @override
  State<WithdrawalPage> createState() => _WithdrawalPageState();
}

class _WithdrawalPageState extends State<WithdrawalPage> {
  int? selectedReason;
  bool agreed = false;

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
            const TextField(
              decoration: InputDecoration(labelText: '비밀번호 확인', border: OutlineInputBorder(),),
            ),
            const SizedBox(height: 32),
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
                child: const Text('회원탈퇴'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}