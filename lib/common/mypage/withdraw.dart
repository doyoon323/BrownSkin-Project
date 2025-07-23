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
      appBar: AppBar(title: const Text('회원탈퇴')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('탈퇴 시 유의사항', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16),
              child: const Text('탈퇴 시 유의사항 내용'),
            ),
            CheckboxListTile(
              value: agreed,
              onChanged: (v) => setState(() => agreed = v ?? false),
              title: const Text('위 내용을 모두 확인하였으며 이에 동의합니다'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('탈퇴사유')),
            for (int i = 0; i < 5; i++)
              RadioListTile(
                title: Text(i < 4 ? '탈퇴사유' : '기타'),
                value: i,
                groupValue: selectedReason,
                onChanged: (v) => setState(() => selectedReason = v),
              ),
            if (selectedReason == 4)
              const TextField(decoration: InputDecoration(hintText: '기타 사유 입력')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: '비밀번호 확인')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 회원 탈퇴 처리
              },
              child: const Text('회원탈퇴'),
            )
          ],
        ),
      ),
    );
  }
}