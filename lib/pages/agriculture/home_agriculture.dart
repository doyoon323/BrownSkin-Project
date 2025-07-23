import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:brownskin_app/pages/agriculture/deliveryReq_agriculture.dart';

import '../../common/api_service.dart';
import '../../common/status_utils.dart';

class AgriHome extends StatefulWidget {
  final String token;
  const AgriHome({required this.token, super.key});

  @override
  AgriHomeState createState() => AgriHomeState();
}

class AgriHomeState extends State<AgriHome> with TickerProviderStateMixin, WidgetsBindingObserver {


  Map<String, List<Map<String, dynamic>>> userByproduct = {};
  String? selectedByproduct;
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
    WidgetsBinding.instance.addPostFrameCallback((_) { init(); });
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
  void showSnack(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  /// 등록한 무게 DB 저장 및 UI 갱신
  Future<bool> addWeight(bool disposed, String? type, String? name, String weight) async {

    if (type == null || name == null || weight.isEmpty) { //에러 핸들링1 : 내용이 비어있을 경우
      showSnack("무게, 타입, 이름을 모두 입력하세요");
      return false;
    }

    double? parsedWeight = double.tryParse(weight);
    if (parsedWeight == null || (!disposed && parsedWeight <= 0) ) { //에러 핸들링2 :유효하지 않은 숫자
      showSnack("유효하지 않은 입력입니다.");
      return false;
    }

    if (disposed) parsedWeight *= -1;

    print("test DISPOSED : $disposed , WEIGHT : $parsedWeight");

    final response = await http.post(
      Uri.parse("$BASE_URL/api/add-weight"),
      headers: {"Authorization": "Token $token"},
      body: {"name": name, "weight": parsedWeight.toString(), "type": type},
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

  void showHistoryPreviewUI(BuildContext context, String type, String name) async {
    await getHistoryData(type, name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 1.0,
          maxChildSize: 1.0,
          expand: true,
          builder: (_, scrollController) {
            late void Function(void Function()) setModalBodyState;

            return StatefulBuilder(
              builder: (context, setOuterState) {
                return SafeArea(
                  child: Material(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Column(
                      children: [
                        // 🔹 헤더
                        Padding(
                          padding: const EdgeInsets.only(top: 36, left: 8, right: 8, bottom: 50),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.arrow_back, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔹 내용 영역
                        Expanded(
                          child: StatefulBuilder(
                            builder: (context, setInnerState) {
                              setModalBodyState = setInnerState;

                              return _buildHistoryList(name, cachedHistory["$type $name"] ?? []);
                            },
                          ),
                        ),

                        // 🔹 하단 버튼
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    final added = await _showAddWeightDialog("부산물 폐기 등록", type, name, true);

                                    if (added) {
                                      final newData = await getHistoryData(type, name);
                                      cachedHistory["$type $name"] = newData;
                                      setModalBodyState(() {
                                        print("🌀 setModalState triggered after 폐기");
                                      });
                                    }
                                  },
                                  child: Text("부산물 폐기"),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    side: BorderSide(color: Colors.black),
                                    foregroundColor: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final added = await _showAddWeightDialog("부산물 무게 추가", type, name, false);
                                    if(added){
                                      final newData = await getHistoryData(type, name);
                                      cachedHistory["$type $name"] = newData;
                                      setModalBodyState(() {
                                        print("🌀 setModalState triggered after 추가");
                                      });
                                    }
                                  },
                                  child: Text("부산물 추가"),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }


  Map<String, List<Map<String, dynamic>>> cachedHistory = {};
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
    } else {
      last_fetch_history[key] = now;
    }

    if (!cachedHistory.containsKey(key)) {
      cachedHistory[key] = [];
    }

    final existingKeys = cachedHistory[key]!
        .map((e) => "${e['timestampFull']}_${e['type']}_${e['name']}")
        .toSet();

    final uniqueNewData = filteredData.where((entry) {
      return !existingKeys.contains("${entry['timestampFull']}_${entry['type']}_${entry['name']}");
    }).toList();

    cachedHistory[key] = [...uniqueNewData, ...cachedHistory[key]!];

    final limitDate = now.subtract(Duration(days: 30));
    cachedHistory[key] = cachedHistory[key]!.where((entry) {
      final entryDate = DateTime.parse(entry['timestamp']);
      return entryDate.isAfter(limitDate) || entryDate.isAtSameMomentAs(limitDate);
    }).toList();

    // ✅ 최신 상태 반환
    return List<Map<String, dynamic>>.from(cachedHistory[key]!);
  }














/* UI 구현 */

  @override
  Widget build(BuildContext context) {
    final summaryData = getSummaryData();
    final filteredData = getFilteredData();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75),
        child: AppBar(
          title: Text(
            '부산물 관리 시스템',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                isGridView ? Icons.grid_view : Icons.list,
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  isGridView = !isGridView;
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person,
                size: 40,
              ),
              onPressed: () {
                /// 마이페이지 이동
              },
            ),
            SizedBox(width: 8)
          ],
        ),
      ),

      /// 상단 헤더 (탭 버튼 + 요약 정보)
      body: Column(
        children: [
          Container(
            //color: Colors.green[700],
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8), // 원하시면 모서리 둥글게 가능
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: Icon(Icons.warning, color: Colors.white, size: 20),
                                ),
                                Text(
                                  "포화 위험 품목",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "${summaryData['danger']}개",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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

          // 체크박스 버튼
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildFilterCheckbox("가공", isProcessChecked, (newValue) {
                      setState(() {
                        isProcessChecked = newValue!;
                      });
                    }),
                    SizedBox(width: 4),
                    _buildFilterCheckbox("수확", isHarvestChecked, (newValue) {
                      setState(() {
                        isHarvestChecked = newValue!;
                      });
                    }),
                  ],
                ),
                /// 우측: 정렬 드롭다운
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
                        setState(() { sortBy = value!;});
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
             isGridView ?
             ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 5),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                return _buildListItem(filteredData[index]);
              },
            )
                 : GridView.builder(
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
          ),
        ],
      ),

