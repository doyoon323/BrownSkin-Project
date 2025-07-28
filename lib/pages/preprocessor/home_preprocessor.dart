import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/themes.dart';
import 'package:brownskin_app/common/widgets.dart';

class PreprocessorHomePage extends StatefulWidget {
  final String token; //로그인 후 받은 토큰. 모든 API 호출 시 authorization 헤더에 필요
  const PreprocessorHomePage({super.key, required this.token});

  @override
  State<PreprocessorHomePage> createState() => _PreprocessorHomePageState();
}

//각 탭에 대응되는 리스트
class _PreprocessorHomePageState extends State<PreprocessorHomePage> {
  List<Map<String, dynamic>> receivedItems = []; //상태가 pending인 입고 대기 아이템
  List<Map<String, dynamic>> processingItems = []; //상태가 accepted인 작업중 아이템
  List<Map<String, dynamic>> completedItems = []; //상태 completed인 작업완료 아이템
  bool isChartViewCompleted = false; //카드보기<->그래프보기 전환 때 사용되는 상태변수


  @override
  void initState() {
    super.initState();
    fetchPreprocessItems();
  }

  //데이터 가져오기(GET으로)에 대한 함수
  Future<void> fetchPreprocessItems() async {
    //입고 대기 리스트
    final pendingList = await ApiService.fetchList(
      url: '$BASE_URL/api/my-preprocess?status=pending',
      token: widget.token,
    );
    //처리중 리스트
    final acceptedList = await ApiService.fetchList(
      url: '$BASE_URL/api/my-preprocess?status=accepted',
      token: widget.token,
    );
    //처리완료리스트
    final completedList = await ApiService.fetchList(
      url: '$BASE_URL/api/my-preprocess?status=completed',
      token: widget.token,
    );
    
    if (!mounted) return; //안전장치

    //UI업데이트 위한 상태 반영
    setState(() {
      receivedItems = pendingList;
      processingItems = acceptedList;
      completedItems = completedList;
    });
  }

  //작업 시작처리(입고->작업중)
  Future<void> _startProcessing(Map<String, dynamic> item) async {
    //예상출고일 선택->달력 UI 관련
    final pickedDate = await showDatePicker( 
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    //예상 출고일 선택-> 시작일은 현재날짜, 끝은 위에서 고른 날짜
    if (pickedDate != null) {
      final startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final completeDate = DateFormat('yyyy-MM-dd').format(pickedDate);

      //서버에 POST.(아이디, 시작날짜, 끝날짜)
      final response = await ApiService.postWithToken(
        endpoint: '/api/accept-preprocess',
        token: widget.token,
        body: {
          "id": item['id'].toString(),
          "start_date": startDate,
          "expected_complete_date": completeDate,
        },
      );

      if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
        await fetchPreprocessItems();
      }
    }
  }

