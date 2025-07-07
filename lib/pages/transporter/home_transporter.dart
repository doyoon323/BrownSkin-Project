import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brownskin_app/constants.dart';

//StatefulWidget: 배송사 홈화면 위젯
class TransporterHomePage extends StatefulWidget {
  final String token;
  const TransporterHomePage({required this.token, super.key}); //토큰: 로그인 인증 토큰, API 호출 시 필요

//Stete 클래스 생성
  @override
  State<TransporterHomePage> createState() => _TransporterHomePageState();
}

//Stete 클래스: 주요 상태 및 변수 선언
class _TransporterHomePageState extends State<TransporterHomePage> {
  String currentTab = '수거 요청'; //현재 선택된 탭
  List<Map<String, dynamic>> allRequests = []; //진행중 요청들
  List<Map<String, dynamic>> completedRequests = []; //완료,거절 요청들

//상태맵: 서버에서 내려오는 상태코드를 한글로 변환
  final statusMap = {
    'pending': '수거 요청',
    'accepted': '수거 대기',
    'transit': '배송중',
    'completed': '배송 완료',
    'denied': '거절',
  };

//초기 데이터 로딩
  @override
  void initState() {
    super.initState();
    fetchMyDeliveries(); //진행중 요청 로딩
    fetchCompletedDeliveries(); //완료, 거절 요청 로딩
  }

//진행중 요청 불러오기
  Future<void> fetchMyDeliveries() async {
    final url = Uri.parse('$BASE_URL/api/my-delivery'); //API요청
    final headers = {"Authorization": "Token ${widget.token}"};
    try { //안전한 통신 위해서 try-catch 씀
      final response = await http.get(url, headers: headers);
      
      //정상 응답 처리
      if (response.statusCode == 200) { //
        final parsed = jsonDecode(utf8.decode(response.bodyBytes));
        final rawList = parsed['results'];
        setState(() { //데이터 변환 및 상태 저장
          allRequests = rawList.map<Map<String, dynamic>>((item) {
            
            //날짜 설정 로직
            String dateText = item['req_date'] ?? '';
            if (item['status'] == 'transit') {
              dateText = item['transit_date'] ?? '';
            }

            //맵 변환
            return {
              'id': item['id'],
              'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
              'status': statusMap[item['status']] ?? item['status'],
              'rawStatus': item['status'],
              'date': dateText,
              'disposer': item['disposer'],
              'preprocessor': item['preprocessor'],
            };
          }).toList();
        });

        //에러처리
      } else {
        print('진행중 데이터 오류: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

//완료, 거절 요청 불러오기
  Future<void> fetchCompletedDeliveries() async {
    //완료, 거절 각각 다른 상태 API로 호출
    final url = Uri.parse('$BASE_URL/api/my-history?status=completed');
    final urlDenied = Uri.parse('$BASE_URL/api/my-history?status=denied');
    final headers = {"Authorization": "Token ${widget.token}"};
    try {
      final responseCompleted = await http.get(url, headers: headers);
      final responseDenied = await http.get(urlDenied, headers: headers);

    //정상처리
      if (responseCompleted.statusCode == 200 && responseDenied.statusCode == 200) {
        final parsedCompleted = jsonDecode(utf8.decode(responseCompleted.bodyBytes));
        final parsedDenied = jsonDecode(utf8.decode(responseDenied.bodyBytes));

        final rawListCompleted = parsedCompleted['results'];
        final rawListDenied = parsedDenied['results'];

        //맵변환_완료&거절
        setState(() {
          completedRequests = [
            ...rawListCompleted.map<Map<String, dynamic>>((item) {
              return {
                'id': item['id'],
                'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
                'status': '배송 완료',
                'rawStatus': 'completed',
                'date': item['complete_date'] ?? '',
                'disposer': item['disposer'],
                'preprocessor': item['preprocessor'],
              };
            }),
            ...rawListDenied.map<Map<String, dynamic>>((item) {
              return {
                'id': item['id'],
                'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
                'status': '거절',
                'rawStatus': 'denied',
                'date': item['complete_date'] ?? '',
                'disposer': item['disposer'],
                'preprocessor': item['preprocessor'],
              };
            }),
          ];
        });
        //통신 실패 시 에러&예외처리
      } else {
        print('완료/거절 데이터 오류: ${responseCompleted.body} ${responseDenied.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

  //상태에 따른 날짜 라벨
  String _dateLabel(String status) {
    if (status == 'pending' || status == 'accepted') return '수거 요청일';
    if (status == 'transit') return '배송 시작일';
    if (status == 'completed') return '배송 완료일';
    if (status == 'denied') return '거절일';
    return '날짜';
  }

//여기부터는 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( //상단 앱 바
        title: const Text('배송사 홈', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFF5F5DC), //배경색
      body: Column(
        children: [
          Container( //탭 버튼 영역
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2)),
              ],
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
          Expanded( //요청 리스트 표시
            child: (currentTab == '완료' ? completedRequests : allRequests.where((e) => e['status'] == currentTab)).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.brown[300]),
                        const SizedBox(height: 16),
                        Text('요청이 없습니다.', style: TextStyle(fontSize: 18, color: Colors.brown[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(8),
                    children: (currentTab == '완료' ? completedRequests : allRequests.where((e) => e['status'] == currentTab))
                        .map(_buildRequestItem)
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title) { //탭 버튼 위젯
    bool isSelected = currentTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () async { //클릭 시 데이터 로딩(새로고침)
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD2B48C) : Colors.white,
            border: Border(
              bottom: BorderSide(color: isSelected ? const Color(0xFF8B4513) : Colors.transparent, width: 3),
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

  //요청 카드
  Widget _buildRequestItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.brown[100]!, width: 1)),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(item['item'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D4037))), //제목: 품목명, 타입, 무게
        subtitle: Padding( 
          padding: const EdgeInsets.only(top: 8),
          child: Text( //작은 글씨: 배출사+전처리사 정보, 상태, 날짜
            "배출사: ${item['disposer']['company_name']} (${item['disposer']['addr1']} ${item['disposer']['addr2']} ${item['disposer']['addrDetail']})\n"
            "전처리사: ${item['preprocessor']['company_name']} (${item['preprocessor']['addr1']} ${item['preprocessor']['addr2']} ${item['preprocessor']['addrDetail']})\n"
            "상태: ${item['status']}\n"
            "${_dateLabel(item['rawStatus'])}: ${item['date']}",
            style: TextStyle(color: Colors.brown[600], fontSize: 13, height: 1.4),
          ),
        ),
        trailing: _buildActionButton(item),
      ),
    );
  }

  //요청 상태에 따른 버튼(이거 누르면 다음으로 넘어감)
  Widget _buildActionButton(Map<String, dynamic> item) {
    if (item['rawStatus'] == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _acceptDelivery(item['id']),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4513), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2),
            child: const Text('수락', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _denyDelivery(item['id']),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA52A2A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2),
            child: const Text('거절', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (item['rawStatus'] == 'accepted') {
      return ElevatedButton(
        onPressed: () => _transitDelivery(item['id']),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA0522D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2),
        child: const Text('수거 완료', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (item['rawStatus'] == 'transit') {
      return ElevatedButton(
        onPressed: () => _completeDelivery(item['id']),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCD853F), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 2),
        child: const Text('배송 완료', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox();
  }

//수락 API 호출
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

//거절 API 호출
  Future<void> _denyDelivery(int id) async {
    final url = Uri.parse('$BASE_URL/api/deny-delivery');
    final headers = {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    };
    try {
      final response = await http.post(url, headers: headers, body: {"id": "$id"});
      if (response.statusCode == 200) {
        await fetchMyDeliveries();
        await fetchCompletedDeliveries();
      } else {
        print('거절 실패: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

//수거 완료 API 호출
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

//배송 완료 API 호출
  Future<void> _completeDelivery(int id) async {
    final url = Uri.parse('$BASE_URL/api/complete-delivery');
    final headers = {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    };
    try {
      final response = await http.post(url, headers: headers, body: {"id": "$id"});
      if (response.statusCode == 200) {
        await fetchMyDeliveries();
        await fetchCompletedDeliveries();
      } else {
        print('배송 완료 실패: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }
}
