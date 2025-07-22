import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:brownskin_app/pages/agriculture/deliveryReq_agriculture.dart';

import '../../common/api_service.dart';
import '../../widgets/bottom_nav.dart';
import '../../common/status_utils.dart';

class AgriHome extends StatefulWidget {
  final String token;
  const AgriHome({required this.token, super.key});

  @override
  AgriHomeState createState() => AgriHomeState();
}

class AgriHomeState extends State<AgriHome> with TickerProviderStateMixin, WidgetsBindingObserver {


  Map<String, List<Map<String, dynamic>>> userByproduct = {};
  Map<String, String?>? selectedByproduct;
  String? selectedType;

  String get token => widget.token;
  List<Map<String, dynamic>> donutData = [];
  final TextEditingController weightController = TextEditingController();

  // UI 상태 관리
  String currentTab = "전체"; // 전체, 가공, 수확 탭
  String sortBy = "name"; // 정렬 기준 : name, status
  bool isGridView = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 관찰 등록

    _timer = Timer.periodic(
        Duration(minutes: 15),
            (timer) {
              if (userByproduct.isNotEmpty) {
                fetchUserByProduct();
                updateData(userByproduct);
              }
        }
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
    });
  }


  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this); // 앱 상태 관찰 해제
    super.dispose();
  }


  Future<void> init() async {
    await fetchUserByProduct();
    await updateData(userByproduct);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchUserByProduct().then((_) => updateData(userByproduct));
    }
  }

  /// 현재 사용자 부산물 데이터 저장
  Future<void> fetchUserByProduct() async {
    final rawData = await ApiService.fetchMap(
        url: '$BASE_URL/api/my-byprod',
        token: widget.token
    );
    //json parsing
    userByproduct = rawData.map((key, value) =>
        MapEntry(key, List<Map<String, dynamic>>.from(value)),);
  }

  /// 출력 helper function
  void showSnack(String message, {Color color = Colors.green}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  /// 등록한 무게 DB 저장 및 UI 갱신
  Future<bool> addWeight(String? type, String? name, String weight) async {
    if (type == null || name == null || weight.isEmpty) { //에러 핸들링1 : 내용이 비어있을 경우
      showSnack("무게, 타입, 이름을 모두 입력하세요");
      return false;
    }

    final parsedWeight = double.tryParse(weight);
    if (parsedWeight == null || parsedWeight <= 0) { //에러 핸들링2 :유효하지 않은 숫자
      showSnack("유효하지 않은 입력입니다.");
      return false;
    }

    final response = await http.post(
      Uri.parse("$BASE_URL/api/add-weight"),
      headers: {"Authorization": "Token $token"},
      body: {"name": name, "weight": weight, "type": type},
    );

    if (response.statusCode != 200) {
      showSnack("무게를 추가하는 것을 실패했습니다.", color: Colors.red);
      return false;
    }

    await fetchUserByProduct();
    setState(() {
      selectedByproduct = null;
      selectedType = null;
    });
    showSnack("성공적으로 등록되었습니다!");
    return true;
  }


  /// data transform helper function
  Map<String, dynamic> transformItem(String type,
      Map<String, dynamic> item,
      int defaultThreshold,) {
    final name = item['name'];
    final threshold = (item["threshold"] ?? defaultThreshold) as num;
    final weight = (item["weight_float"] ?? 0) as num;
    final percent = (weight / threshold).clamp(0.0, 1.0);

    return {
      "name": name,
      "type": type,
      "threshold": threshold,
      "weight": weight,
      "percent": percent,
    };
  }

  /// 데이터 시각화용 데이터를 갱신하는 함수
  Future<void> updateData(Map<String, List<Map<String, dynamic>>> byproductList,) async {
    List<Map<String, dynamic>> tempList = [];
    const defaultThreshold = 200; // !! default = 200 (데이터를 기반으로 수정해야함)

    for (final byproduct in byproductList.entries) {
      final type = byproduct.key;
      final products = byproduct.value;
      for (final item in products)
        tempList.add(transformItem(type, item, defaultThreshold));
    }
    setState(() { donutData = tempList;});
  }

  Map<String, List<Map<String, dynamic>>> cachedHistory = {};

  void showHistoryPreviewUI(BuildContext context, String type, String name) async {
    final newData = await getHistoryData(type, name);
    String key = "$type $name";

    if (!cachedHistory.containsKey(key))  cachedHistory[key] = [];

    final existingKeys = cachedHistory[key]!.map((e) => "${e['timestampFull']}_${e['type']}_${e['name']}").toSet();
    final uniqueNewData = newData.where((entry) {return !existingKeys.contains("${entry['timestampFull']}_${entry['type']}_${entry['name']}");}).toList();

    cachedHistory[key] = [...uniqueNewData, ...cachedHistory[key]!];
    DateTime limitDate = DateTime.now().subtract(Duration(days: 30));
    cachedHistory[key] = cachedHistory[key]!.where((entry) {
      DateTime entryDate = DateTime.parse(entry['timestamp']);
      return entryDate.isAfter(limitDate) || entryDate.isAtSameMomentAs(limitDate);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
      isScrollControlled: true,
      builder: (_) => _buildHistoryBottomSheet(name, cachedHistory[key]!),
    );
  }


  Map<String, DateTime> last_fetch_history = {};

  Future<List<Map<String, dynamic>>> getHistoryData(String type, String name) async {
    final key = "$type $name";
    final now = DateTime.now();

    final fetchFromDate = last_fetch_history[key] ?? now.subtract(const Duration(days: 30));
    final fetchFrom = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(fetchFromDate);

    final url = '$BASE_URL/api/dispose-history?type=$type&name=$name&fetch_from=$fetchFrom';
    final response = await ApiService.fetchList(url: url, token: token);

    final List<Map<String, dynamic>> filteredData = response.map((entry) {
      return {
        'type': entry['type'],
        'name': entry['name'],
        'weight_diff_float': entry['weight_diff_float'],
        'current_weight_float': entry['current_weight_float'],
        'status': entry['status'] == "disposed" ? "추가" : entry['status'] == "abondoned" ? "폐기" : "수거",
        'timestamp': entry['timestamp'].substring(0, 10),
        'timestampFull': entry['timestamp']
      };
    }).toList();

    if (filteredData.isNotEmpty) {
      filteredData.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      last_fetch_history[key] = DateTime.parse(filteredData.first['timestamp']);
    } else last_fetch_history[key] = now;

    return filteredData;
  }















/* UI 구현 */

  @override
  Widget build(BuildContext context) {
    final summaryData = getSummaryData();
    final filteredData = getFilteredData();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '부산물 관리 시스템', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            })
        ],
      ),

      /// 상단 헤더 (탭 버튼 + 요약 정보)
      body: Column(
        children: [
          Container(
            color: Colors.green[700],
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // 탭 버튼
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton("전체", "전체"),
                      SizedBox(width: 4),
                      _buildTabButton("가공", "가공"),
                      SizedBox(width: 4),
                      _buildTabButton("수확", "수확"),
                    ],
                  ),
                ),

                // 요약 정보
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${summaryData['count']}개",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "총 품목",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${(summaryData['average'] * 100).toStringAsFixed(
                                  0)}%",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "평균 포화률",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${summaryData['danger']}개",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "위험 품목",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 검색 및 정렬 바
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 12),

                // 정렬 드롭다운
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sortBy,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      items: [
                        DropdownMenuItem(value: "name", child: Text("이름순")),
                        DropdownMenuItem(value: "status", child: Text("위험도순")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          sortBy = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 메인 콘텐츠 (Grid / List 뷰)
          Expanded(
            child:
            filteredData
                .isEmpty //검색결과 없음
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "검색 결과가 없습니다",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : isGridView // 그리드 뷰
                ? GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                return _buildCompactGridCard(filteredData[index]);
              },
            )
                : ListView.builder(
              // 리스트 뷰
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                return _buildListItem(filteredData[index]);
              },
            ),
          ),
        ],
      ),

      /// 하단 부산물 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddWeightDialog();
        },
        backgroundColor: Colors.green[700],
        child: Icon(Icons.add, color: Colors.white),
      ),

      /// 하단 메뉴 바
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DeliveryReqAgriculturePage(
                      token: token,
                      userByproduct: userByproduct,
                    ),
              ),
            ).then((result) {
              if (result == true) {
                fetchUserByProduct().then((_) => updateData(userByproduct));
              }
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_rounded), label: '배송 요청')],
        selectedItemColor: Colors.green[700]!,
        unselectedItemColor: Colors.grey[400]!,
      ),
    );
  }


  /// 필터링 및 정렬된 데이터 반환
  List<Map<String, dynamic>> getFilteredData() {
    List<Map<String, dynamic>> filtered = donutData.where((item) {
      // 탭 필터링
      bool tabMatch = currentTab == "전체" || item["type"] == currentTab;
      return tabMatch ;
    }).toList();

    // 정렬
    filtered.sort((a, b) {
      switch (sortBy) {
        case "percent": return b["percent"].compareTo(a["percent"]);
        case "status": return getStatusPriority(b["percent"]).compareTo(getStatusPriority(a["percent"]));
        case "name":
        default: return a["name"].compareTo(b["name"]);
      }
    });
    return filtered;
  }


  /// 요약 정보 계산
  Map<String, dynamic> getSummaryData() {
    if (donutData.isEmpty) return {"total": 0, "average": 0, "danger": 0, "warning": 0};

    List<Map<String, dynamic>> filtered = getFilteredData();
    if (filtered.isEmpty)  return {"total": 0, "average": 0, "danger": 0, "warning": 0};

    double totalWeight = filtered.fold(0, (sum, item) => sum + item["weight"]);
    double averagePercent = filtered.fold(0.0, (sum, item) => sum + item["percent"]) / filtered.length;
    int dangerCount = filtered.where((item) => item["percent"] >= 0.9).length;
    int warningCount = filtered.where((item) => item["percent"] >= 0.7 && item["percent"] < 0.9).length;

    return {
      "total": totalWeight,
      "average": averagePercent,
      "danger": dangerCount,
      "warning": warningCount,
      "count": filtered.length,
    };
  }

  Widget _buildHistoryBottomSheet(String name,
      List<Map<String, dynamic>> history) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$name 무게 이력",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          /// 테이블 헤더
          Row(
            children: const [
              Expanded(flex: 3, child: Text("날짜", style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text("구분", style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text("무게 (kg)", style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text("현재 잔여량", style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          SizedBox(height: 8),
          Divider(height: 1, thickness: 1),

          /// 내용 리스트
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      /// 날짜
                      Expanded(flex: 3,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16,
                                color: Colors.grey[700]),
                            SizedBox(width: 4),
                            Text(entry["timestamp"],
                                style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),

                      /// 구분
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2), // 작게 유지
                        decoration: BoxDecoration(
                          color: getStatusColor(entry["status"]).withOpacity(
                              0.15),
                          borderRadius: BorderRadius.circular(10), // 살짝만 둥글게
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 💥 핵심: 내용만큼만 차지
                          children: [
                            Icon(
                              getStatusIcon(entry["status"]),
                              size: 12,
                              color: getStatusColor(entry["status"]),
                            ),
                            SizedBox(width: 4),
                            Text(
                              entry["status"],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: getStatusColor(entry["status"]),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 15),

                      /// 무게 변화
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${entry["weight_diff_float"] > 0
                              ? "+"
                              : ""}${entry["weight_diff_float"].toStringAsFixed(
                              1)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: entry["weight_diff_float"] > 0
                                ? Colors.green
                                : entry["status"] == 'disposed' ? Color(
                                0xFFED2939) : Colors.red,
                          ),
                        ),
                      ),

                      /// 현재 무게
                      Expanded(
                        flex: 2,
                        child: Text("${entry["current_weight_float"].toStringAsFixed(1)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.brown[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 1. 도넛 차트 & 그리드 시각화
  Widget _buildCompactGridCard(Map<String, dynamic> item) {
    double percent = item["percent"];
    Color progressColor = getProgressColor(percent);
    Color backgroundColor = getBackgroundColor(percent);

    return GestureDetector(
        onTap: () {
          showHistoryPreviewUI(context, item['type'], item['name']);
        },
        child: Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: progressColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: progressColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 상태 아이콘 + 이름 + 유형 (중앙 정렬)
                Icon(getStatusIcon_Progress(percent), color: progressColor,
                    size: 16),
                SizedBox(height: 4),
                Text(
                  "${item['name']}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item['type'] == '가공'
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['type'],
                    style: TextStyle(
                      fontSize: 10,
                      color: item['type'] == '가공'
                          ? Colors.blue.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // 원형 진행률 표시
                CircularPercentIndicator(
                  radius: 35.0,
                  lineWidth: 6.0,
                  animation: true,
                  animationDuration: 1000,
                  percent: percent,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(percent * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        getStatusText(percent),
                        style: TextStyle(
                          fontSize: 8,
                          color: progressColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: progressColor,
                  backgroundColor: Colors.grey[300]!,
                ),
                SizedBox(height: 8),

                // 무게 정보
                Text(
                  "${item["weight"]}/${item["threshold"]}kg",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                // 위험 상태 표시
                if (percent >= 0.9)
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "처리필요",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
    );
  }

  /// 2. 리스트 시각화
  Widget _buildListItem(Map<String, dynamic> item) {
    double percent = item["percent"];
    Color progressColor = getProgressColor(percent);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 50,
          height: 50,
          child: CircularPercentIndicator(
            radius: 25.0,
            lineWidth: 4.0,
            animation: true,
            percent: percent,
            center: Text(
              "${(percent * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: progressColor,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: progressColor,
            backgroundColor: Colors.grey[300]!,
          ),
        ),
        title: Row(
          children: [
            Text(
              "${item['name']}",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item['type'] == '가공'
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item['type'],
                style: TextStyle(
                  fontSize: 10,
                  color: item['type'] == '가공'
                      ? Colors.blue.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("${item["weight"]} / ${item["threshold"]} kg"),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 3,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(getStatusIcon_Progress(percent), color: progressColor,
                size: 20),
            SizedBox(height: 2),
            Text(
              getStatusText(percent),
              style: TextStyle(
                fontSize: 10,
                color: progressColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 탭 버튼
  Widget _buildTabButton(String title, String value) {
    bool isSelected = currentTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            currentTab = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.green[700] : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }


  /// 부산물 추가 다이얼로그
  void _showAddWeightDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '새 부산물 등록',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // 1. 부산물 유형 선택
                    Text('부산물 유형 선택'),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      hint: Text("유형을 선택해주세요"),
                      items: ["가공", "수확"].map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedType = value;
                          selectedByproduct = null;
                        });
                      },
                    ),

                    if (selectedType != null) ...[
                      SizedBox(height: 16),
                      Text('품목 선택'),
                      SizedBox(height: 8),
                      DropdownButtonFormField<Map<String, String?>>(
                        value: selectedByproduct,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        hint: Text("품목을 선택해주세요"),
                        items: byproductsCategory
                            .where((item) => item['type'] == selectedType)
                            .map(
                              (item) =>
                              DropdownMenuItem(
                                value: item,
                                child: Text(item['name']!),
                              ),
                        )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedByproduct = value;
                          });
                        },
                      ),
                    ],

                    SizedBox(height: 16),
                    Text('무게 입력 (kg)'),
                    SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '예: 100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),

                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await addWeight(
                            selectedType, selectedByproduct!['name'],
                            weightController.text.trim());
                        if (success) await updateData(userByproduct);
                        weightController.clear();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '등록하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_rounded),
            label: '배송 요청',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            //배송 요청 탭을 눌렀을 때 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeliveryReqAgriculturePage(
                  token: token,
                  userByproduct: userByproduct,
              ),
            ),
            ).then((result){
              if(result ==true) {
                fetchUserByProduct().then((_)=> updateData(userByproduct));
              }
            });
          }
          // index == 0 일 때는 홈이므로 아무 동작 안 함
        },
      ),
    );
  }
}