      /// 하단 부산물 추가 버튼
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              _showAddWeightDialog("새 부산물 등록",null,null, false);
            },
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.white,
            shape: CircleBorder(side: BorderSide(color: Colors.black26)),
            child: Icon(Icons.add, size: 45),
          ),
          SizedBox(height: 15),
          Text(
            '부산물 종류 등록',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 하단 메뉴 바
      bottomNavigationBar: bottomNavigationBar(),
    );
  }



  bool isProcessChecked = true;
  bool isHarvestChecked = true;
  Widget _buildFilterCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Theme(
          data: ThemeData(unselectedWidgetColor: Colors.black26),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26, width: 1), // 윤곽선
            ),
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              checkColor: Colors.black,
              activeColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }


  List<Map<String, dynamic>> getFilteredData() {
    List<Map<String, dynamic>> filtered = donutData.where((item) {
      if (item["type"] == "가공" && !isProcessChecked) return false;
      if (item["type"] == "수확" && !isHarvestChecked) return false;
      return true;
    }).toList();

    // 정렬
    filtered.sort((a, b) {
      switch (sortBy) {
        case "status":
          return getStatusPriority(b["percent"]).compareTo(getStatusPriority(a["percent"]));
        case "name":
        default:
          return a["name"].compareTo(b["name"]);
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


  Widget _buildHistoryList(String name, List<Map<String, dynamic>> history) {
    final latestWeight = history.isNotEmpty
        ? history.first["current_weight_float"]
        : 0.0;

    print("📦 buildHistoryList(): ${history.length} items");
    print("📦 history hashCode: ${history.hashCode}");

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$name 부산물", style: TextStyle(fontSize: 16)),
          SizedBox(height: 14),
          Text(
            "${latestWeight.toStringAsFixed(1)} $weight_uints",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 75),
          Expanded(
            child: ListView.builder(
              key: ValueKey(history.length), // ✅ 변화 감지용 key
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry["status"], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text(entry["timestamp"], style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${entry["weight_diff_float"] > 0 ? "+" : ""}${entry["weight_diff_float"].toStringAsFixed(1)} $weight_uints",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: entry["weight_diff_float"] > 0 ? Colors.black87 : Color(0xFFED2939),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text("${entry["current_weight_float"].toStringAsFixed(1)} $weight_uints",
                                style: TextStyle(fontSize: 13, color: Colors.brown[800])),
                          ],
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
                  "${item["weight"]}/${item["threshold"]}$weight_uints",
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

  Widget _buildListItem(Map<String, dynamic> item) {
    double percent = item["percent"];
    Color progressColor = getProgressColor(percent);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Padding(

                      padding: EdgeInsets.only(top: 20),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: "[ ${item['type']} ] "),
                            TextSpan(text: "${item['name']}  "),
                            TextSpan(text: "${item['weight']}$weight_uints"),
                          ],
                        ),
                      ),
                    ),


                    if (item['percent'] >= 0.8)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 12, color: Colors.black87),
                            SizedBox(width: 4),
                            Text(
                              "위험",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),


              OutlinedButton(
                onPressed: () {
                  showHistoryPreviewUI(context, item['type'], item['name']);
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  side: BorderSide(color: Colors.black),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                ),
                child: Text("재고 내역", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          SizedBox(height: 20),

          // 진행률 바 + % 텍스트
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 20,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "${(percent * 100).toInt()}%",
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // 폐기 / 추가 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showAddWeightDialog("부산물 폐기 등록",item['type'], item['name'], true);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: Text("폐기"),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _showAddWeightDialog("부산물 무게 추가",item['type'], item['name'], false);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: Text("추가"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 부산물 추가 다이얼로그
  /// 부산물 추가 다이얼로그
  Future<bool> _showAddWeightDialog(String label, String? type, String? name, bool disposed) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
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
                      label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

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
                      DropdownButtonFormField<String>(
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
                            .map<DropdownMenuItem<String>>(
                              (item) => DropdownMenuItem(
                            value: item['name'],
                            child: Text(item['name']!),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedByproduct = value;
                          });
                        },
                      ),
                    ],

                    SizedBox(height: 16),
                    Text('무게 입력 ($weight_uints)'),
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
                          disposed,
                          selectedType,
                          selectedByproduct,
                          weightController.text.trim(),
                        );

                        if (success) {
                          await updateData(userByproduct); // 필요한 경우 유지
                          weightController.clear();
                          Navigator.pop(context, true); // ✅ 성공 시 true 반환
                        } else {
                          Navigator.pop(context, false); // 실패 시 false
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black,
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
    return result == true; // null 또는 false → 실패
  }
  Widget bottomNavigationBar() {
    return BottomAppBar(
      shape: CircularNotchedRectangle(), // 가운데 notch
      notchMargin: 6.0,
      elevation: 10,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            /// 홈 버튼
            GestureDetector(
              onTap: () {
                // 홈 화면이므로 아무 동작 안함
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_rounded, color: Colors.black),
                  Text('홈', style: TextStyle(color: Colors.black, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(width: 40),

            /// 배송 요청 버튼
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryReqAgriculturePage(
                      token: token,
                      userByproduct: userByproduct,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    fetchUserByProduct().then((_) => updateData(userByproduct));
                  }
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_rounded, color: Colors.grey[400]),
                  Text('배송 요청', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
