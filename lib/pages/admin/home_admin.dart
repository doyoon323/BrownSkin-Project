import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';
import 'dart:convert';
import 'package:brownskin_app/model/ByProduct.dart';
import 'package:brownskin_app/model/RegionWeight.dart';
import 'dart:async';
import 'package:brownskin_app/pages/admin/setThreshold_admin.dart';

//관리자 홈 화면 (부산물 데이터를 시각화하여 보여준다)
class AdminHomePage extends StatefulWidget {
  /* 인증 토큰을 매개변수로 받아 저장 */
  final String token;
  const AdminHomePage({required this.token, super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with TickerProviderStateMixin {

  List<ByProduct> data = []; //전체 데이터
  List<String> usernames = []; // 사용자 이름 추출
  List<double> weights = []; // 무게 추출

  String? selectedProvince; // default = 미선택
  String? selectedType = "가공"; // default = 가공
  Map<String, String?>? selectedByproduct = {"name": "사과", "type": "가공"};
  String? selectedByproductName = "사과"; // default = 가공


  List<String> provinces = [];
  List<RegionWeight>? regionData;
  double? totalWeight = 0.0;

  //UI 구성
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartAnimationController, curve: Curves.elasticOut),
    );

    // 데이터 로드  (화면에 띄울 데이터 분류, 동적 지역 정보)
    updateInfo();
    getProvinceData();
  }

  Future<void> getProvinceData() async {
    String? nextUrl = "$BASE_URL/api/byprod-list?page=1";
    List<String> temp = [];

    while (nextUrl != null) {
      final result = await http.get(
        Uri.parse(nextUrl),
        headers: {'Authorization': 'Token ${widget.token}'},
      );

      if (result.statusCode == 200) {
        final body = jsonDecode(utf8.decode(result.bodyBytes));
        final List<dynamic> results = body['results']; // 관리자가 가진 모든 업체의 데이터를 불러와서

        // addr1 (시,도 정보)만 추출
        temp.addAll(results.map<String>((item) => item['user']['addr1'] as String));

        nextUrl = body['next'] as String?;
      } else {
        throw Exception('지역 정보 불러오기 실패 : ${result.statusCode}');
      }
    }

    // 중복 제거
    setState(() {
      provinces = temp.toSet().toList();
      provinces = ["전국"] + provinces;
    });

    print("================$provinces================");
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  void updateInfo() async {
    setState(() {
      isLoading = true;
    });

    String? selectedDistrict; // 시도 까지만 구현. 더 자세한 주소는.. (이하생략)
    List<RegionWeight> tempList1 = [];

    Map<String, dynamic> sumData;
    if (selectedProvince == "전국") {
      sumData = await getData(
        selectedType,
        selectedByproductName,
        null,
        selectedDistrict,
      );
    }
    else {
      sumData = await getData(
        selectedType,
        selectedByproductName,
        selectedProvince,
        selectedDistrict,
      );
    }

    if (sumData.containsKey("results") && sumData["results"] != null) { //전국단위라 모든 시,도를 긁어ㄴ오는ing....
      final resultsMap = sumData["results"] as Map<String, dynamic>;

      // Map을 entries로 순회해서 RegionWeight 리스트 생성
      tempList1 = resultsMap.entries.map(
            (entry) =>
            RegionWeight(
              weight: (entry.value as num).toDouble(),
              city: entry.key,
            ),
      ).toList();

      setState(() {
        regionData = tempList1;
        totalWeight = (sumData["total_weight"] as num?)?.toDouble();
        isLoading = false;
      });
    } else { //하나의 시만 보여주는 ing... 근데 무게만 보이면 심심하니까... 업체도 그냥 전부 보여주자는 스불재..

      await getDisposerData(selectedProvince);
      setState(() {
        totalWeight = (sumData["total_weight"] as num?)?.toDouble();
        isLoading = false;
      });
    }

    _animationController.forward();
    _chartAnimationController.forward();
  }

  // A안: default를 가공/사과로 설정해두기
  Future<Map<String, dynamic>> getData(String? type, String? name,
      String? addr1,
      String? addr2) async {
    String url = "$BASE_URL/api/sum-byprod?" "type=$type&" "name=$name";

    if (addr1 != null) { //시도
      url += "&addr1=$addr1";
    }

    if (addr2 != null && addr1 != null) { //구
      url += "&addr2=$addr2";
    }

    final headers = {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": "Token ${widget.token}",
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      // 현 상황에서는 total_weight 외 필요 하지 않음
      //전국이면 results, addr1이면 total weight;
      final data = jsonDecode(
        response.body,); //result = weight of type-name fruit in address
      return data;
    } else {
      throw Exception('Failed to load data');
    }
  }

  /* 서버에서 데이터를 받아오는 함수 */
  Future<void> getDisposerData(String? addr1) async {
    /* 로딩 상태로 UI 갱신 */
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      /* 첫 페이지 URL */
      String? nextUrl = "$BASE_URL/api/byprod-list?" "addr1=$addr1&" "type=$selectedType&" "name=$selectedByproductName&"
          + "page=1";
      List<ByProduct> allData = [];

      /* 페이지 순회하며 모든 데이터를 받아옴 */
      while (nextUrl != null) {
        var result = await http.get(
          Uri.parse(nextUrl),
          headers: {'Authorization': 'Token ${widget.token}'},
        );

        /* 서버 인증 성공 시 */
        if (result.statusCode == 200) {
          final body = jsonDecode(utf8.decode(result.bodyBytes));
          final List<dynamic> results = body['results'];

          try {
            /* JSON 데이터를 모델 객체로 변환하여 리스트에 추가 */
            allData.addAll(results.map((item) => ByProduct.fromJson(item)));
          } catch (e) {
            print('파싱 오류: $e');
            throw Exception('데이터 파싱 중 오류가 발생했습니다.');
          }

          /* 다음 페이지 URL 설정 (없으면 null) */
          nextUrl = body['next'] as String?;
        } else {
          throw Exception('서버 오류: ${result.statusCode}');
        }
      }

      /* 정렬 및 데이터 상태 업데이트 */
      usernames = allData.map((e) => e.username).toList();
      weights = allData.map((e) => e.weight).toList();
      allData.sort((a, b) => a.company_name.compareTo(b.company_name));

      setState(() {
        data = allData;
        isLoading = false;
      });

      /* UI 실행 */
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Widget buildRegionBarChart(List<RegionWeight> data) {
    final barGroups = data
        .asMap()
        .entries
        .map(
          (entry) {
        final index = entry.key;
        final item = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.weight,
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade300,
                  Colors.green.shade600,
                  Colors.green.shade800,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 24,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        );
      },
    )
        .toList();

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: data.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 50,
              minY: 0,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toInt()}kg",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            idx >= 0 && idx < data.length ? data[idx].city : "",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  int selectedIndex = 0;

  void _onItemTapped(BuildContext context, int index) async {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) {
      // 홈
    } else if (index == 1) {
      // 임계 설정 페이지로 이동i
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SetThresholdAdminPage(provinces: provinces, token : widget.token)
        ),
      );

