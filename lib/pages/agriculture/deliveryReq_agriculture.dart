import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brownskin_app/constants.dart';

class DeliveryReqAgriculturePage extends StatefulWidget {
  final String token; //로그인 토큰, API 호출에 사용
  final Map<String, List<Map<String, dynamic>>> userByproduct; //농가가 보유한 부산물정보(유형별 분류)

  const DeliveryReqAgriculturePage({required this.token, required this.userByproduct, super.key});

  @override //상태 위젯 생성
  State<DeliveryReqAgriculturePage> createState() => _DeliveryReqAgriculturePageState();
}

//State 클래서 변수 선언
class _DeliveryReqAgriculturePageState extends State<DeliveryReqAgriculturePage> { 
  String currentTab = '수거 요청'; //현재 선택 탭(수거 요청 or 나의 요청 이력)
  String? selectedType; //선택된 부산물 유형
  Map<String, dynamic>? selectedByproduct; //선택된 개별 품목
  final TextEditingController weightController = TextEditingController(); //무게 입력 필드 제어

  List<Map<String, dynamic>> myRequests = []; //진행중 요청 목록
  List<Map<String, dynamic>> completedRequests = []; //완료 및 거절 목록

  final statusMap = { //서버 상태 코드 -> 한글 변환 
    'pending': '수거 요청',
    'accepted': '요청 수락',
    'transit': '배송중',
    'completed': '배송 완료',
    'denied': '거절',
  };

