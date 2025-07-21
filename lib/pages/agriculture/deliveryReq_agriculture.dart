// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/status_utils.dart';
import 'package:brownskin_app/pages/agriculture/delivery_tracking.dart';
import 'package:brownskin_app/common/themes.dart';
import 'package:brownskin_app/common/widgets.dart';


class DeliveryReqAgriculturePage extends StatefulWidget {
  final String token; //로그인 토큰, API 호출에 사용
  final Map<String, List<Map<String, dynamic>>> userByproduct; //농가가 보유한 부산물정보(유형별 분류)

  const DeliveryReqAgriculturePage({required this.token, required this.userByproduct, super.key});

  @override //상태 위젯 생성
  State<DeliveryReqAgriculturePage> createState() => _DeliveryReqAgriculturePageState();
}

//STate 함수 안의 변수들 선언하기
class _DeliveryReqAgriculturePageState extends State<DeliveryReqAgriculturePage> { 
  String currentTab = '수거 요청'; //현재 선택 탭(수거 요청 or 나의 요청 이력)
  String? selectedType; //선택된 부산물 유형
  Map<String, dynamic>? selectedByproduct; //선택된 개별 품목
  final String role = 'disposer';
  final TextEditingController weightController = TextEditingController(); //무게 입력 필드 제어

  List<Map<String, dynamic>> myRequests = []; //진행중 요청 목록
  List<Map<String, dynamic>> completedRequests = []; //완료 및 거절 목록

  

  @override //초기 데이터 로딩(화면 생성 시, 내역 조회)
  void initState() {
    super.initState();
    fetchMyRequests();
    fetchCompletedRequests();
  }

//fetchmyRequest=진행중 요청 조회
  Future<void> fetchMyRequests() async {
  final rawList = await ApiService.fetchList(
    url: '$BASE_URL/api/my-delivery',
    token: widget.token,
  );

  if (!mounted) return;

  setState(() {
    myRequests = rawList.map<Map<String, dynamic>>((item) {
      String dateText = item['req_date'] ?? ''; //기본은 기본
      if (item['status'] == 'transit') { //배송중일 때 배송 시작일 보여줌
        dateText = item['transit_date'] ?? '';
      }
      return {
        'id': item['id'],
        'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
        'status': item['status'],
        'date': dateText,
        'transporter': item['transporter'],
        'preprocessor': item['preprocessor'],
      };
    }).toList();
  });
}

  //fetchCompletedRquests=완료 및 거절 요청 조회
  Future<void> fetchCompletedRequests() async {
  final all = await ApiService.fetchList(
    url: '$BASE_URL/api/my-history',
    token: widget.token,
  );

  if (!mounted) return;

  setState(() {
    completedRequests = all.map<Map<String, dynamic>>((item) {
      return { //서버데이터를 리스트타일 형태로 가공
        'id': item['id'],
        'item': "${item['name']} (${item['type']}) ${item['weight_float'] ?? 0}kg",
        'status': getStatusLabelForRole(role, item['status']),
        'rawStatus': item['status'],
        'date': item['complete_date'] ?? '',
        'transporter': item['transporter'],
        'preprocessor': item['preprocessor'],
      };
    }).toList();
  });
}



//전체UI 구성
  @override
  Widget build(BuildContext context) {
    return DefaultTabController( //탭구조
      length: 2,
      child: Builder(
        builder: (context) {

          //탭 변경 감지해서 변경할때마다 새로고침(tabcontroller로 탭 인덱스 추적)
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (tabController.indexIsChanging) return;
            if (tabController.index == 1) {
              fetchMyRequests();
              fetchCompletedRequests();
            }
          });

          return Scaffold(
            backgroundColor: AppColors.backgroundBrown,
            //상단앱바
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text('수거 요청 관리', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.primaryBrown,
              elevation: 4,
              shadowColor: AppColors.darkBrown ,
              actions: [ //상단에 새로고침버튼, 로그아웃버튼(공통위젯폴더)
                buildLogoutIconButton(context),
                buildRefreshIconButton(context, () async {
                  await fetchMyRequests();
                  await fetchCompletedRequests();
                }),       
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          if (selectedType != null) _buildProductSection(), //유형 선택하고 나면 품목 및 무게 입력
        ],
      ),
    );
  }

  Widget _buildDropdownSection() { //유형선택 드롭다운(수확, 가공)
    //디자인
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.brown ,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      //선택하는 부분UI
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
                color: Colors.brown ,
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
                color: Colors.brown ,
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
                child: ActionButtonGroup(
                  buttons: [
                    ActionButtonData(
                      label: '수거 요청 보내기',
                      onPressed: sendDeliveryRequest,
                      backgroundColor: AppColors.primaryBrown, 
                    ),
                  ],
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

    //진행중+완료/거절 내역 모두 합침
    final allList = [...myRequests, ...completedRequests]; 
    //비어있습니다 표시
    if (allList.isEmpty) return buildEmptyPlaceholder();
    //카드 형태 리스트
    return ListView.builder( 
      padding: const EdgeInsets.all(12),
      itemCount: allList.length,
      itemBuilder: (context, index) {
        final item = allList[index];

        return InfoCard(
          title: item['item'],
          subtitle:
              "배송사: ${item['transporter']['company_name']} (${item['transporter']['addr1']} ${item['transporter']['addr2']} ${item['transporter']['addrDetail']})\n"
              "전처리사: ${item['preprocessor']['company_name']} (${item['preprocessor']['addr1']} ${item['preprocessor']['addr2']} ${item['preprocessor']['addrDetail']})\n"
              "상태: ${getStatusLabelForRole(role, item['status'])}\n"
              "${getDateLabelForRole(role, item['rawStatus'] ?? item['status'])}: ${item['date'] ?? '-'}", 
              

          borderColor: AppColors.primaryBrown,
          elevation: 2,
        );      
      },
    );
  }

  //수거 요청 전송 함수
  Future<void> sendDeliveryRequest() async {
    final messenger = ScaffoldMessenger.of(context);

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

    //API호출_수거요청 보내기
    final response = await ApiService.postWithToken(
      endpoint: '/api/dispose-req',
      token: widget.token,
      body: {
        "type": selectedType!,
        "name": selectedByproduct!["name"],
        "weight": weightController.text.trim(),
      },
    );


    //정상 처리
    if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
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
      messenger.showSnackBar(
        SnackBar(content: Text("요청 실패: ${response?.body ?? '응답 없음'}")),
      );
    }
  }
}
