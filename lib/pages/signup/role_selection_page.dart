import 'package:flutter/material.dart';
import 'verification_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  final List<Map<String, String>> roles = const [
    {'value': 'disposer', 'label': '분리/배출', 'desc': '농가에서 발생한 부산물을 판매할 수 있어요'},
    {'value': 'transporter', 'label': '수거', 'desc': '부산물을 수거하고 운반할 수 있어요'},
    {'value': 'preprocessor', 'label': '전처리', 'desc': '수거된 부산물을 전처리할 수 있어요'},
    {'value': 'client', 'label': '고객', 'desc': '서비스를 이용해 부산물 정보를 확인할 수 있어요'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원 유형 선택')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final role = roles[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(role['label']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(role['desc']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VerificationPage(selectedRole: role['value']!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
