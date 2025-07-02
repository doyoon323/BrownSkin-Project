import 'package:flutter/material.dart'; // 기본 UI 라이브러리 import

// 배송사 홈화면 StatefulWidget 정의 (상태 변화 필요)
class DistributorHomePage extends StatefulWidget {
  final String token; // 로그인 인증 토큰 (서버 요청시 사용)
  const DistributorHomePage({required this.token, super.key});

  @override
  State<DistributorHomePage> createState() => _DistributorHomePageState();
}

class _DistributorHomePageState extends State<DistributorHomePage> {
  String currentTab = '수거 요청'; // 현재 선택된 탭 상태 ('수거 요청', '수거 대기' 등)

  // 전체 수거/배송 요청 리스트 (더미데이터, 나중에 서버 데이터로 교체)
  List<Map<String, dynamic>> allRequests = [
    {"id": 1, "item": "사과", "status": "수거 요청", "date": ""},
    {"id": 2, "item": "배추", "status": "수거 대기", "date": "2025-07-01"},
    {"id": 3, "item": "참깨", "status": "배송중", "date": "2025-07-01"},
    {"id": 4, "item": "옥수수", "status": "배송 완료", "date": "2025-06-30"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('배송사 홈'), // 상단 앱바 제목
        backgroundColor: Colors.blue,  // 앱바 배경 색상
      ),
      body: Column(
        children: [
          // 탭 버튼 영역
          Row(
            children: [
              _buildTabButton('수거 요청'),
              _buildTabButton('수거 대기'),
              _buildTabButton('배송중'),
              _buildTabButton('배송 완료'),
            ],
          ),

          // 선택된 탭에 해당하는 리스트 출력
          Expanded(
            child: ListView(
              children: allRequests
                  .where((e) => e['status'] == currentTab) // 현재 탭과 상태가 같은 데이터만 필터링
                  .map((e) => _buildRequestItem(e))       // 각 데이터를 카드 형태로 변환
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  // 탭 버튼 UI 생성 함수
  Widget _buildTabButton(String title) {
    bool isSelected = currentTab == title; // 현재 선택된 탭인지 확인
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentTab = title; // 탭 변경
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          color: isSelected ? Colors.blue[100] : Colors.grey[200], // 선택된 탭만 색상 강조
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black, // 선택 여부에 따라 글자색 다르게
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 각 리스트 아이템 UI 생성 함수
  Widget _buildRequestItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(item['item']), // 품목명 출력
        subtitle: Text(
          '상태: ${item['status']}  ${item['date'] != "" ? _getDateText(item) : ""}', // 상태 및 날짜 출력
        ),
        trailing: _buildActionButton(item), // 상태에 따라 버튼 다르게 표시
      ),
    );
  }

  // 상태별로 다른 버튼 반환
  Widget _buildActionButton(Map<String, dynamic> item) {
    if (item['status'] == '수거 요청') {
      // 수거 요청 상태 → 수락 버튼
      return ElevatedButton(
        onPressed: () => _showDateInputDialog(item, '수거 대기'), // 수거 대기로 상태 변경
        child: const Text('수락'),
      );
    } else if (item['status'] == '수거 대기') {
      // 수거 대기 상태 → 수거 완료 버튼
      return ElevatedButton(
        onPressed: () => _showDateInputDialog(item, '배송중'), // 배송중으로 상태 변경
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text('수거 완료'),
      );
    } else if (item['status'] == '배송중') {
      // 배송중 상태 → 배송 완료 버튼
      return ElevatedButton(
        onPressed: () => _showDateInputDialog(item, '배송 완료'), // 배송 완료로 상태 변경
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('배송 완료'),
      );
    }
    // 나머지 상태는 버튼 없음
    return const SizedBox();
  }

  // 날짜 입력 다이얼로그 (공통으로 사용)
  void _showDateInputDialog(Map<String, dynamic> item, String nextStatus) {
    final TextEditingController dateController = TextEditingController(); // 날짜 입력용 컨트롤러

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('날짜 입력'),
        content: TextField(
          controller: dateController,
          decoration: const InputDecoration(
            hintText: '예: 2025-07-01', // 입력 예시
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // 취소 시 창 닫기
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (dateController.text.isEmpty) return; // 입력 없으면 아무 동작 안 함

              setState(() {
                item['status'] = nextStatus;         // 상태 변경
                item['date'] = dateController.text;  // 날짜 저장
              });
              Navigator.pop(context); // 창 닫기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 상태에 따라 날짜 문구 다르게 반환
  String _getDateText(Map<String, dynamic> item) {
    switch (item['status']) {
      case '수거 대기':
        return "수거 예정 날짜: ${item['date']}";
      case '배송중':
        return "수거 완료 날짜: ${item['date']}";
      case '배송 완료':
        return "배송 완료 날짜: ${item['date']}";
      default:
        return ""; // 기타 상태는 빈 문자열
    }
  }
}
