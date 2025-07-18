//공통위젯들을 뽑아놓은 파일입니다...

//카드형식, 액션버튼(상태변경)형식, 앱바, 텅 빈 위젯, 로그아웃버튼, 새로고침버튼


import 'package:flutter/material.dart';
import 'themes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brownskin_app/pages/login/login_page.dart'; 

//1. 카드

class InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color borderColor;
  final Color backgroundColor;
  final double elevation;

  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.borderColor = const Color(0xFF8D6E63), // 기본 갈색
    this.backgroundColor = Colors.white,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shadowColor: borderColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              subtitle,
              style: const TextStyle(height: 1.4),
            ),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}

//2. 버튼

class ActionButtonData {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const ActionButtonData({
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.primaryBrown,
  });
}

class ActionButtonGroup extends StatelessWidget {
  final List<ActionButtonData> buttons;
  final EdgeInsets spacing;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double elevation;

  const ActionButtonGroup({
    super.key,
    required this.buttons,
    this.spacing = const EdgeInsets.only(right: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.elevation = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons.asMap().entries.map((entry) {
        final index = entry.key;
        final btn = entry.value;
        final isLast = index == buttons.length - 1;

        return Padding(
          padding: isLast ? EdgeInsets.zero : spacing,
          child: ElevatedButton(
            onPressed: btn.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: btn.backgroundColor,
              foregroundColor: Colors.white,
              padding: padding,
              elevation: elevation,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
            ),
            child: Text(
              btn.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}

//3. 앱바

PreferredSizeWidget buildCommonAppBar({
  required String title,
  required VoidCallback onRefresh,
  required TabBar? tabBar,
}) {
  return AppBar(
    title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    backgroundColor: AppColors.primaryBrown,
    elevation: 4,
    shadowColor: AppColors.darkBrown,
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: onRefresh,
        ),
      ),
    ],
    bottom: tabBar,
  );
}

//4. 텅 비어있는 상태
Widget buildEmptyPlaceholder() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_outlined, size: 64, color: Colors.brown),
        const SizedBox(height: 16),
        Text(
          '비어있습니다',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}


// 5. 로그아웃 버튼 (페이지 어디서든 재사용 가능)
Widget buildLogoutIconButton(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: AppColors.darkBrown,
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      tooltip: '로그아웃',
      onPressed: () async {
        final navigator = Navigator.of(context); // ✅ context 안전하게 캐싱

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
    ),
  );
}


//6. 새로고침 버튼
Widget buildRefreshIconButton(
    BuildContext context, Future<void> Function() onPressed) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: AppColors.darkBrown,
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      tooltip: '새로고침',
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context); // ✅ 미리 저장

        await onPressed(); // 새로고침 수행

        messenger.showSnackBar(
          const SnackBar(content: Text('새로고침 완료')),
        );
      },
    ),
  );
}



