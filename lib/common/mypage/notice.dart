import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:flutter/material.dart';
import '../themes.dart';
import 'noticeDetail.dart';

class NoticeListPage extends StatefulWidget {
  final String token;
  const NoticeListPage({super.key, required this.token});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  List<dynamic> _notices = [];
  String? _next;
  String? _previous;
  bool _isLoading = false;

  static const Color mediumbackgroundBrown = Color(0xFF4A3429);
  static const Color backgroundBrown = Color(0xFFD7CCC8);


  @override
  void initState() {
    super.initState();
    _fetchNotices('/notices/api/');
  }

  Future<void> _fetchNotices(String url) async {
    setState(() => _isLoading = true);

    final response = await ApiService.fetchMap(url: '$BASE_URL/notices/api/', token: widget.token);

    if (response != null) {
      setState(() {
        _notices = response['results'] ?? [];
        _next = response['next'];
        _previous = response['previous'];
      });
    }
    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항', style: TextStyle(color: backgroundBrown)),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: backgroundBrown,
        elevation: 0,
      ),

      backgroundColor: backgroundBrown,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _notices.isEmpty ? const Center(child: Text('공지사항이 없습니다.')) : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _notices.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white),
              itemBuilder: (context, index) {
                final item = _notices[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['created_at'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeDetailPage(notice: item),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (_previous != null)
                  TextButton(
                    onPressed: () => _fetchNotices(_previous!),
                    child: const Text('이전'),
                  ),
                if (_next != null)
                  TextButton(
                    onPressed: () => _fetchNotices(_next!),
                    child: const Text('다음'),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}