import 'package:flutter/material.dart';
import 'signup_form_page.dart';

class VerificationPage extends StatefulWidget {
  final String selectedRole;
  const VerificationPage({super.key, required this.selectedRole});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  String? _selectedType;

  final Map<String, List<String>> typeOptions = {
    'transporter': ['clean', 'normal'],
    'preprocessor': ['A', 'B', 'C', 'D'],
  };

  @override
  Widget build(BuildContext context) {
    final requiresType = typeOptions.containsKey(widget.selectedRole);
    final availableTypes = typeOptions[widget.selectedRole] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('사업자 인증')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '업체 확인을 위한\n사업자 등록증을 첨부해주세요',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '사업자 등록증 사진과 정보를 등록해주세요',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (requiresType)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('세부 유형 선택', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: availableTypes.map((type) => ChoiceChip(
                      label: Text(type),
                      selected: _selectedType == type,
                      onSelected: (_) {
                        setState(() => _selectedType = type);
                      },
                    )).toList(),
                  ),
                ],
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignUpFormPage(
                      selectedRole: widget.selectedRole,
                      selectedType: _selectedType,
                    ),
                  ),
                );
              },
              child: const Text('인증 완료'),
            )
          ],
        ),
      ),
    );
  }
}
