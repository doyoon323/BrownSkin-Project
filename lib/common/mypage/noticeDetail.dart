import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets.dart';

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;
  static const Color lightBackground = Color(0xFFF8F6F4); 

  const NoticeDetailPage({super.key, required this.notice});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(
        context: context,
        title: '공지 상세',
        showBackButton: true,
        showActions: false,
      ),
      backgroundColor: lightBackground,
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

