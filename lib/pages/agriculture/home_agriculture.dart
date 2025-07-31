import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';
import 'package:intl/intl.dart';
import 'package:brownskin_app/pages/agriculture/deliveryReq_agriculture.dart';
import '../../common/api_service.dart';
import '../../common/status_utils.dart';
import '../../common/widgets.dart';

class AgriHome extends StatefulWidget {
  final String token;
  const AgriHome({required this.token, super.key});

  @override
  AgriHomeState createState() => AgriHomeState();
}

class AgriHomeState extends State<AgriHome> with TickerProviderStateMixin, WidgetsBindingObserver {
  String get token => widget.token;
  Map<String, List<Map<String, dynamic>>> userByproduct = {};
  List<Map<String, dynamic>> donutData = [];
  final TextEditingController weightController = TextEditingController();

  // UI 상태 관리
  String sortBy = "name"; // 정렬 기준 : name, status
  Timer? _timer;

  static const Color lightbackgroundBrown = Color(0xFF8D6E63);
  static const Color backgroundBrown = Color(0xFFD7CCC8);
  static const Color cardBrown = Color(0xFFEFEBE9);


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
    setState(() {});
    if (disposed) {
    showSnack("부산물이 폐기 처리되었습니다.");
  } else {
    showSnack("부산물이 성공적으로 추가되었습니다.");
  }
    return true;
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


  /// data transform helper function
  Map<String, dynamic> transformItem(String type, Map<String, dynamic> item, int defaultThreshold,) {
    final threshold = (item["threshold"] ?? defaultThreshold) as num;
    final weight = (item["weight_float"] ?? 0) as num;

    return {
      "name": item['name'],
      "type": type,
      "threshold": threshold,
      "weight": weight,
      "percent": (weight / threshold).clamp(0.0, 1.0),
    };
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
                    color: cardBrown,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 36, left: 8, right: 8, bottom: 50),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(Icons.arrow_back, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: StatefulBuilder(
                            builder: (context, setInnerState) {
                              setModalBodyState = setInnerState;

                              return _buildHistoryList(name, cachedHistory["$type $name"] ?? []);
                            },
                          ),
                        ),

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
                                      setModalBodyState(() {});
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: BorderSide(color: lightbackgroundBrown),
                                    foregroundColor: lightbackgroundBrown,
                                  ),
                                  child: Text("부산물 폐기"),
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
                                      setModalBodyState(() {});
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    backgroundColor: lightbackgroundBrown,
                                    foregroundColor: cardBrown,
                                  ),
                                  child: Text("부산물 추가"),
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

    if (!cachedHistory.containsKey(key)) cachedHistory[key] = [];

    final existingKeys = cachedHistory[key]!.map((e) => "${e['timestampFull']}_${e['type']}_${e['name']}").toSet();

    final uniqueNewData = filteredData.where((entry) {
      return !existingKeys.contains("${entry['timestampFull']}_${entry['type']}_${entry['name']}");
    }).toList();

    cachedHistory[key] = [...uniqueNewData, ...cachedHistory[key]!];

    final limitDate = now.subtract(Duration(days: 30));
    cachedHistory[key] = cachedHistory[key]!.where((entry) {
      final entryDate = DateTime.parse(entry['timestamp']);
      return entryDate.isAfter(limitDate) || entryDate.isAtSameMomentAs(limitDate);
    }).toList();

    return List<Map<String, dynamic>>.from(cachedHistory[key]!);
  }






