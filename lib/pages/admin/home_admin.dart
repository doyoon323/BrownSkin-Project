import 'package:brownskin_app/model/polygon_data.dart';
import 'package:brownskin_app/service/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:brownskin_app/constants.dart';
import 'dart:convert';
import 'dart:ui' as ui;

import 'dart:async';
import 'package:brownskin_app/pages/admin/setThreshold_admin.dart';
import 'package:brownskin_app/pages/admin/global.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


//관리자 홈 화면 (부산물 데이터를 시각화하여 보여준다)
class AdminHomePage extends StatefulWidget {
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

  double threshold = 1; //default


  //UI 구성
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;


  //Maps
  Set<Marker> _provinceMarkers = {}; //관리자가 가진 모든 시도 정보
  Set<Marker> _districtMarkers = {}; //관리자가 가진 모든 구 정보
  Set<Marker> currentMarkers = {}; //현재 지도에 띄울 마커
  GoogleMapController? _controller;
  final LatLng _center = const LatLng(35.5,127.8); //지도를 켰을 때 중심 좌표

  final polygonService = PolygonService(); // 지역별 경계선
  
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

    polygonService.createPolygonsFromConsts().then((_){
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }



    Future<void> initData() async {
      await getProvinceData();
      await loadAllDistricts();
      print("✅ 전체 데이터 로드 완료: $allAreas");
      threshold = await getThreshold(selectedType, selectedByproductName);
      _provinceMarkers = await _generateProvinceMarkers();
      _districtMarkers = await _generateDistrictMarkers();
      currentMarkers = _provinceMarkers;

      setState(() {
        isLoading = false;
      });
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

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token ${widget.token}'},
      );
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


  // Stack overlay로 바꾸길 요망
  Future<Set<Marker>> _generateProvinceMarkers() async {
    Set<Marker> markers = {};

    // results Map만 반환하도록 구현했다고 가정
    Map<String, dynamic> provinceWeightData = await getWeightData(
        selectedType, selectedByproductName, null, null);

    for (var province in allAreas.keys) {
      LatLng latLng = await getLatLngFromAddress(province, "");

      if (latLng.latitude == 0 && latLng.longitude == 0) {
        continue;
      }

      double weight = 0.0;
      if (provinceWeightData.containsKey(province)) {
        weight = (provinceWeightData[province] as num).toDouble();
      }

// threshold 유효성 체크
      double percent;
      if (threshold <= 0) {
        print("⚠️ 임계치 값이 유효하지 않아 색상 계산을 건너뜁니다.");
        percent = 0.0;
      } else {
        percent = (weight / threshold).clamp(0.0, 1.0);
      }

// 색상 결정
      List<Color> color;
      if (threshold <= 0) {
        color = [Colors.grey, Colors.grey];
      } else {
        color = getGradientColorsByPercentage(percent);
      }

      print("$province weight: $weight and threshold: $threshold, so percent is $percent\n Color is ${color
              .toString()}");

      final BitmapDescriptor icon = await createCustomMarkerBitmap(
        province: province,
        label: "${weight.toInt()}",
        colorStart: color[0],
        colorEnd: color[1],
        percentage: percent,
      );

      Marker marker = Marker(
        markerId: MarkerId(province),
        position: latLng,
        icon: icon,
        onTap: () async {
          // 원하는 줌 레벨
          const double targetZoom = 8.0;

          // 카메라 이동 + 줌인
          await _controller?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: latLng,
                zoom: targetZoom,
              ),
            ),
          );
        },
      );

