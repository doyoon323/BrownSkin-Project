import 'package:flutter/material.dart';

class NoticeListPage extends StatelessWidget {
  const NoticeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = List.generate(
      7,
          (index) => {'title': '공지사항', 'date': '0000-00-00'},
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('공지사항'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: notices.length,
        separatorBuilder: (_, __) =>  Divider(color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final item = notices[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            title: Text(
              item['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item['date']!),
            onTap: () {
              // 상세 페이지 이동 등 원하는 동작
            },
          );
        },
      ),
    );
  }
}