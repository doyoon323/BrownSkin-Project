import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/status_utils.dart';
import 'package:brownskin_app/common/themes.dart';
import 'package:brownskin_app/common/widgets.dart';


class TransporterHomePage extends StatefulWidget {
  final String token;
  const TransporterHomePage({required this.token, super.key});

  @override
  State<TransporterHomePage> createState() => _TransporterHomePageState();
}

//주요 필드, 변수 설명
class _TransporterHomePageState extends State<TransporterHomePage> with SingleTickerProviderStateMixin{
  List<Map<String, dynamic>> allRequests = [];
  List<Map<String, dynamic>> completedRequests = [];
  final String role = 'transporter';
  late TabController _tabController;
  final List<String> tabTitles = ['수거 요청', '수거 대기', '배송중', '완료/거절'];
  // 위치 정보 주기적으로 업데이트하는 타이머
  Timer? _locationUpdateTimer;

  Color getBorderColorByStatus(String status) {
  switch (status) {
    case 'denied':
      return Colors.red;
    default:
      return AppColors.primaryBrown;
  }
}

  //데이터 초기 호출_앱 실행 시점

@override
void initState() {
  super.initState();

  _tabController = TabController(length: tabTitles.length, vsync: this);
  _tabController.addListener(() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 3) {
        fetchCompletedDeliveries();
      } else {
        fetchMyDeliveries();
      }
    }
  });

  fetchMyDeliveries();
  fetchCompletedDeliveries();

  // 위치정보 주기적으로 전송
  _locationUpdateTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
    _postLocation();
  });
}

@override
void dispose() {
  _tabController.dispose();
  _locationUpdateTimer?.cancel(); // 위치 업데이트 타이머 해제
  super.dispose();
}


  //FetchMydeliveries->요청, 진행중
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
          dateText = item['transit_date'] ?? ''; //배송중이면 날짜 배송시작일로
        }
        return { //서버데이터를 리스트타일 표시용 데이터로 가공
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

  //fetchCompletedDeliveries->완료, 거절건
  Future<void> fetchCompletedDeliveries() async {
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
        'disposer': item['disposer'],
        'preprocessor': item['preprocessor'],
      };
    }).toList();
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBrown,

      //상단 앱바(제목, 새로고침)
      appBar: buildCustomAppBar(
        context: context,
        title: '배송 시스템', // 또는 '전처리 시스템'
        token: widget.token,
        showBackButton: false,
        showActions: true,
        onRefresh: () async {
          await fetchMyDeliveries(); // or await fetchPreprocessItems();
          await fetchCompletedDeliveries(); // or other relevant function
        },
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: [
            Tab(text: '수거 요청'),
            Tab(text: '수거 대기'),
            Tab(text: '배송중'),
            Tab(text: '완료/거절'),
          ],
        ),
      ),


      //각 탭에 따라서 표시할 요청 나눔
      body: TabBarView(
        controller: _tabController,
        children: tabTitles.map((title) => _buildRequestList(title)).toList(),        
      ),

    );
  }

  //배송건들 카드 생성
  Widget _buildRequestItem(Map<String, dynamic> item) {
  final String title = item['item'];
 ///카드위젯
  final String subtitle =
      "배출사: ${item['disposer']['company_name']} (${item['disposer']['addr1']} ${item['disposer']['addr2']} ${item['disposer']['addrDetail']})\n"
      "전처리사: ${item['preprocessor']['company_name']} (${item['preprocessor']['addr1']} ${item['preprocessor']['addr2']} ${item['preprocessor']['addrDetail']})\n"
      "상태: ${getStatusLabelForRole(role, item['rawStatus'])}\n"
      "${getDateLabelForRole(role, item['rawStatus'])}: ${item['date']}";

  return InfoCard(
    title: title,
    subtitle: subtitle,
    trailing: _buildActionButton(item),
    borderColor: getBorderColorByStatus(item['rawStatus'] ?? item['status']),
    backgroundColor: Colors.white,
    elevation: 6,
  );
}

//배송카드 공간

