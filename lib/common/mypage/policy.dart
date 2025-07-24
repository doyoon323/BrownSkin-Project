import 'package:flutter/material.dart';

class PolicyListPage extends StatelessWidget {
  const PolicyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final policies = [
      '서비스 이용약관',
      '개인정보 처리방침',
      '운영정책',
      '위치기반서비스이용약관',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('< 약관 및 정책')
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: policies.length,
        itemBuilder: (_, index) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(policies[index], style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 정책 상세 이동
            },
          );
        },
      ),
    );
  }
}