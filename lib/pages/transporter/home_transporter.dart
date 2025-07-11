import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/status_utils.dart';

class TransporterHomePage extends StatefulWidget {
  final String token;
  const TransporterHomePage({required this.token, super.key});

  @override
  State<TransporterHomePage> createState() => _TransporterHomePageState();
}

class _TransporterHomePageState extends State<TransporterHomePage> {
  String currentTab = '수거 요청';
  List<Map<String, dynamic>> allRequests = [];
  List<Map<String, dynamic>> completedRequests = [];
  final String role = 'transporter';

  // 통일된 갈색 테마
  static const Color primaryBrown = Color(0xFF8D6E63);
  static const Color lightBrown = Color(0xFFBCAAA4);
  static const Color darkBrown = Color(0xFF5D4037);
  static const Color backgroundBrown = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    fetchMyDeliveries();
    fetchCompletedDeliveries();
  }

  Future<void> fetchMyDeliveries() async {
    final rawList = await ApiService.fetchList(
      url: '$BASE_URL/api/my-delivery',
      token: widget.token,
    );
    if (!mounted) return;

    setState(() {
      allRequests = rawList.map<Map<String, dynamic>>((item) {
        String dateText = item['req_date'] ?? '';
        if (item['status'] == 'transit') {
          dateText = item['transit_date'] ?? '';
        }
        return {
          'id': item['id'],
          'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
          'status': getStatusLabelForRole(role, item['status']),
          'rawStatus': item['status'],
          'date': dateText,
          'disposer': item['disposer'],
          'preprocessor': item['preprocessor'],
        };
      }).toList();
    });
  }

  Future<void> fetchCompletedDeliveries() async {
    final completedList = await ApiService.fetchList(
      url: '$BASE_URL/api/my-history?status=completed',
      token: widget.token,
    );
    final deniedList = await ApiService.fetchList(
      url: '$BASE_URL/api/my-history?status=denied',
      token: widget.token,
    );

    if (!mounted) return;

    setState(() {
      completedRequests = [
        ...completedList.map<Map<String, dynamic>>((item) => {
              'id': item['id'],
              'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
              'status': '배송 완료',
              'rawStatus': 'completed',
              'date': item['complete_date'] ?? '',
              'disposer': item['disposer'],
              'preprocessor': item['preprocessor'],
            }),
        ...deniedList.map<Map<String, dynamic>>((item) => {
              'id': item['id'],
              'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
              'status': '거절',
              'rawStatus': 'denied',
              'date': item['complete_date'] ?? '',
              'disposer': item['disposer'],
              'preprocessor': item['preprocessor'],
            }),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBrown,
      appBar: AppBar(
        title: const Text('배송사 홈', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBrown,
        elevation: 4,
        shadowColor: darkBrown.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await fetchMyDeliveries();
              await fetchCompletedDeliveries();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('새로고침 완료')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: primaryBrown,
            ),
            child: Row(
              children: [
                _buildTabButton('수거 요청'),
                _buildTabButton('수거 대기'),
                _buildTabButton('배송중'),
                _buildTabButton('완료'),
              ],
            ),
          ),
          Expanded(
            child: (currentTab == '완료' ? completedRequests : allRequests.where((e) => e['status'] == currentTab)).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: lightBrown),
                        const SizedBox(height: 16),
                        Text('요청이 없습니다.',
                            style: TextStyle(fontSize: 18, color: darkBrown, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: (currentTab == '완료' ? completedRequests : allRequests.where((e) => e['status'] == currentTab))
                        .map(_buildRequestItem)
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
    final isSelected = currentTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          switch (title) {
            case '수거 요청':
            case '수거 대기':
            case '배송중':
              await fetchMyDeliveries();
              break;
            case '완료':
              await fetchCompletedDeliveries();
              break;
          }
          setState(() {
            currentTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? primaryBrown : primaryBrown.withOpacity(0.4),
            border: Border(
              bottom: BorderSide(color: isSelected ? Colors.white : Colors.transparent, width: 3),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 6,
      shadowColor: darkBrown.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryBrown, width: 1.5),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item['item'],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkBrown),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "배출사: ${item['disposer']['company_name']} (${item['disposer']['addr1']} ${item['disposer']['addr2']} ${item['disposer']['addrDetail']})\n"
            "전처리사: ${item['preprocessor']['company_name']} (${item['preprocessor']['addr1']} ${item['preprocessor']['addr2']} ${item['preprocessor']['addrDetail']})\n"
            "상태: ${getStatusLabelForRole(role, item['rawStatus'])}\n"
            "${getDateLabelForRole(role, item['rawStatus'])}: ${item['date']}",
            style: TextStyle(color: darkBrown.withOpacity(0.7), fontSize: 13, height: 1.4),
          ),
        ),
        trailing: _buildActionButton(item),
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> item) {
    if (item['rawStatus'] == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _acceptDelivery(item['id']),
            style: _buttonStyle(primaryBrown),
            child: const Text('수락', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _denyDelivery(item['id']),
            style: _buttonStyle(Colors.red.shade700),
            child: const Text('거절', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (item['rawStatus'] == 'accepted') {
      return ElevatedButton(
        onPressed: () => _transitDelivery(item['id']),
        style: _buttonStyle(primaryBrown),
        child: const Text('수거 완료', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (item['rawStatus'] == 'transit') {
      return ElevatedButton(
        onPressed: () => _completeDelivery(item['id']),
        style: _buttonStyle(primaryBrown),
        child: const Text('배송 완료', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox();
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
    );
  }

  Future<void> _acceptDelivery(int id) async {
    await _postToServer('/api/accept-delivery', id);
    fetchMyDeliveries();
  }

  Future<void> _denyDelivery(int id) async {
    await _postToServer('/api/deny-delivery', id);
    await fetchMyDeliveries();
    await fetchCompletedDeliveries();
  }

  Future<void> _transitDelivery(int id) async {
    await _postToServer('/api/transit-delivery', id);
    fetchMyDeliveries();
  }

  Future<void> _completeDelivery(int id) async {
    await _postToServer('/api/complete-delivery', id);
    await fetchMyDeliveries();
    await fetchCompletedDeliveries();
  }

  Future<void> _postToServer(String endpoint, int id) async {
    final url = Uri.parse('$BASE_URL$endpoint');
    final headers = {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    };
    try {
      final response = await http.post(url, headers: headers, body: {"id": "$id"});
      if (response.statusCode >= 400) {
        print('$endpoint 실패: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }
}
