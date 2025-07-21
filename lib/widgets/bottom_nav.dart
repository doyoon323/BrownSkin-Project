import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final Color backgroundColor;
  final TextStyle? selectedLabelStyle;
  final BottomNavigationBarType type;
  final BoxShadow? boxShadow;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
    this.selectedItemColor = Colors.green,
    this.unselectedItemColor = const Color(0xFF94A3B8),
    this.backgroundColor = Colors.white,
    this.selectedLabelStyle,
    this.type = BottomNavigationBarType.fixed,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: boxShadow != null ? [boxShadow!] : [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        selectedLabelStyle: selectedLabelStyle ?? const TextStyle(fontWeight: FontWeight.w600),
        type: type,
        items: items,
      ),
    );
  }
}