        if (result != null){
          setState(() {
            selectedIndex = result;
          });
          updateInfo();
          getProvinceData();
        }else{
          setState(() {
            selectedIndex = 0;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '부산물 데이터 관리',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  '데이터를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                Text(
                  '필터 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 부산물 유형 선택
            _buildDropdownField(
              label: '부산물 유형',
              icon: Icons.category,
              value: selectedType,
              items: ["가공", "수확"],
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                  selectedByproductName = null;
                  _chartAnimationController.reset();
                  updateInfo();
                });
              },
            ),

            if (selectedType != null) ...[
              const SizedBox(height: 16),
              _buildDropdownField(
                label: '품목',
                icon: Icons.agriculture,
                value: selectedByproductName,
                items: byproductsCategory
                    .where((item) => item['type'] == selectedType)
                    .map((item) => item['name']!)
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedByproductName = value;
                    _chartAnimationController.reset();
                    updateInfo();
                  });
                },
              ),

              const SizedBox(height: 16),
              _buildDropdownField(
                label: '지역',
                icon: Icons.location_on,
                value: selectedProvince,
                items: provinces,
                onChanged: (value) {
                  setState(() {
                    selectedProvince = value;
                    _chartAnimationController.reset();
                    updateInfo();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: "$label을 선택해주세요",
              hintStyle: TextStyle(color: Colors.grey.shade500),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 6,
      shadowColor: Colors.green.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.scale,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '총 무게',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${selectedProvince ?? '전국'}의 ${selectedByproductName ?? ''}(${selectedType ?? '전국'}) 부산물",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              totalWeight != null
                  ? "${totalWeight!.toStringAsFixed(1)} kg"
                  : "데이터 없음",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    if (regionData != null && regionData!.isNotEmpty) {
      return _buildChartCard(
        title: "지역별 무게 분포",
        icon: Icons.bar_chart,
        child: buildRegionBarChart(regionData!),
      );
    } else if (data.isNotEmpty) {
      return _buildChartCard(
        title: "업체별 무게 분포",
        icon: Icons.business,
        child: buildCompanyBarChart(data),
      );
    } else {
      return _buildEmptyDataCard();
    }
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.green.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(height: 300, child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDataCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '표시할 데이터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '필터를 조정해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade600,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: '임계 설정',
          ),
        ],
      ),
    );
  }

  Widget buildCompanyBarChart(List<ByProduct> data) {
    final barGroups = data
        .asMap()
        .entries
        .map(
          (entry) {
        final index = entry.key;
        final item = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.weight,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.shade300,
                  Colors.teal.shade600,
                  Colors.teal.shade800,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 24,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        );
      },
    )
        .toList();

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: data.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 50,
              minY: 0,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        "${value.toInt()}kg",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            idx >= 0 && idx < data.length ? data[idx].company_name : "",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}