import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:flutter/material.dart';
import '../widgets.dart';
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
  static const Color lightbackgroundBrown = Color(0xFF433228);
  static const Color cardBrown = Color(0xFFEFEBE9);
  static const Color lightBackground = Color(0xFFF8F6F4); // 이전 페이지와 동일한 옅은 배경색

  @override
  void initState() {
    super.initState();
    _fetchNotices('/notices/api/');
  }

  Future<void> _fetchNotices(String url) async {
    setState(() => _isLoading = true);
    final response = await ApiService.fetchMap(url: '$BASE_URL/notices/api/', token: widget.token);
    if (response.isNotEmpty) {
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
      appBar: buildCustomAppBar(
        context: context,
        title: '공지사항',
        showBackButton: true,
        showActions: false,
      ),
      backgroundColor: lightBackground, // 옅은 배경색으로 변경
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : _notices.isEmpty ? const Center(child: Text('공지사항이 없습니다.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final item = _notices[index];
                return _buildMenuItem(
                  title: item['title'] ?? '제목 없음',
                  subtitle: item['created_at'] ?? '',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NoticeDetailPage(notice: item)),
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
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: mediumbackgroundBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('이전'),
                  ),
                if (_next != null)
                  TextButton(
                    onPressed: () => _fetchNotices(_next!),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: mediumbackgroundBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('다음'),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white, // 흰색 배경으로 변경
        boxShadow: [
          BoxShadow(
            color: mediumbackgroundBrown.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 17, 
            color: mediumbackgroundBrown, // 짙은 갈색으로 변경
            letterSpacing: 0.3
          ),
        ),
        subtitle: subtitle != null ? Text(
            subtitle,
            style: TextStyle(
              fontSize: 13, 
              color: mediumbackgroundBrown.withOpacity(0.6) // 짙은 갈색의 투명도 버전
            )
        ) : null,
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mediumbackgroundBrown, // 짙은 갈색 배경
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.chevron_right,
            color: Colors.white, // 흰색 화살표
            size: 20,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: lightbackgroundBrown.withOpacity(0.1),
        splashColor: cardBrown.withOpacity(0.1),
      ),
    );
  }
}