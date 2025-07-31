import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/pages/agriculture/deliveryReq_agriculture.dart';
import '../../common/api_service.dart';
import '../../common/status_utils.dart';
import '../../common/widgets.dart';
import 'dispose_history.dart';

class AgriHome extends StatefulWidget {
  final String token;
  const AgriHome({required this.token, super.key});

  @override
  AgriHomeState createState() => AgriHomeState();
}

class AgriHomeState extends State<AgriHome> with TickerProviderStateMixin, WidgetsBindingObserver {
  String get token => widget.token;
  Map<String, List<Map<String, dynamic>>> userByproduct = {};
  List<Map<String, dynamic>> productData = [];
  final TextEditingController weightController = TextEditingController();

  // UI 상태 관리
  String sortBy = "name"; // 정렬 기준 : name, status
  Timer? _timer;
  bool isProcessChecked = true;
  bool isHarvestChecked = true;

  List<DropdownMenuItem<String>> sortOptions = [
    DropdownMenuItem(value: "name", child: Text("이름순")),
    DropdownMenuItem(value: "status", child: Text("위험도순")),
  ];

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
    if (disposed) showSnack("부산물이 폐기 처리되었습니다.");
    else showSnack("부산물이 성공적으로 추가되었습니다.");

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
    setState(() { productData = tempList;});
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
          _buildSortSection(),
          _buildByproductInfo()
        ],
      ),
      floatingActionButton: _buildNewProductButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: bottomNavigationBar(context, [
          BottomNavItem(icon: Icons.home_rounded, label: '홈', isSelected: true, onTap: () {}),
          BottomNavItem(icon: Icons.local_shipping_rounded, label: '배송 요청', onTap: () => onDeliveryRequestTap(context))
        ], color: cardBrown)
    );
  }

  int _getDangerCount(List<Map<String, dynamic>> data) {
    return data.where((item) => item["percent"] >= 0.9).length;
  }


  Widget _buildSummaryHeader(){
    List<Map<String, dynamic>> filtered = getFilteredData();
    int dangerCount = (productData.isEmpty || filtered.isEmpty) ? 0 : _getDangerCount(filtered);

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
                        Text("${dangerCount}개", style: TextStyle(color: cardBrown, fontSize: 16)),
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

  Widget _buildSortSection(){
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
                FilterCheckbox(label: "가공", value: isProcessChecked, onChanged: (v) => setState(() => isProcessChecked = v!)),
                FilterCheckbox(label: "수확", value: isHarvestChecked, onChanged: (v) => setState(() => isHarvestChecked = v!)),
              ],
            ),
            /// 우측: 정렬 드롭다운
            Container(
              decoration: BoxDecoration(color: cardBrown, borderRadius: BorderRadius.circular(12),),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  items: sortOptions,
                  onChanged: (value) { setState(() { sortBy = value!;});},
                ),
              ),
            ),
          ],
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
        child: ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 5),
          itemCount: filteredData.length,
          itemBuilder: (context, index) => _buildListItem(filteredData[index]),
          separatorBuilder: (context, index) => SizedBox(height: 8),
        )
    );
  }


  Widget _buildListItem(Map<String, dynamic> item) {
    final double percent = item["percent"] ?? 0.0 ;
    final Color progressColor = getProgressColor(percent);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBrown,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [ BoxShadow(color: cardBrown, spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2)) ],
        border: Border.all(color: Colors.grey.withOpacity(0.8), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child:Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                      "[ ${item['type']} ] ${item['name']}  ${item['weight']}$weight_unit",
                      style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(
                        type: item['type'],
                        name: item['name'],
                        token: token,
                        onAddWeightDialog: _showAddWeightDialog,
                        cardBrown: cardBrown,
                        lightbackgroundBrown: lightbackgroundBrown,
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                  side: BorderSide(color: Colors.black),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text("재고 내역", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          SizedBox(height: 20),
          buildProgressBar(percent, progressColor, backgroundBrown),
          SizedBox(height: 10),
          _buildActionButtons(item),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getFilteredData() {
    List<Map<String, dynamic>> filtered = productData.where((item) {
      if (item["type"] == "가공" && !isProcessChecked) return false;
      if (item["type"] == "수확" && !isHarvestChecked) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) return [];
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

  // NavTap 관리
  void onDeliveryRequestTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeliveryReqAgriculturePage(token: token, userByproduct: userByproduct)),
    ).then((result) {
      if (result == true) fetchUserByProduct().then((_) => updateData(userByproduct));
    });
  }

  Widget _buildActionButtons(Map<String, dynamic> item) {
    return ActionButtonGroup(
      buttons: [
        ActionButtonData(
          label: '폐기',
          onPressed: () =>_showAddWeightDialog("부산물 폐기 등록", item['type'], item['name'], true),
          backgroundColor: lightbackgroundBrown,
        ),
        ActionButtonData(
          label: '추가',
          onPressed: () => _showAddWeightDialog("부산물 무게 추가", item['type'], item['name'], false),
          backgroundColor: lightbackgroundBrown,
        ),
      ],
      spacing: const EdgeInsets.only(right: 12),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      expanded: true,
    );
  }


//팝업 정보
  String _getActionText(String label) {
  if (label.contains("무게 추가")) return "추가하시겠습니까?";
  if (label.contains("폐기")) return "를 폐기하시겠습니까?";
  if (label.contains("새 부산물")) return "부산물을 등록하시겠습니까?";
  return "등록하시겠습니까?";
}


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
            return _buildWeightModalContent(
              label: label,
              isFixed: isFixed,
              selectedType: selectedType,
              selectedByproduct: selectedByproduct,
              onTypeChanged: (value) {
                setModalState(() {
                  selectedType = value;
                  selectedByproduct = null;
                });
              },
              onByproductChanged: (value) => setModalState(() => selectedByproduct = value),
              controller: weightController,
              onSubmit: () => _handleWeightSubmit(
                label: label,
                disposed: disposed,
                selectedType: selectedType,
                selectedByproduct: selectedByproduct,
                controller: weightController,
                context: context,
              ),
            );
          },
        );
      },
    );
    return result == true;
  }


  Widget _buildWeightModalContent({
    required String label,
    required bool isFixed,
    required String? selectedType,
    required String? selectedByproduct,
    required ValueChanged<String?> onTypeChanged,
    required ValueChanged<String?> onByproductChanged,
    required TextEditingController controller,
    required VoidCallback onSubmit,
  }) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(color: cardBrown, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('부산물 유형 선택'),
                SizedBox(height: 8),
                CommonDropdownField(
                  value: selectedType,
                  items: ['가공', '수확'],
                  onChanged: isFixed ? null : onTypeChanged,
                  isEnabled: !isFixed,
                  hintText: '유형을 선택해주세요',
                ),
              ],
            ),
            if (selectedType != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('품목 선택'),
                  SizedBox(height: 8),
                  CommonDropdownField(
                    value: selectedByproduct,
                    items: byproductsCategory.where((item) => item['type'] == selectedType).map((item) => item['name']!).toList(),
                    onChanged: isFixed ? null : onByproductChanged,
                    isEnabled: !isFixed,
                    hintText: '품목을 선택해주세요',
                  ),
                ],
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
            ActionButton(data: ActionButtonData(label: '등록하기', onPressed: onSubmit, backgroundColor: lightbackgroundBrown))
          ],
        ),
      ),
    );
  }


  void _handleWeightSubmit({
    required String label,
    required bool disposed,
    required String? selectedType,
    required String? selectedByproduct,
    required TextEditingController controller,
    required BuildContext context,
  }) {
    final type = selectedType;
    final name = selectedByproduct;
    final weight = controller.text.trim();

    if (type == null || name == null || weight.isEmpty) {
      showSnack("무게, 타입, 이름을 모두 입력하세요");
      return;
    }
    showConfirmPopup(
      context: context,
      typeLabel: type,
      productName: name,
      weightText: weight,
      actionText: _getActionText(label),
      onConfirm: () async {
        final success = await addWeight(disposed, type, name, weight);
        if (success) {
          await updateData(userByproduct);
          controller.clear();
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context, false);
        }
      },
    );
  }
}