      markers.add(marker);
    }
    return markers;
  }


  List<Color> getGradientColorsByPercentage(double percent) {
    int r, g, b;

    if (percent <= 0.5) {
      final ratio = percent / 0.5;
      r = (0 + (249 - 0) * ratio).round();        // R: 0 → 249
      g = (208 + (217 - 208) * ratio).round();    // G: 208 → 217
      b = (98 + (51 - 98) * ratio).round();       // B: 98 → 51

      // 중심색
      final baseColor = Color.fromARGB(255, r, g, b);

      // 테두리색: 중심색보다 약간 밝음
      final lighterR = (r + 10).clamp(0, 255).toInt();
      final lighterG = (g + 10).clamp(0, 255).toInt();
      final lighterB = (b + 10).clamp(0, 255).toInt();

      return [
        baseColor,
        Color.fromARGB(255, lighterR, lighterG, lighterB),
      ];
    } else {
      final ratio = (percent - 0.5) / 0.5;
      r = (249 + (244 - 249) * ratio).round();    // R: 249 → 244
      g = (217 + (68 - 217) * ratio).round();     // G: 217 → 68
      b = (51 + (68 - 51) * ratio).round();       // B: 51 → 68

      final baseColor = Color.fromARGB(255, r, g, b);

      final lighterR = (r + 10).clamp(0, 255).toInt();
      final lighterG = (g + 10).clamp(0, 255).toInt();
      final lighterB = (b + 10).clamp(0, 255).toInt();

      return [
        baseColor,
        Color.fromARGB(255, lighterR, lighterG, lighterB),
      ];
    }
  }


  Future<Set<Marker>> _generateDistrictMarkers() async {
    Set<Marker> markers = {};
    for (var entry in allAreas.entries) {
      final province = entry.key;
      final districts = entry.value;


      for (var district in districts) {
        LatLng latLng = await getLatLngFromAddress(province, district);
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          continue;
        }


        Map<String, dynamic> provinceWeightData = await getWeightData(
            selectedType, selectedByproductName, province, district);

        double? weight;
        if (provinceWeightData.containsKey(district)) {
          weight = (provinceWeightData[district] as num).toDouble();
        } else if (provinceWeightData["total_weight"] != null) {
          weight = (provinceWeightData["total_weight"] as num).toDouble();
        }

        print("$province $district weight: $weight");

        final percent = (weight! / threshold).clamp(0.0, 1.0);


        List<Color> color = getGradientColorsByPercentage(percent);

        if (threshold <= 0) {
          print("⚠️ 임계치 값이 유효하지 않아 색상 계산을 건너뜁니다.");
          color[0] = Colors.grey;
          color[1] = Colors.grey;
        }

        print(
            "$province $district weight: $weight and threshold : $threshold, so percent is $percent\n Color is ${color
                .toString()}");

        final BitmapDescriptor icon = await createCustomMarkerBitmap(
          province: district,
          label: "${weight.toInt()}",
          colorStart: color[0],
          colorEnd: color[1],
          percentage: percent
        );


        Marker marker = Marker(
          markerId: MarkerId("$province $district"),
          position: latLng,
          icon: icon,
          onTap: () async {
            // 원하는 줌 레벨
            const double targetZoom = 10.0;

            // 카메라 이동 + 줌인
            await _controller?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: latLng,
                  zoom: targetZoom,
                ),
              ),
            );
          },
        );
        markers.add(marker);
      }
    }
    return markers;
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap({
    required String province,
    required String label,
    required Color colorStart,
    required Color colorEnd,
    required double percentage,
  }) async {
    // 마커 크기 범위
    const double minSize = 120;
    const double maxSize = 140;

    // 비율에 따라 크기 결정
    final double size = minSize + percentage * (maxSize - minSize);

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);


    final Offset center = Offset(size / 2, size / 2);
    final double radius = size / 2;

    final Paint backgroundPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          colorStart.withOpacity(1.0),    // 바깥 색
          colorEnd.withOpacity(1.0), // 중심 색
        ],
        [0.0, 1.0],
      );


    // 동그란 원 그리기
    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );


    final String shortProvince =
    province.length > 2 ? province.substring(0, 2) : province;

    // 폰트 크기
    final double baseFontSize = size / 4.2;
    final double provinceFontSize = shortProvince.length >= 5
        ? baseFontSize * 0.8
        : baseFontSize;

    // 텍스트
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      children: [
        TextSpan(
          text: "$shortProvince\n",
          style: TextStyle(
            fontSize: provinceFontSize,
            color: const Color(0xFFF2F2F2),
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        TextSpan(
          text: "$label",
          style: TextStyle(
            fontSize: baseFontSize,
            color: const Color(0xFFF2F2F2),
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size * 0.85,
    );

    // 중앙에 여백 확보
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + 4,
      ),
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
    /* UI 구현 */
    Widget _buildMapSection() {
      return GoogleMap(
        polygons: polygonService.getPolygons(),
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target : _center,
          zoom:7
        ),
        onMapCreated: (controller) async {
          _controller = controller;

          // map_style.json 읽어오기
          final String style = await DefaultAssetBundle.of(context)
              .loadString('assets/map_style.json');

          // 스타일 적용
          _controller?.setMapStyle(style);

          _drawZoomMarker(7);
        },

        onCameraIdle : () async {
          final position = await _controller?.getZoomLevel();
          _drawZoomMarker(position!);
        },
        markers: currentMarkers,
        zoomControlsEnabled: true,
      );
    }




  void _drawZoomMarker(double zoom) {
    setState(() {
      if (zoom <= 7) {
        currentMarkers = _provinceMarkers;
      } else {
        currentMarkers = _districtMarkers;
      }
    });
  }



    int selectedIndex = 0;
    Future<void> _onItemTapped(BuildContext context, int index) async {
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
      }
    }



  Future<void> _reloadMarkers() async {
    _provinceMarkers = await _generateProvinceMarkers();
    _districtMarkers = await _generateDistrictMarkers();

    // 현재 줌에 맞춰 지도에 새 마커 뿌리기
    final position = await _controller?.getZoomLevel();
    if (position != null) {
      _drawZoomMarker(position);
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




  // 실행
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
