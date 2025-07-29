import 'package:brownskin_app/common/themes.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/pages/agriculture/home_agriculture.dart';
import 'package:brownskin_app/pages/transporter/home_transporter.dart';
import 'package:brownskin_app/pages/preprocessor/home_preprocessor.dart';


class Tester extends StatelessWidget {

  Tester({super.key});


  final String disposer = "aaab7629a0f5d5cea77ccbb16f0e22c339572e04";
  final String preprocessor = "49aff36822888c39e580e305b1a4e5d64468e348";
  final String transporter = "af55792179c8576088626e856d47c98c231957fa";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          foregroundColor:Colors.white,
          backgroundColor: AppColors.primaryBrown,
          title:  Text(
              "분야별 테스트",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          )
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircleButton(
                icon: Icons.recycling, // 예: 분리수거 아이콘
                label: '분리배출',
                color: Colors.blue,
                onTap: () {
                  Navigator.push<int>(context,
                      MaterialPageRoute(builder: (context) => AgriHome(token: disposer)));
                },
              ),
              _buildCircleButton(
                icon: Icons.local_shipping, // 예: 배송 아이콘
                label: '유통업체',
                color: Colors.orange,
                onTap: () {
                  Navigator.push<int>(context,
                      MaterialPageRoute(builder: (context) => TransporterHomePage(token: transporter)));
                },
              ),

              _buildCircleButton(
                icon: Icons.factory,
                label: '전처리사',
                color: Colors.green,
                onTap: () {
                  Navigator.push<int>(context,
                      MaterialPageRoute(builder: (context) => PreprocessorHomePage(token: preprocessor)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}