/* UI 구현 */
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: backgroundBrown,
      appBar: buildCustomAppBar(
        context: context,
        title: '부산물 관리',
        token: widget.token,
        showBackButton: false,
        showActions: true,
        onRefresh: () async {
          await fetchUserByProduct();
          await updateData(userByproduct); // 또는 fetchUserByProduct + updateData
        },
      ),
 
      body: Column(
        children: [
          SizedBox(height: 15),
          _buildSummaryHeader(),
          _buildCheckbox(),
          _buildByproductInfo()
        ],
      ),
      floatingActionButton: _buildNewProductButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: bottomNavigationBar(context, [
          BottomNavItem(icon: Icons.home_rounded, label: '홈', isSelected: true, onTap: () {}),
          BottomNavItem(icon: Icons.local_shipping_rounded, label: '배송 요청', onTap: () => onDeliveryRequestTap(context))
        ],
        color: cardBrown
      ),
    );
  }


  Widget _buildNewProductButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: () => _showAddWeightDialog("새 부산물 등록",null,null, false),
          backgroundColor: lightbackgroundBrown,
          foregroundColor: cardBrown,
          shape: CircleBorder(side: BorderSide(color: Colors.black26)),
          child: Icon(Icons.add, size: 45),
        ),
        SizedBox(height: 15),
        Text('부산물 종류 등록', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),),
      ],
    );
  }

  Widget _buildByproductInfo(){
    final filteredData = getFilteredData();
    return Expanded(
        child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 5),
            itemCount: filteredData.length,
            itemBuilder: (context, index) {
              return _buildListItem(filteredData[index]);
            })
    );
  }

  Widget _buildSummaryHeader(){
    List<Map<String, dynamic>> filtered = getFilteredData();
    Map<String,dynamic> DangerData;

    if (donutData.isEmpty || filtered.isEmpty) DangerData = {"danger": 0};
    else {
      int dangerCount = filtered.where((item) => item["percent"] >= 0.9).length;
      DangerData = {"danger": dangerCount};
    }
    return Container(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(color: Color(0xC8DF3838), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.warning, color: cardBrown, size: 20)),
                            Text("포화 위험 품목", style: TextStyle(color: cardBrown, fontSize: 16)),
                          ],
                        ),
                        Text("${DangerData['danger']}개", style: TextStyle(color: cardBrown, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }

  Widget _buildCheckbox(){
    return
      Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildFilterCheckbox("가공", isProcessChecked, (newValue) {
                  setState(() { isProcessChecked = newValue!; });
                }),
                SizedBox(width: 4),
                _buildFilterCheckbox("수확", isHarvestChecked, (newValue) {
                  setState(() { isHarvestChecked = newValue!; });
                }),
              ],
            ),
            /// 우측: 정렬 드롭다운
            Container(
              decoration: BoxDecoration(color: cardBrown, borderRadius: BorderRadius.circular(12),),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  items: [DropdownMenuItem(value: "name", child: Text("이름순")), DropdownMenuItem(value: "status", child: Text("위험도순")),],
                  onChanged: (value) { setState(() { sortBy = value!;});},
                ),
              ),
            ),
          ],
        ),
      );
  }

  // NavTap 관리
  void onDeliveryRequestTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryReqAgriculturePage(token: token, userByproduct: userByproduct)),
    ).then((result) {
      if (result == true) fetchUserByProduct().then((_) => updateData(userByproduct));
    });
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
            decoration: BoxDecoration(border: Border.all(color: Colors.black26, width: 1)),
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              checkColor: Colors.black,
              activeColor: cardBrown,
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
        default:
          return a["name"].compareTo(b["name"]);
      }
    });
    return filtered;
  }


  Widget _buildWarningBadge(double percent) {
    if (percent < 0.8) return SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 12, color: Colors.black87),
            SizedBox(width: 4),
            Text("위험", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
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
    final latestWeight = history.isNotEmpty ? history.first["current_weight_float"] : 0.0;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$name 부산물", style: TextStyle(fontSize: 16)),
          SizedBox(height: 14),
          Text("${latestWeight.toStringAsFixed(1)} $weight_unit", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 75),
          Expanded(
            child: ListView.builder(
              key: ValueKey(history.length),
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
                              "${entry["weight_diff_float"] > 0 ? "+" : ""}${entry["weight_diff_float"].toStringAsFixed(1)} $weight_unit",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: entry["weight_diff_float"] > 0 ? Colors.black87 : Color(0xFFED2939),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text("${entry["current_weight_float"].toStringAsFixed(1)} $weight_unit",
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



  Widget _buildActionButtons(Map<String, dynamic> item) {
    return Row(
      children: [
        Expanded(
          child: SingleActionButton(
            label: '폐기',
            onPressed: () {
              _showAddWeightDialog("부산물 폐기 등록", item['type'], item['name'], true);
            },
            backgroundColor: lightbackgroundBrown,
            foregroundColor: Colors.white,
            borderRadius: 10,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleActionButton(
            label: '추가',
            onPressed: () {
              _showAddWeightDialog("부산물 무게 추가", item['type'], item['name'], false);
            },
            backgroundColor: lightbackgroundBrown,
            foregroundColor: Colors.white,
            borderRadius: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percent, Color color) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: backgroundBrown,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
            ),
          ),
        ),
        SizedBox(width: 10),
        Text(
          "${(percent * 100).toInt()}%",
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    );
  }



  Widget _buildListItem(Map<String, dynamic> item) {
    double percent = item["percent"];
    Color progressColor = getProgressColor(percent);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBrown,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: cardBrown.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
        border: Border.all(color: Colors.grey.withOpacity(0.6), width: 1.0,)
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
                            TextSpan(text: "${item['weight']}$weight_unit"),
                          ],
                        ),
                      ),
                    ),
                    _buildWarningBadge(percent)
                  ],
                ),
              ),

              OutlinedButton(
                onPressed: () {
                  showHistoryPreviewUI(context, item['type'], item['name']);
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2),),
                  side: BorderSide(color: Colors.black),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text("재고 내역", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildProgressBar(percent, progressColor),
          SizedBox(height: 10),
          _buildActionButtons(item)
        ],
      ),
    );
  }


  /// 부산물 추가 다이얼로그
  Future<bool> _showAddWeightDialog(String label, String? type, String? name, bool disposed) async {
    final isFixed = type != null && name != null;
    String? selectedType = type;
    String? selectedByproduct = name;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,),
              decoration: BoxDecoration(color: cardBrown, borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildCategoryInputSection( label: label, isFixed: isFixed, selectedType: selectedType, selectedByproduct: selectedByproduct,
                    onTypeChanged: (value) {
                      setModalState(() {
                        selectedType = value;
                        selectedByproduct = null;
                      });
                    },
                    onByproductChanged: (value) {
                      setModalState(() { selectedByproduct = value;});
                    },
                    controller: weightController,
                    onSubmit: () {
                      final type = selectedType;
                      final name = selectedByproduct;
                      final weight = weightController.text.trim();

                      if (type == null || name == null || weight.isEmpty) {
                        showSnack("무게, 타입, 이름을 모두 입력하세요");
                        return;
                      }

                      //확인 팝업
                      showConfirmPopup(
                        context: context,
                        typeLabel: type,
                        productName: name,
                        weightText: weight,
                        actionText: _getActionText(label),
                        onConfirm: () async {
                          final success = await addWeight(disposed, type, name, weight);
                          if (!success) {
                            Navigator.pop(context, false);
                          } else {
                            await updateData(userByproduct);
                            weightController.clear();
                            Navigator.pop(context, true);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result == true; // null 또는 false → 실패
  }

//팝업 정보
  String _getActionText(String label) {
  if (label.contains("무게 추가")) return "추가하시겠습니까?";
  if (label.contains("폐기")) return "를 폐기하시겠습니까?";
  if (label.contains("새 부산물")) return "부산물을 등록하시겠습니까?";
  return "등록하시겠습니까?";
}

  List<Widget> _buildCategoryInputSection({
    required String label,
    required bool isFixed,
    required String? selectedType,
    required String? selectedByproduct,
    required ValueChanged<String?> onTypeChanged,
    required ValueChanged<String?> onByproductChanged,
    required TextEditingController controller,
    required VoidCallback onSubmit,
  }) {
    return [
      Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
      const SizedBox(height: 20),

      _buildDropdownSection(
          label: '부산물 유형 선택',
          dropdown: isFixed ? CommonDropdownField(value: selectedType, items: [selectedType!], onChanged: null, isEnabled: false)
            : CommonDropdownField(value: selectedType, items: ['가공', '수확'], onChanged: onTypeChanged, hintText: '유형을 선택해주세요')
      ),

      if (selectedType != null)
        _buildDropdownSection(
          label: '품목 선택',
          dropdown: isFixed ? CommonDropdownField(value: selectedByproduct, items: [selectedByproduct ?? ''], onChanged: null, isEnabled: false)
              : CommonDropdownField(
            value: selectedByproduct,
            items: byproductsCategory.where((item) => item['type'] == selectedType)
                .map((item) => item['name']!).toList(),
            onChanged: onByproductChanged,
            hintText: '품목을 선택해주세요',
          )
        ),

      const SizedBox(height: 16),
      Text('무게 입력 ($weight_unit)'),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: '예: 100',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      const SizedBox(height: 20),
      SingleActionButton(label: '등록하기', onPressed: onSubmit, backgroundColor: lightbackgroundBrown , borderRadius: 12,
      ),
    ];
  }

  Widget _buildDropdownSection({required String label, required Widget dropdown}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label), SizedBox(height: 8), dropdown]
    );
  }
}
