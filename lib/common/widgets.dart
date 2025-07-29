//공통위젯들을 뽑아놓은 파일입니다...


import 'package:flutter/material.dart';
import 'mypage/home.dart';
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

//2. 액션버튼

class ActionButtonData {
  final String label;
  final VoidCallback onPressed;
  final ButtonStyle? style;
  final Color backgroundColor;

  const ActionButtonData({
    required this.label,
    required this.onPressed,
    this.style,
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
            style: btn.style ?? ElevatedButton.styleFrom(
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



//2-2 single button (추후 통합)

class SingleActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double borderRadius;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const SingleActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
    this.borderRadius = 2,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(vertical: 16)
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius),),
        ),
        child: Text(label, style: TextStyle(fontSize: fontSize))
      ),
    );
  }
}

//3. 앱바 (전처리, 수거, 농가)

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
    bottom: tabBar ,
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
Widget buildLogoutIconButton(BuildContext context, {Color? backgroundColor}) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: backgroundColor ?? AppColors.darkBrown,
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      icon: const Icon(Icons.logout, color: Colors.white),
      tooltip: '로그아웃',
      onPressed: () async {
        final navigator = Navigator.of(context);

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
    BuildContext context, Future<void> Function() onPressed, {Color? backgroundColor}) {
  return Container(
    margin: const EdgeInsets.only(right: 8),
    decoration: BoxDecoration(
      color: backgroundColor ?? AppColors.darkBrown,
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



//8. 하단 메뉴바
class BottomNavItem {
final IconData icon;
final String label;
final VoidCallback onTap;
final bool isSelected;

BottomNavItem({required this.icon, required this.label, required this.onTap, this.isSelected = false, Color? color});
}

Widget bottomNavigationBar(BuildContext context, List<BottomNavItem> items, {Color? color}) {
  return BottomAppBar(
    color: color ?? Colors.white,
    child: SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => GestureDetector(
          onTap: item.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: item.isSelected ? Colors.brown : Colors.grey[400]),
              Text(item.label, style: TextStyle(color: item.isSelected ? Colors.brown : Colors.grey[400], fontSize: 12)),
            ],
          ))).toList(),
      ),
    ),
  );
}

//9. 드롭다운
class CommonDropdownField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final void Function(String?)? onChanged;
  final String hintText;
  final bool isEnabled;

  const CommonDropdownField({super.key, required this.value, required this.items, required this.onChanged, this.hintText = '', this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: isEnabled ? onChanged : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isEnabled ? Colors.grey[50] : Colors.grey[200],
      ),
      hint: Text(hintText),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList()
    );
  }
}


//10. 로딩
Widget buildLoadingWidget() {
  return Center(
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600), strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          Text('데이터를 불러오는 중...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text('잠시만 기다려주세요', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    ),
  );
}

//10. 확인팝업
void showConfirmPopup({
  required BuildContext context,
  required String typeLabel,          // ex: 수확
  required String productName,        // ex: 사과
  required String weightText,         // ex: 100
  required String actionText,         // ex: '부산물을 등록하시겠습니까?'
  required VoidCallback onConfirm,    // 확인 버튼 눌렀을 때 실행할 함수
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  const TextSpan(text: '[ ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: typeLabel, style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' ] '),
                  TextSpan(text: productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' ${weightText}kg', style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
                  TextSpan(text: '\n$actionText'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

//11. 마이페이지 접속 버튼
Widget buildMyPageIconButton(BuildContext context, String token, {Color? color}) {
  return IconButton(
    icon: Icon(Icons.person, color: Colors.white),
    tooltip: '마이페이지',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyPageScreen(token: token)),
      );
    },
  );
}

