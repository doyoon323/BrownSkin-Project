import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../themes.dart';

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;
  static const Color backgroundBrown = Color(0xFFD7CCC8);

  const NoticeDetailPage({super.key, required this.notice});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지 상세',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: backgroundBrown,
      ),
      backgroundColor: backgroundBrown,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('작성자: ${notice['author_username'] ?? ''}'),
            Text('작성일: ${notice['created_at'] ?? ''}'),
            const Divider(height: 32,color: Colors.black,),
            Expanded(child: SingleChildScrollView(child: Text(notice['content'] ?? ''))),
          ],
        ),
      ),
    );
  }
}

