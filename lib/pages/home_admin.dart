import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';
import 'dart:convert';
import 'package:brownskin_app/model/ByProduct.dart';
import 'package:brownskin_app/model/RegionWeight.dart';
import 'dart:async';

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

  static const List<Map<String, String?>> byproductsCategory = [
    {"type": "가공", "name": "사과"},
    {"type": "수확", "name": "사과"},
    {"type": "수확", "name": "배추"},
    {"type": "수확", "name": "참깨"},
    {"type": "수확", "name": "옥수수"},
  ];

  List<String> provinces = [];

  List<RegionWeight>? regionData;

  double? totalWeight = 0.0;

  //UI 구성
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );


    // 최초 페이지 로딩 시 데이터 불러오기
    updateInfo();
    getProvinceData();
  }


  Future<void> getProvinceData() async {
    print("✅ getProvinceData() 호출됨");
    String? nextUrl = "$BASE_URL/api/byprod-list?page=1";
    List<String> temp = [];

    while (nextUrl != null) {
      print("✅ while 루프 시작: $nextUrl");
      final result = await http.get(
        Uri.parse(nextUrl),
        headers: {'Authorization': 'Token ${widget.token}'},
      );

      if (result.statusCode == 200) {
        final body = jsonDecode(utf8.decode(result.bodyBytes));
        final List<dynamic> results = body['results'];

        print("✅$results");
        // 여기서 addr1만 추출
        temp.addAll(
            results.map<String>((item) => item['user']['addr1'] as String)
        );

        nextUrl = body['next'] as String?;
      } else {
        throw Exception('서버 오류: ${result.statusCode}');
      }
    }

    // 중복 제거
    setState(() {
      provinces = temp.toSet().toList(); // 중복 제거해서 리스트에 담기
      provinces = ["전국"] + provinces;
    });

    print("================$provinces================");
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void updateInfo() async {
    print("👁️ UPDATA INFO ");
    String? selectedDistrict = null;
    List<RegionWeight> tempList1 = [];

    var sum_data;
    if (selectedProvince == "전국"){
      sum_data = await getData(
        selectedType,
        selectedByproductName,
        null,
        selectedDistrict,
      );
    }
    else {
      sum_data = await getData(
        selectedType,
        selectedByproductName,
        selectedProvince,
        selectedDistrict,
      );
    }

    if (sum_data.containsKey("results") && sum_data["results"] != null) { //전국단위라 모든 시,도를 긁어ㄴ오는ing....
      final resultsMap = sum_data["results"] as Map<String, dynamic>;

      // Map을 entries로 순회해서 RegionWeight 리스트 생성
      tempList1 = resultsMap.entries.map(
            (entry) => RegionWeight(
          weight: (entry.value as num).toDouble(),
              city: entry.key,
            ),
      ).toList();

      setState(() {
        regionData = tempList1;
        totalWeight = (sum_data["total_weight"] as num?)?.toDouble();
      });
    } else { //하나의 시만 보여주는 ing... 근데 무게만 보이면 심심하니까... 업체도 그냥 전부 보여주자는 스불재..

      await getDisposerData(selectedProvince);
      setState(() {
        totalWeight = (sum_data["total_weight"] as num?)?.toDouble();
      });
    }
  }

  // A안: default를 가공/사과로 설정해두기
  Future<Map<String, dynamic>> getData(String? type, String? name,
      String? addr1,
      String? addr2) async {
    String url = "$BASE_URL/api/sum-byprod?" + "type=$type&" + "name=$name";

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
      //전국이면 results, addr1이면 total weight;
      // 현 상황에서는 total_weight 외 필요 하지 않음
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

      String? nextUrl = "$BASE_URL/api/byprod-list?"+"addr1=$addr1&"+"type=$selectedType&"+"name=$selectedByproductName&"
          +"page=1";
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
    final barGroups = data.asMap().entries.map(
          (entry) {
        final index = entry.key;
        final item = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.weight,
              color: Colors.indigo,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      },
    ).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 50,
        minY: 0,
        barGroups: barGroups,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  "${value.toInt()}kg",
                  style: const TextStyle(fontSize: 10),
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
                  child: Text(
                    idx >= 0 && idx < data.length ? data[idx].city : "",
                    style: const TextStyle(fontSize: 10),
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
          border: const Border(
            bottom: BorderSide(),
            left: BorderSide(),
          ),
        ),
        gridData: FlGridData(show: true),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('무게 데이터 관리'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // 부산물 유형 선택
            const Text('부산물 유형 선택'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              hint: const Text("유형을 선택해주세요"),
              items: ["가공", "수확"].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                  selectedByproductName = null;
                  updateInfo(); // 유형 선택 시 갱신
                });
              },
            ),


            if (selectedType != null) ...[
              const SizedBox(height: 16),
              const Text('품목 선택'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedByproductName,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                hint: const Text("품목을 선택해주세요"),
                items: byproductsCategory
                    .where((item) => item['type'] == selectedType)
                    .map(
                      (item) =>
                      DropdownMenuItem<String>(
                        value: item['name'],
                        child: Text(item['name']!),
                      ),
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedByproductName = value;
                    print("value : $value and selectedByproductName : $selectedByproductName");
                    updateInfo(); // 품목 선택 시 갱신
                  });
                },
              ),

              const SizedBox(height: 16),
              const Text('지역 선택'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedProvince,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                hint: const Text("지역을 선택하세요"),
                items: provinces.map((province) {
                  return DropdownMenuItem(
                      value: province, child: Text(province));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProvince = value;
                    updateInfo(); // 지역 선택 시 갱신
                  });
                },
              ),
            ],

            const SizedBox(height: 24),

            // 무게 설명
            Text(
              "${selectedProvince ?? '전국'}의 ${selectedByproductName ??
                  ''}(${selectedType ?? '전국'}) 부산물의 총 무게",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            const SizedBox(height: 8),

            // 무게 데이터 표시
            Text(
              totalWeight != null
                  ? "${totalWeight!.toStringAsFixed(1)} kg"
                  : "데이터 없음",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),

            if (regionData != null && regionData!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "지역별 무게 분포",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: buildRegionBarChart(regionData!),
              ),
            ]
            else if (data != null && data!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "업체별 무게 분포",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: buildCompanyBarChart(data!),
              ),
            ]

          ],
        ),
      ),
    );
  }
}

Widget buildCompanyBarChart(List<ByProduct> data) {
  final barGroups = data.asMap().entries.map(
        (entry) {
          print("🤢🤢 $entry");
      final index = entry.key;
      final item = entry.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.weight,
            color: Colors.teal,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    },
  ).toList();

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: data.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 50,
      minY: 0,
      barGroups: barGroups,
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                "${value.toInt()}kg",
                style: const TextStyle(fontSize: 10),
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
                child: Text(
                  idx >= 0 && idx < data.length ? data[idx].company_name : "",
                  style: const TextStyle(fontSize: 10),
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
        border: const Border(
          bottom: BorderSide(),
          left: BorderSide(),
        ),
      ),
      gridData: FlGridData(show: true),
    ),
  );
}