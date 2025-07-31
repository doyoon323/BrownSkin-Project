import 'package:flutter/material.dart';
import 'verification_page.dart';
import 'package:brownskin_app/common/themes.dart';
import 'package:brownskin_app/common/widgets.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  final List<Map<String, dynamic>> roles = const [
    {
      'value': 'disposer',
      'label': '배출사',
      'desc': '농부산물 추가/폐기 및 관리와 수거요청할 수 있어요',
      'icon': Icons.eco,
      'color': AppColors.darkBrown,
    },
    {
      'value': 'transporter',
      'label': '배송사',
      'desc': '농가의 농부산물을 전처리사로 배송해요',
      'icon': Icons.local_shipping,
      'color': AppColors.darkBrown,
    },
    {
      'value': 'preprocessor',
      'label': '전처리사',
      'desc': '농부산물을 전처리해요',
      'icon': Icons.build_circle,
      'color': AppColors.darkBrown,
    },
    {
      'value': 'client',
      'label': '고객',
      'desc': '필요한 가공농부산물을 주문해요(일반 고객)',
      'icon': Icons.shopping_bag,
      'color': AppColors.accentBrown,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBrown,
      appBar: buildCustomAppBar(
        context: context,
        title: '회원 유형 선택',
        showBackButton: true,
        showActions: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundBrown,
              AppColors.backgroundBrown.withOpacity(0.8),
            ],
          ),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final role = roles[index];
            return _buildRoleCard(context, role, index);
          },
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, Map<String, dynamic> role, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBrown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerificationPage(selectedRole: role['value']!),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 아이콘 컨테이너
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (role['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role['icon'] as IconData,
                    size: 30,
                    color: role['color'] as Color,
                  ),
                ),
                const SizedBox(width: 16),
                // 텍스트 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role['label']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        role['desc']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryBrown.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // 화살표 아이콘
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentBrown.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.primaryBrown,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