Widget _buildRequestList(String tabTitle) {
  List<Map<String, dynamic>> list = tabTitle == '완료/거절'
      ? completedRequests
      : allRequests.where((e) => getStatusLabelForRole(role, e['rawStatus']) == tabTitle).toList();

// 정렬: 최신순 + 완료/거절 탭일 경우 상태 우선
list.sort((a, b) {
  final aDate = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
  final bDate = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);

  if (tabTitle == '완료/거절') {
    // 완료 먼저, 거절 나중
    final aPriority = a['rawStatus'] == 'completed' ? 0 : 1;
    final bPriority = b['rawStatus'] == 'completed' ? 0 : 1;

    if (aPriority != bPriority) {
      return aPriority.compareTo(bPriority);
    }
  }

  // 최신순 정렬
  return bDate.compareTo(aDate);
});


//비어있습니다 표시
  if (list.isEmpty) return buildEmptyPlaceholder();
  
  return ListView(
    padding: const EdgeInsets.all(12),
    children: list.map(_buildRequestItem).toList(),
  );
}

  //우측 작은 버튼 함수
Widget _buildActionButton(Map<String, dynamic> item) {
  final int id = item['id'];
  final String status = item['rawStatus'];

  if (status == 'pending') {
    return ActionButtonGroup(
      buttons: [
        ActionButtonData(label: '수락', onPressed: () => _acceptDelivery(id)),
        ActionButtonData(label: '거절', onPressed: () => _denyDelivery(id), backgroundColor: Colors.red.shade700),
      ],
    );
  } else if (status == 'accepted') {
    return ActionButtonGroup(
      buttons: [
        ActionButtonData(label: '수거 완료', onPressed: () => _transitDelivery(id)),
      ],
    );
  } else if (status == 'transit') {
    return ActionButtonGroup(
      buttons: [
        ActionButtonData(label: '배송 완료', onPressed: () => _completeDelivery(id)),
      ],
    );
  }
  return const SizedBox(); // 나머지 상태는 버튼 없음
}

  //각 API 호출 함수들(버튼에서)
  Future<void> _acceptDelivery(int id) async { //수락
    await ApiService.postWithToken(
      endpoint: '/api/accept-delivery',
      token: widget.token,
      body: {"id": "$id"},
    );
    fetchMyDeliveries();
  }
  Future<void> _denyDelivery(int id) async { //거절
    await ApiService.postWithToken(
    endpoint: '/api/deny-delivery',
    token: widget.token,
    body: {"id": "$id"},
    );
    await fetchMyDeliveries();
    await fetchCompletedDeliveries(); 
    //거절건은 진행 중 목록에서 빠지고, 완료 목록에 들어가야 하므로 두 개 새로고침
  }

  Future<void> _transitDelivery(int id) async { //수거완료(배송중)
    await ApiService.postWithToken(
      endpoint: '/api/transit-delivery',
      token: widget.token,
      body: {"id": "$id"},
    );
    fetchMyDeliveries();
  }

  Future<void> _completeDelivery(int id) async { //배송완료
    await ApiService.postWithToken(
      endpoint: '/api/complete-delivery',
      token: widget.token,
      body: {"id": "$id"},
    );
    await fetchMyDeliveries();
    await fetchCompletedDeliveries(); 
    //얘도 두 번
    //이게 뭐냐면, post로 서버에 상태 변경한 뒤에, 
    //1)mydelivery 새로고침해서 진행중 요청에서 빠지고, 
    //2)myhistory 새고해서 거기에 포함돼야 함. 
    //즉 두 곳에서 데이터가 바뀌니까 둘 다 호출해야됨
  }

  //위치 전송 API 호출
  Future<void> _postLocation() async {
    // 위치 정보 획득 가능한지 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    // 위치 추적 퍼미션 확인
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('permissions are denied');
      }
    }
    // 현재 위치 구하기
    Position position = await Geolocator.getCurrentPosition();
    // 요청 보내기
    final url = Uri.parse('$BASE_URL/api/update-location');
    final headers = {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    };
    final bodys = {
      "latitude": position.latitude.toString(),
      "longitude": position.longitude.toString(),
    };
    try {
      final response = await http.post(url, headers: headers, body: bodys);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('위치 post 성공: ${response.body}');
      } else {
        debugPrint('위치 post 실패: ${response.body}');
      }
    } catch (e) {
      debugPrint('네트워크 오류: $e');
    }
  }
}