  //작업 완료 처리 함수(작업중->작업 완료)
  Future<void> _completeProcessing(Map<String, dynamic> item) async {
    final controller = TextEditingController();

    //사용자한테 다이얼로그 띄워서 무게 입력값 받기
    final confirmed = await showDialog<bool>(  //그 UI
      context: context,
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: TextTheme(
            titleLarge: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold),
            bodyMedium: TextStyle(color: AppColors.darkBrown),
          ),
          dialogTheme: DialogThemeData(backgroundColor: Colors.white),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('최종 무게 입력', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '최종 무게 (kg)',
              labelStyle: TextStyle(color: AppColors.primaryBrown),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBrown, width: 2),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.lightBrown),
              ),
            ),
            cursorColor: AppColors.primaryBrown,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: AppColors.lightBrown),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) { //사용자가 확인 눌렀고 무게가 빈 문자열x
      final finalWeight = controller.text.trim(); //그 무게를 finalweight로 저장
      //성공 시 완료처리 post
      final response = await ApiService.postWithToken(
        endpoint: '/api/complete-preprocess',
        token: widget.token,
        body: {
          "id": item['id'].toString(),
          "final_weight": finalWeight, //여기에 최종무게 넣어서 보냄
        },
      );
      //성공 시 리스트 새로고침
      if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
        await fetchPreprocessItems();
      }
    }
  }

  //UI구성
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBrown,

        //상단앱바
        appBar: AppBar(
          title: Text('전처리 시스템', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryBrown,
          elevation: 4,
          shadowColor: AppColors.darkBrown ,
          actions: [ //상단에 새로고침버튼, 로그아웃버튼(공통위젯폴더)
            buildLogoutIconButton(context),
            buildRefreshIconButton(context, fetchPreprocessItems),
            buildProfileIconButton(context: context, token: widget.token),
            ],
          bottom: TabBar( //하단에는 탭 세 개
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: '입고'),
              Tab(text: '작업중'),
              Tab(text: '작업완료'),
            ],
          ),
        ),
        body: TabBarView( //각 탭이 뭔지: 아래에 각각 정의돼있음
          children: [
            _buildReceivedTab(), //탭1: 입고
            _buildProcessingTab(), //탭2:작업중
            _buildCompletedTab(), //탭3: 작업완료
          ],
        ),
      ),
    );
  }

  //탭1. 입고_receivedItem목록 카드형으로 보여주고, 각 항목마다 작업시작 버튼 제공
  Widget _buildReceivedTab() {

    //비어있습니다 표시
    if (receivedItems.isEmpty) return buildEmptyPlaceholder();

    //정렬 입고일 오래된 순
    receivedItems.sort((a, b) {
      final aDate = DateTime.tryParse(a['req_date'] ?? '') ?? DateTime(1900);
      final bDate = DateTime.tryParse(b['req_date'] ?? '') ?? DateTime(1900);
      return aDate.compareTo(bDate); // 오래된 게 위로
    });

  
    return Container(
      color: AppColors.backgroundBrown,
      child: ListView( //리스트형 카드 반복
        padding: const EdgeInsets.all(16),
        children: receivedItems.map((item) { //목록 map으로 돌면서 각각 카드형식으로 보여줌
          final displayWeight = item['weight_float']?.toString() ?? '정보 없음';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InfoCard(
              title: "${item['name']} (${item['type']})",
              subtitle: "무게: ${displayWeight}kg\n상태: 입고\n입고일: ${item['req_date']}",
              trailing: ActionButtonGroup(
                buttons: [
                  ActionButtonData(
                    label: '작업 시작',
                    onPressed: () => _startProcessing(item),
                  ),
                ],
              ),

              borderColor: AppColors.primaryBrown,
              backgroundColor: Colors.white,
              elevation: 6,
            ),
          );
        }).toList(), //형태로 반환
      ),
    );
  }

  //탭2. 작업중
  Widget _buildProcessingTab() {
    //비어있습니다 표시
    if (processingItems.isEmpty) return buildEmptyPlaceholder();

    //정렬 예상 완료일 임박한 순
    processingItems.sort((a, b) {
      final aDate = DateTime.tryParse(a['expected_complete_date'] ?? '') ?? DateTime(2100);
      final bDate = DateTime.tryParse(b['expected_complete_date'] ?? '') ?? DateTime(2100);
      return aDate.compareTo(bDate); // 임박한 게 위로
    });

    return Container(
      color: AppColors.backgroundBrown,
      child: ListView( //리스트형 카드 반복
        padding: const EdgeInsets.all(16),
        children: processingItems.map((item) {
          final displayWeight = item['weight_float']?.toString() ?? '정보 없음';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InfoCard(
              title: "${item['name']} (${item['type']})",
              subtitle: "무게: ${displayWeight}kg\n상태: 작업중\n작업시작일: ${item['start_date']}\n예상출고일: ${item['expected_complete_date']}",
              trailing: ActionButtonGroup(
                buttons: [
                  ActionButtonData(
                    label: '작업 완료',
                    onPressed: () => _completeProcessing(item),
                  ),
                ],
              ),

              borderColor: AppColors.primaryBrown,
              backgroundColor: Colors.white,
              elevation: 6,
            ),
          );

        }).toList(), //리스트위젯으로 변환
      ),
    );
  }

  //탭3. 완료건_은 카드/그래프 전환이 있으므로 infocard 빼지 않음
  Widget _buildCompletedTab() {
    //비어있습니다 표시
    if (completedItems.isEmpty) return buildEmptyPlaceholder();

    
    // 수율 계산 함수
    double calculateYield(Map<String, dynamic> item) {
      final double finalWeight = double.tryParse(item['final_weight'].toString()) ?? 0;
      final double originalWeight = double.tryParse(item['weight_float'].toString()) ?? 1;
      return originalWeight > 0 ? finalWeight / originalWeight : 0;
    }

    // 정렬: 수율 높은 순
    completedItems.sort((a, b) {
      final aYield = calculateYield(a);
      final bYield = calculateYield(b);
      return bYield.compareTo(aYield); // 높은 게 위로 오게 내림차순
    });

    return Container( //전체 컨테이너
      color: AppColors.backgroundBrown,
      child: Column( //탭 디자인
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkBrown ,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row( //보기전환버튼
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryBrown),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () { //버튼 누르면
                      setState(() { //상태 토글
                        isChartViewCompleted = !isChartViewCompleted;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text( //글자도 바뀜
                      isChartViewCompleted ? '카드 보기' : '그래프 보기',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          //그래프 보기
          Expanded(
            child: isChartViewCompleted //이게 true일 때 작동
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, //2열
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: completedItems.length,

                    //각 그래프 카드 내부
                    itemBuilder: (context, index) {
                      final item = completedItems[index];
                      final double finalWeight =
                          double.tryParse(item['final_weight'].toString()) ?? 0;
                      final double originalWeight =
                          double.tryParse(item['weight_float'].toString()) ?? 1;
                      final double yield = //수율계산
                          originalWeight > 0 ? (finalWeight / originalWeight) : 0;

                      return Card( //그래프보기 카드 형식
                        elevation: 6,
                        shadowColor: AppColors.darkBrown ,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.primaryBrown, width: 1.5),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white ,
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "${item['name']}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBrown,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "(${item['type']})",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkBrown ,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              //그래프 디자인
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 8.0,
                                percent: yield.clamp(0.0, 1.0),
                                center: Text(
                                  "${(yield * 100).toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                                progressColor: AppColors.primaryBrown,
                                backgroundColor: AppColors.lightBrown ,
                                animation: true,
                                animationDuration: 800,
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.accentBrown ,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${finalWeight.toStringAsFixed(1)}kg",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBrown,
                                  ),
                                ),
                              ),
                              Text(
                                "${item['complete_date']}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.darkBrown ,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )

                  //카드보기 형식
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: completedItems.map((item) {
                      final double finalWeight =
                          double.tryParse(item['final_weight'].toString()) ?? 0;
                      final double originalWeight =
                          double.tryParse(item['weight_float'].toString()) ?? 1;
                      final double yield =
                          originalWeight > 0 ? (finalWeight / originalWeight * 100) : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 6,
                          shadowColor: AppColors.darkBrown ,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.primaryBrown, width: 1.5),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                "${item['name']} (${item['type']})",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "최종무게: ${finalWeight.toStringAsFixed(1)}kg\n상태: 완료\n작업완료일: ${item['complete_date']}\n수율: ${yield.toStringAsFixed(1)}%",
                                  style: TextStyle(color: AppColors.darkBrown , height: 1.4),
                                ),
                              ),
                              trailing: ElevatedButton( //출고버튼(아직 동작x)
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBrown,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 3,
                                ),
                                child: const Text('출고', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
