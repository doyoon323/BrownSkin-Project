import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brownskin_app/constants.dart';

class DistributorHomePage extends StatefulWidget {
  final String token;
  const DistributorHomePage({required this.token, super.key});

  @override
  State<DistributorHomePage> createState() => _DistributorHomePageState();
}

class _DistributorHomePageState extends State<DistributorHomePage> {
  String currentTab = '수거 요청';
  List<Map<String, dynamic>> allRequests = [];
  final statusMap = {
    'pending': '수거 요청',
    'accepted': '수거 대기',
    'transit': '배송중',
    'completed': '배송 완료',
  };

  @override
  void initState() {
    super.initState();
    fetchMyDeliveries();
  }

  Future<void> fetchMyDeliveries() async {
    final url = Uri.parse('$BASE_URL/api/my-delivery');
    final headers = {"Authorization": "Token ${widget.token}"};
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> rawList = parsed['results'];
        setState(() {
          allRequests = rawList.map<Map<String, dynamic>>((item) {
            return {
              'id': item['id'],
              'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
              'status': statusMap[item['status']] ?? item['status'],
              'rawStatus': item['status'],
              'date': item['req_date'],
              'addr': "${item['disposer']['addr1']} ${item['disposer']['addr2']} ${item['disposer']['addrDetail'] ?? ''}",
            };
          }).toList();
        });
      } else {
        print('서버 응답 오류: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '배송사 홈',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFF5F5DC),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabButton('수거 요청'),
                _buildTabButton('수거 대기'),
                _buildTabButton('배송중'),
                _buildTabButton('배송 완료'),
              ],
            ),
          ),
          Expanded(
            child: allRequests.where((e) => e['status'] == currentTab).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.brown[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '요청이 없습니다.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.brown[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: allRequests
                        .where((e) => e['status'] == currentTab)
                        .map(_buildRequestItem)
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) {
    bool isSelected = currentTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => currentTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD2B48C) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF8B4513) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF8B4513) : Colors.brown[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.brown[100]!, width: 1),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          item['item'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF5D4037),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "배출사 위치: ${item['addr']}\n상태: ${item['status']}\n요청일: ${item['date']}",
            style: TextStyle(
              color: Colors.brown[600],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        trailing: _buildActionButton(item),
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> item) {
    if (item['rawStatus'] == 'pending') {
      return ElevatedButton(
        onPressed: () => _acceptDelivery(item['id']),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B4513),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Text('수락', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (item['rawStatus'] == 'accepted') {
      return ElevatedButton(
        onPressed: () => _transitDelivery(item['id']),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA0522D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Text('수거 완료', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (item['rawStatus'] == 'transit') {
      return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCD853F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: const Text('배송 완료', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox();
  }

  Future<void> _acceptDelivery(int id) async {
    final url = Uri.parse('$BASE_URL/api/accept-delivery');
    final headers = {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    };
    try {
      final response = await http.post(url, headers: headers, body: {"id": "$id"});
      if (response.statusCode == 200) {
        fetchMyDeliveries();
      } else {
        print('수락 실패: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

  Future<void> _transitDelivery(int id) async {
    final url = Uri.parse('$BASE_URL/api/transit-delivery');
    final headers = {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    };
    try {
      final response = await http.post(url, headers: headers, body: {"id": "$id"});
      if (response.statusCode == 200) {
        fetchMyDeliveries();
      } else {
        print('수거 완료 실패: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }
}
