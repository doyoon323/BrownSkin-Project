import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';
import 'dart:convert';
import 'dart:async';
import 'package:brownskin_app/pages/admin/setThreshold_admin.dart';
import 'package:brownskin_app/pages/admin/global.dart';

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

  // dropdown 저장용 변수

  String selectedType = "수확"; // default = 수확
  String? selectedByproductName = "사과"; // default = 사과

  double threshold = 1;


  //UI 구성
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;


  //Maps
  bool _isNaverMapInitialized = false;
  List<NMarker> _provinceMarkers = [];
  List<NMarker> _districtMarkers = [];
  NaverMapController? _controller;


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


    // 데이터 로드  (화면에 띄울 데이터 분류, 동적 지역 정보)
    initData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeNaverMap() async {
    print("😍😍😍😍😍initNaverMap()");
    final naverMap = FlutterNaverMap();
    await naverMap.init(
      clientId: 'fqc49wyjq4',
      onAuthFailed: (error) {
        print("네이버 지도 인증 실패: $error");
      },
    );
    setState(() {
      _isNaverMapInitialized = true;
    });
  }

    Future<void> initData() async {
      print("👉 initData(): START");

      await getProvinceData();
      print("✅ getProvinceData() 완료");

      await loadAllDistricts();
      print("✅ loadAllDistricts() 완료");

      await _initializeNaverMap();
      print("✅ _initializeNaverMap() 완료");

      print("✅ 전체 데이터 로드 완료: $allAreas");

      threshold = await getThreshold(selectedType, selectedByproductName);
      print("✅ getThreshold 완료  & $selectedType $selectedByproductName의 threshold: $threshold");


      _provinceMarkers = await _generateProvinceMarkers();
      print("✅ _generateProvinceMarkers() 완료 (총 ${_provinceMarkers.length}개)");

      _districtMarkers = await _generateDistrictMarkers();
      print("✅ _generateDistrictMarkers() 완료 (총 ${_districtMarkers.length}개)");


      setState(() {
        isLoading = false;
      });

      print("👉 initData(): END");
    }


    Future<void> getProvinceData() async {
      String url = "$BASE_URL/api/addr-list";

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Token ${widget.token}'},
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(utf8.decode(response.bodyBytes));
          final List<dynamic> result = body['addr1_list'];

          // Map으로 초기화
          setState(() {
            allAreas = {
              for (final province in result) province.toString(): []
            };
          });
        } else {
          throw Exception('지역 정보 불러오기 실패 : ${response.statusCode}');
        }
      } catch (e) {
        print("getProvinceData 예외 발생: $e");
      }
    }

  Future<Map<String, dynamic>> getWeightData(String type, String? byproduct, String? addr1,String? addr2) async {
    String url = "$BASE_URL/api/sum-byprod?type=$type&name=$byproduct";

    String returnfield = "results";
    if (addr1 != null){
      url += "&addr1=$addr1";
    }
    if (addr2 != null){
      url += "&addr2=$addr2";
    }

    print("🔍 provinceWeightData 요청: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token ${widget.token}'},
      );

      print("📨 응답 상태 코드: ${response.statusCode}");
      print("📨 응답 바디: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (addr2 != null){
          return body as Map<String, dynamic>;
        }
        return body[returnfield] as Map<String, dynamic>;


      } else {
        throw Exception("API 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("getProvinceWeightData() 예외: $e");
      // **빈 Map을 반환해 null이 안 되도록**
      return {};
    }
  }


  Future<double> getThreshold (String type, String? byproduct) async {
    String url = "$BASE_URL/api/threshold?type=$type&name=$byproduct";

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      print("☎️😋😋😋😋$body");
      return body['weight_float'] == null ? -1 : body['weight_float'] as double;
    }
    else {
      throw Exception("get Threshold() 실패: ${response.statusCode}");
    }
  }

    Future<List<String>> getDistrictData(String province) async {
      String url = "$BASE_URL/api/addr-list?addr1=$province";

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Token ${widget.token}'},
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(utf8.decode(response.bodyBytes));

          // API 결과 예: {"addr2_list": ["강남구","송파구"]}
          final List<dynamic> result = body['addr2_list'];

          // List<String>으로 변환해서 반환
          return result.map((e) => e.toString()).toList();
        } else {
          throw Exception('시군구 정보 불러오기 실패 : ${response.statusCode}');
        }
      } catch (e) {
        print("getDistrictData 예외 발생: $e");
        // 실패 시 빈 리스트 반환
        return [];
      }
    }

    Future<void> loadAllDistricts() async {
      final provinceList = allAreas.keys.toList();

      final futures = provinceList.map((province) => getDistrictData(province));
      final results = await Future.wait(futures);

      setState(() {
        for (int i = 0; i < provinceList.length; i++) {
          allAreas[provinceList[i]] = results[i];
        }
      });
    }

  Future<NLatLng> getLatLngFromAddress(String addr1, String addr2) async {
    print("🔍 getLatLngFromAddress(): $addr1 $addr2");

    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=${addr1 + addr2}'
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'KakaoAK 75acb2a58d477b9c94d5c3e61790980b'
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['documents'].isEmpty) {
        print("⚠️ 주소 결과 없음: $addr1 $addr2");
        print("⚠️ Province '$addr1 $addr2' 마커 생성 실패");
        return NLatLng(0, 0);
      }
      final doc = body['documents'][0];
      print("✅ 좌표 결과: ${doc['y']}, ${doc['x']}");
      return NLatLng(
        double.parse(doc['y']),
        double.parse(doc['x']),
      );
    } else {
      print("❌ API 호출 실패: ${response.statusCode}");
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }



  Future<List<NMarker>> _generateProvinceMarkers() async {
    List<NMarker> markers = [];
    print("👉 _generateProvinceMarkers() 시작");


    // results Map만 반환하도록 구현했다고 가정
    Map<String, dynamic> provinceWeightData = await getWeightData(selectedType, selectedByproductName, null, null);
    print("✅ provinceWeightData: $provinceWeightData");


    for (var province in allAreas.keys) {
      NLatLng latLng = await getLatLngFromAddress(province, "");
      print("📍 Province 마커 생성: $province (${latLng.latitude}, ${latLng.longitude})");

      if (latLng.latitude == 0 && latLng.longitude == 0) {
        continue;
      }




      double? weight = 0.0;
      if (provinceWeightData.containsKey(province)) {
        weight = (provinceWeightData[province] as num).toDouble();
      }



      final percent = (weight! / threshold).clamp(0.0, 1.0);


      Color color;
      if (percent >= 0.9) {
        color = Colors.red.shade600;
      } else if (percent >= 0.7) {
        color = Colors.orange.shade600;
      } else if (percent >= 0.5) {
        color = Colors.yellow.shade700;
      } else {
        color = Colors.green;
      }

      print("$province weight: $weight and threshold : $threshold, so percent is $percent\n Color is ${color.toString()}");
      NMarker marker = NMarker(
        id: province,
        position: latLng,
        caption: weight != null
            ? NOverlayCaption(
          text: weight.toString(),
          color: color, // 글자색
          haloColor: Colors.white, // 테두리 색
          textSize: 25, // 글자 크기
        )
            : NOverlayCaption(text: "0",
          color: Colors.green, // 글자색
          haloColor: Colors.white, // 테두리 색
          textSize: 25
        ),
          isForceShowCaption: true
      );
      markers.add(marker);
    }
    return markers;
  }



  Future<List<NMarker>> _generateDistrictMarkers() async {
    List<NMarker> markers = [];
    print("👉 _generateDistrictMarkers() 시작");

    double percent = 0.0;

    for (var entry in allAreas.entries) {
      final province = entry.key;
      final districts = entry.value;



      for (var district in districts) {
        NLatLng latLng = await getLatLngFromAddress(province, district);
        print("📍 District 마커 생성: $province $district (${latLng.latitude}, ${latLng.longitude})");


        if (latLng.latitude == 0 && latLng.longitude == 0) {
          continue;
        }


        Map<String, dynamic> provinceWeightData = await getWeightData(selectedType, selectedByproductName, province , district);

        double? weight;
        if (provinceWeightData.containsKey(district)) {
          weight = (provinceWeightData[district] as num).toDouble();
        } else if (provinceWeightData["total_weight"] != null) {
          weight = (provinceWeightData["total_weight"] as num).toDouble();
        }

        print("$province $district weight: $weight");

        final percent = (weight! / threshold).clamp(0.0, 1.0);

        Color color;
        if (percent >= 0.9) {
          color = Colors.red.shade600;
        } else if (percent >= 0.7) {
          color = Colors.orange.shade600;
        } else if (percent >= 0.5) {
          color = Colors.yellow.shade700;
        } else {
          color = Colors.green;
        }

        print("$province $district weight: $weight and threshold : $threshold, so percent is $percent\n Color is ${color.toString()}");

        NMarker marker = NMarker(
            id: "$province $district",
            position: latLng,
            caption: weight != null
                ? NOverlayCaption(
              text: weight.toString(),
              color: color, // 글자색
              haloColor: color, // 테두리 색
              textSize: 25, // 글자 크기
            )
                : NOverlayCaption(text: "0",
                color: Colors.green, // 글자색
                haloColor: Colors.white, // 테두리 색
                textSize: 25
            ),
            isForceShowCaption: true
        );
        markers.add(marker);
      }
    }
    return markers;
  }

    /* UI 구현 */
    Widget _buildMapSection() {
      return NaverMap(
        onMapReady: (controller) {
          _controller = controller;
          _onZoomChanged(6);
        },
        onCameraIdle: () async {
          final position = await _controller?.getCameraPosition();
          _onZoomChanged(position!.zoom);
        },
        options: NaverMapViewOptions(
          initialCameraPosition: NCameraPosition(
            target: NLatLng(36.5, 127.8), // 초기 중심 좌표
            zoom: 6,
          ),

          // 사용자가 스크롤/줌 가능 여부 (기본 true)
          scrollGesturesEnable: true,
          stopGesturesEnable: true,
          tiltGesturesEnable: true,
          rotationGesturesEnable: true,
        ),
      );
    }

  void _onZoomChanged(double zoom) {
    print("🔍 _onZoomChanged(): zoom = $zoom");
    _controller?.clearOverlays();

    if (zoom <= 7) {
      print("✅ 전국 마커 ${_provinceMarkers.length}개 표시");
      for (var marker in _provinceMarkers) {
        _controller?.addOverlay(marker);
      }
    } else {
      print("✅ 시군구 마커 ${_districtMarkers.length}개 표시");
      for (var marker in _districtMarkers) {
        _controller?.addOverlay(marker);
      }
    }
  }



    int selectedIndex = 0;
    Future<void> _onItemTapped(BuildContext context, int index) async {

      print("😍😍😍😍😍😍before Thresholde: $threshold");


      // 선택 인덱스 갱신
      setState(() {
        selectedIndex = index;
      });

      // 홈
      if (index == 0) {
        return;
      }

      // 임계 설정
      if (index == 1) {
        final result = await Navigator.push<int>(
          context,
          MaterialPageRoute(
              builder: (context) => SetThresholdAdminPage(token: widget.token)
          ),
        );

        // 복귀했울 때 result 없으면 홈으로
        if (result == null) {
          print("result is null || after Thresholde: $threshold");
          setState(() {
            selectedIndex = 0;
          });
          return;
        }

        setState(() {
          selectedIndex = result;
        });
        threshold = await getThreshold(selectedType, selectedByproductName);
        await _reloadMarkers();

        print("after Thresholde: $threshold");
      }
    }

  Future<void> _reloadMarkers() async {
    print("🔄 마커 리로드 시작");

    _provinceMarkers = await _generateProvinceMarkers();
    _districtMarkers = await _generateDistrictMarkers();

    // 현재 줌에 맞춰 지도에 새 마커 뿌리기
    final position = await _controller?.getCameraPosition();
    if (position != null) {
      _onZoomChanged(position.zoom);
    }
  }

  Widget _buildFilterBar() {
    final filteredByproducts = byproductsCategory
        .where((item) => item["type"] == selectedType)
        .map((item) => item["name"]!)
        .toSet()
        .toList();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 가공/수확 버튼
          ToggleButtons(
            borderRadius: BorderRadius.circular(6),
            selectedColor: Colors.white,
            fillColor: Colors.green,
            color: Colors.black87,
            isSelected: [
              selectedType == "가공",
              selectedType == "수확",
            ],
            onPressed: (index) async {
              setState(() {
                selectedType = index == 0 ? "가공" : "수확";
                // ✅ 타입 바뀌면 품목을 첫번째로 초기화
                final filtered = byproductsCategory
                    .where((item) => item["type"] == selectedType)
                    .map((item) => item["name"]!)
                    .toSet()
                    .toList();
                selectedByproductName = filtered.isNotEmpty ? filtered.first : null;
              });
              threshold = await getThreshold(selectedType, selectedByproductName);
              _reloadMarkers();
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("가공"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("수확"),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // 품목 드롭다운

          DropdownButton<String>(
            value: selectedByproductName,
            items: filteredByproducts.map((name) {
              return DropdownMenuItem(
                value: name,
                child: Text(name),
              );
            }).toList(),
            onChanged: (value) async {
              setState(() {
                selectedByproductName = value!;
              });
              threshold = await getThreshold(selectedType, selectedByproductName);
              _reloadMarkers();
            },
          )
        ],
      ),
    );
  }

    @override
    Widget build(BuildContext context) {
      if (!_isNaverMapInitialized) {
        return Center(child: CircularProgressIndicator());
      }

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
            :Stack(
          children: [
            _buildMapSection(),
            Align(
              alignment: Alignment.topCenter,
              child: _buildFilterBar(),
            ),
          ],
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600),
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
  }