  @override //초기 데이터 로딩(화면 생성 시, 내역 조회)
  void initState() {
    super.initState();
    fetchMyRequests();
    fetchCompletedRequests();
  }

//진행중 요청 조회
  Future<void> fetchMyRequests() async {
    if (!mounted) return;
    final url = Uri.parse('$BASE_URL/api/my-delivery'); //API 호출
    final headers = {"Authorization": "Token ${widget.token}"};
    try { //응답 처리
      final response = await http.get(url, headers: headers);
      if (!mounted) return;  // 중간 해체 방어

      if (response.statusCode == 200) { //정상 응답
        final parsed = jsonDecode(utf8.decode(response.bodyBytes));
        final rawList = parsed['results'];
        if (!mounted) return;
        setState(() { //상태 저장
          myRequests = rawList.map<Map<String, dynamic>>((item) {
            String dateText = item['req_date'] ?? '';
            if (item['status'] == 'transit') {
              dateText = item['transit_date'] ?? '';
            }
            return { //리스트 변환
              'id': item['id'],
              'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
              'status': item['status'],
              'date': dateText,
              'transporter': item['transporter'],
              'preprocessor': item['preprocessor'],
            };
          }).toList();
        });
      } else { //에러, 예외
        print('이력 조회 실패: ${response.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

  //완료 및 거절 요청 조회
  Future<void> fetchCompletedRequests() async {
    final urlCompleted = Uri.parse('$BASE_URL/api/my-history?status=completed');
    final urlDenied = Uri.parse('$BASE_URL/api/my-history?status=denied');
    final headers = {"Authorization": "Token ${widget.token}"};
    try {
      final responseCompleted = await http.get(urlCompleted, headers: headers);
      final responseDenied = await http.get(urlDenied, headers: headers);

      if (responseCompleted.statusCode == 200 && responseDenied.statusCode == 200) {
        final parsedCompleted = jsonDecode(utf8.decode(responseCompleted.bodyBytes));
        final parsedDenied = jsonDecode(utf8.decode(responseDenied.bodyBytes));

        final rawListCompleted = parsedCompleted['results'];
        final rawListDenied = parsedDenied['results'];

        if (!mounted) return;
        setState(() { 
          completedRequests = [
            ...rawListCompleted.map<Map<String, dynamic>>((item) { //응답 파싱 후 리스트 변환_배송완료
              return {
                'id': item['id'],
                'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
                'status': 'completed',
                'date': item['complete_date'] ?? '',
                'transporter': item['transporter'],
                'preprocessor': item['preprocessor'],
              };
            }),
            ...rawListDenied.map<Map<String, dynamic>>((item) { //응답 파싱 후 리스트 변환_거절
              return { 
                'id': item['id'],
                'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
                'status': 'denied',
                'date': item['complete_date'] ?? '',
                'transporter': item['transporter'],
                'preprocessor': item['preprocessor'],
              };
            }),
          ];
        });
      } else {
        print('완료/거절 조회 실패: ${responseCompleted.body} ${responseDenied.body}');
      }
    } catch (e) {
      print('네트워크 오류: $e');
    }
  }

  //상태별 날짜 라벨
  String _dateLabel(String status) {
    if (status == 'pending' || status == 'accepted') return '수거 요청일';
    if (status == 'transit') return '배송 시작일';
    if (status == 'completed') return '배송 완료일';
    if (status == 'denied') return '거절일';
    return '날짜';
  }

//전체UI 구성
  @override
  Widget build(BuildContext context) {
    return DefaultTabController( //탭구조
      length: 2,
      child: Builder(
        builder: (context) {

          //탭 변경 감지
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (tabController.indexIsChanging) return;
            if (tabController.index == 1) {
              fetchMyRequests();
              fetchCompletedRequests();
            }
          });

          return Scaffold(
            backgroundColor: Colors.brown[50],
            appBar: AppBar(
              title: const Text(
                '수거 요청 관리',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.brown[700],
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: '수거 요청 보내기'),
                  Tab(text: '나의 요청 이력'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildRequestForm(),
                _buildMyRequestList(),
              ],
            ),
          );
        },
      ),
    );
  }

  //수거요청 UI
  Widget _buildRequestForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownSection(), //유형 선택
          const SizedBox(height: 20),
          if (selectedType != null) _buildProductSection(), //품목 및 무게 입력
        ],
      ),
    );
  }

  Widget _buildDropdownSection() { //유형선택 드롭다운(수확, 가공)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>( 
        value: selectedType,
        hint: const Text("부산물 유형 선택"),
        isExpanded: true,
        decoration: const InputDecoration(border: InputBorder.none),
        items: widget.userByproduct.keys.map((type) {
          return DropdownMenuItem(value: type, child: Text(type));
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedType = value;
            selectedByproduct = null;
          });
        },
      ),
    );
  }

  Widget _buildProductSection() { //품목+무게입력
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedByproduct,
            hint: const Text("품목 선택"),
            isExpanded: true,
            decoration: const InputDecoration(border: InputBorder.none),
            items: widget.userByproduct[selectedType]!.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text("${item['name']} (남은 무게: ${item['weight_float']}kg)"),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedByproduct = value;
              });
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.brown.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('무게 입력 (kg)'),
              const SizedBox(height: 12),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "예: 100",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sendDeliveryRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('수거 요청 보내기'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //나의 요청 이력 
  Widget _buildMyRequestList() { 
    final allList = [...myRequests, ...completedRequests]; //진행중+완료/거절 내역 모두 합침
    if (allList.isEmpty) {
      return const Center(child: Text('요청 이력이 없습니다.'));
    }
    return ListView.builder( //카드 형태 리스트
      padding: const EdgeInsets.all(12),
      itemCount: allList.length,
      itemBuilder: (context, index) {
        final item = allList[index];
        String dateLabel = _dateLabel(item['status']);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
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
              child: Text( //배송사, 전처리사, 상태, 날짜 표시
                "배송사: ${item['transporter']['company_name']} (${item['transporter']['addr1']} ${item['transporter']['addr2']} ${item['transporter']['addrDetail']})\n"
                "전처리사: ${item['preprocessor']['company_name']} (${item['preprocessor']['addr1']} ${item['preprocessor']['addr2']} ${item['preprocessor']['addrDetail']})\n"
                "상태: ${statusMap[item['status']] ?? item['status']}\n"
                "${dateLabel}: ${item['date']}",
                style: TextStyle(
                  color: Colors.brown[600],
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //수거 요청 전송 로직
  Future<void> sendDeliveryRequest() async {

    //유효성 검사
    if (selectedType == null || selectedByproduct == null || weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 정보를 입력하세요")),
      );
      return;
    }

    final double? inputWeight = double.tryParse(weightController.text.trim());
    if (inputWeight == null || inputWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("유효한 무게를 입력하세요")),
      );
      return;
    }

    //API 요청
    final url = Uri.parse('$BASE_URL/api/dispose-req');
    final response = await http.post(url, headers: {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      "type": selectedType!,
      "name": selectedByproduct!["name"],
      "weight": weightController.text.trim(),
    });

    //정상 처리
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("요청이 성공적으로 전송되었습니다")),
      );

      if (!mounted) return;
      await fetchMyRequests();
      await fetchCompletedRequests();

      if (!mounted) return;

      setState(() {
        selectedType = null;
        selectedByproduct = null;
        weightController.clear();
      });
    } else {//에러처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("요청 실패: ${response.body}")),
      );
    }
  }
}
