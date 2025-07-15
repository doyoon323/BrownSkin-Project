import 'package:brownskin_app/model/polygon_data.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';
import 'dart:ui' as ui;

import 'dart:async';
import 'package:brownskin_app/pages/admin/setThreshold_admin.dart';
import 'package:brownskin_app/pages/admin/global.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../service/location_service.dart';
import 'admin_data_provider.dart';
import 'admin_marker_factory.dart';


/// 관리자 기본 화면 (부산물 데이터 시각화 with google maps)
class AdminHomePage extends StatefulWidget {
  final String token;
  const AdminHomePage({required this.token, super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with TickerProviderStateMixin {
/// refactoring ver 2.0   - 1. 줌인할 때 범위에 해당하는 마커만 먼저 그리기 2. 5분분마다 자동으로 화면 갱신하기

  ///refactoring ver 3.0(예정) : 업체가 줄어들어 마커가 삭제되어야하는 케이스

  // dropdown 저장용 변수
  String selectedType = "수확"; // default = 수확
  String? selectedByproductName = "사과"; // default = 사과



  //UI 구성
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  double? threshold;


  //Maps
  Set<Marker> _provinceMarkers = {}; //관리자가 가진 모든 시도 정보
  Set<Marker> _districtMarkers = {}; //관리자가 가진 모든 구 정보
  Set<Marker> currentMarkers = {}; //현재 지도에 띄울 마커
  GoogleMapController? _controller;
  final LatLng _center = const LatLng(35.5,127.8); //지도를 켰을 때 중심 좌표

  final polygonService = PolygonService(); // 지역별 경계선
  late final adminData = AdminData(token: widget.token);
  late final markerHelper;


  double? _lastZoomLevel;
  int selectedIndex = 0;


//마커 절반 먼저 그리고 ,
  late final Future<void> Function(LatLng) _onProvinceMarkerTap = (LatLng latLng) async {
    const targetZoom = 10.0;
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: targetZoom),
      ),
    );
  };

  late final Future<void> Function(LatLng) _onDistrictMarkerTap = (LatLng latLng) async {
    const targetZoom = 12.0;
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: targetZoom),
      ),
    );
  };


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

  /// AllAreas, Province마커 생성을 완료하고, district preload를 해둔다
  Future<void> initData() async {
    final totalStopwatch = Stopwatch()..start();
    print('⚡ initData 시작');

    // 1. 지역 데이터 로드
    final sw1 = Stopwatch()..start();

    //DB에서 시도 목록을 받아온다.
    allAreas = await adminData.updateRegionData();
    sw1.stop();
    print('✅ updateRegionData 완료: ${sw1.elapsedMilliseconds} ms');


    // 2. 임계값 로드
    final sw2 = Stopwatch()..start();
    threshold = await adminData.getThreshold(selectedType, selectedByproductName);
    sw2.stop();
    print('✅ getThreshold 완료: ${sw2.elapsedMilliseconds} ms');

    // 3. Marker Helper 생성
    markerHelper = AdminMarker(token: widget.token);

    // 4. 도별 마커 생성
    final sw3 = Stopwatch()..start();

    final provinceWeightData = await adminData.getWeightData(
      selectedType,
      selectedByproductName,
      null,
      null,
    );

    _provinceMarkers = await markerHelper.generateProvinceMarkers(
      provinceWeights: provinceWeightData,
      threshold: threshold!,
      onTap: _onProvinceMarkerTap,
    );

    sw3.stop();
    print('✅ generateProvinceMarkers 완료: ${sw3.elapsedMilliseconds} ms');

    // 6. UI 표시
    setState(() {
      currentMarkers = _provinceMarkers;
      isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 5. 구별 좌표 preload 비동기로 시작
      preloadAllDistrictLatLng().then((_) async {
        final stream = markerHelper.initDistrictMarkers(
          selectedType: selectedType,
          selectedByproductName: selectedByproductName,
          threshold: threshold!,
          existingMarkers: _districtMarkers,
          onTap: _onDistrictMarkerTap,
          adminData: adminData,
        );

        await for (final marker in stream) {
          _districtMarkers.removeWhere((m) => m.markerId == marker.markerId);
          _districtMarkers.add(marker);
        }
      });
    });

    totalStopwatch.stop();
    print('🎉 initData 총 소요 시간: ${totalStopwatch.elapsedMilliseconds} ms');
  }



  Future<void> lazyLoadDistrictMarker(double zoom) async {
    if (zoom <= 9) return; //province 마커를 보이는 경우

    final totalSw = Stopwatch()..start();
    print('🔄 lazyLoadDistrictMarker START');

    final bounds = await _controller!.getVisibleRegion();
    final visibleDistricts = <MapEntry<String, String>>[];

    for (final entry in allAreas.entries) {
      final province = entry.key;
      for (final district in entry.value) {
        final LatLng pos = await getLatLngFromAddress(province, district); /// 개선점 - 중복 api 호출 해결

        if (_latLngInBounds(pos, bounds)) {
          visibleDistricts.add(MapEntry(province, district));
        }
      }
    }

    print('✅ 보이는 구 : ${visibleDistricts}');
    print('✅ 보이는 구 개수: ${visibleDistricts.length}');

    // 3. weight data province별로 미리 조회
    final Map<String, Map<String, dynamic>> provinceWeightDataMap = {};

    for (final province in visibleDistricts.map((e) => e.key).toSet()) {
      final data = await adminData.getWeightData( //갱신된 데이터
        selectedType,
        selectedByproductName,
        province,
        null,
      );
      provinceWeightDataMap[province] = data;
    }

    // 4. 마커 생성
    for (final entry in visibleDistricts) {
      final province = entry.key;
      final district = entry.value;

      final Set<Marker> markers = await markerHelper.generateSpecificDistrictMarkers(
        province: province,
        districts: [district], // 화면에 보이는 district만
        districtWeightData: provinceWeightDataMap[province]!,
        threshold: threshold!,
        existingMarkers: _districtMarkers,
        onTap: _onDistrictMarkerTap,
      );

      if (markers.isNotEmpty) {
        _districtMarkers.addAll(markers);
      }
    }
    totalSw.stop();
    print('🎉 lazyLoadDistrictMarker 완료 (${totalSw.elapsedMilliseconds} ms)');
  }

  bool _latLngInBounds(LatLng point, LatLngBounds bounds) {
    final lat = point.latitude;
    final lng = point.longitude;

    // 북서/남동 좌표
    final southWest = bounds.southwest;
    final northEast = bounds.northeast;

    return lat >= southWest.latitude &&
        lat <= northEast.latitude &&
        lng >= southWest.longitude &&
        lng <= northEast.longitude;
  }


  Future<void> reloadProvinceMarkers() async {
    print('🔄 reloadProvinceMarkers 시작');
    setState(() {
      isLoading = true;
    });

    final sw = Stopwatch()..start();

    // weight 데이터 로드
    final provinceWeightData = await adminData.getWeightData(
      selectedType,
      selectedByproductName,
      null,
      null,
    );

    // 2. 시도 마커 새로 생성
    final markers = await markerHelper.generateProvinceMarkers(
      provinceWeights: provinceWeightData,
      threshold: threshold!,
      onTap: _onProvinceMarkerTap,
    );

    // 3. 교체
    setState(() {
      _provinceMarkers = markers;
      currentMarkers = _provinceMarkers;
      isLoading = false;
    });

    sw.stop();
  }

  Future<void> reloadDistrictMarkers() async {
    print('🔄 reloadDistrictMarkers 시작');
    final sw = Stopwatch()..start();

    final Set<Marker> allDistrictMarkers = {};

    for (final province in allAreas.keys) {
      // weight 데이터
      final districtWeightData = await adminData.getWeightData(
        selectedType,
        selectedByproductName,
        province,
        null,
      );


      final markers = await markerHelper.generateDistrictMarkers(
        province: province,
        districtWeightData: districtWeightData,
        threshold: threshold!,
        existingMarkers: const {}, // 전체 재생성
        onTap: _onDistrictMarkerTap,
      );

      allDistrictMarkers.addAll(markers);
    }

    setState(() {
      _districtMarkers = allDistrictMarkers;
      currentMarkers = (_lastZoomLevel != null && _lastZoomLevel! > 7)
          ? {..._provinceMarkers, ..._districtMarkers}
          : _provinceMarkers;
    });

    sw.stop();
    print('✅ reloadDistrictMarkers 완료 (${sw.elapsedMilliseconds} ms)');
  }


  Future<void> reloadMarkers() async {
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    if (zoom <= 9) {
      await reloadProvinceMarkers();
      //백그라운드
      unawaited(Future(() async {
        final stream = markerHelper.updateDistrictMarkers(
          selectedType: selectedType,
          selectedByproductName: selectedByproductName,
          threshold: threshold!,
          existingMarkers: _districtMarkers,
          onTap: _onDistrictMarkerTap,
          adminData: adminData,
        );

        final updated = <Marker>{};
        await for (final marker in stream) {
          updated.add(marker);
        }
        setState(() {
          _districtMarkers = updated;
        });
      }));
    } else {
      await reloadDistrictMarkers();
      await reloadProvinceMarkers();
    }
  }


  Future<void> _onItemTapped(BuildContext context, int index) async {
      setState(() {
        selectedIndex = index;
      });
      // 홈
      if (index == 0) {
        return;
      }
      // 임계 설정
      else if (index == 1) {
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
        threshold = await adminData.getThreshold(selectedType, selectedByproductName);
        await reloadProvinceMarkers();
        await reloadDistrictMarkers();
      }
    }



  void _drawZoomMarker(double zoom) {
    if (_lastZoomLevel == null ||
        (zoom <= 7 && _lastZoomLevel! > 7) ||
        (zoom > 7 && _lastZoomLevel! <= 7)) {
      setState(() {
        currentMarkers = zoom <= 7 ? _provinceMarkers : _districtMarkers;
      });
    }
    _lastZoomLevel = zoom;
  }





  Widget _buildMapSection() {
    return GoogleMap(
      polygons: polygonService.getPolygons(),
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 7,
      ),
      onMapCreated: (controller) async {
        _controller = controller;
        final String style = await DefaultAssetBundle.of(context)
            .loadString('assets/map_style.json');
        _controller?.setMapStyle(style);
        _drawZoomMarker(7);
      },

      onCameraIdle: () async {
        final zoom = await _controller?.getZoomLevel() ?? 7.0;
        await lazyLoadDistrictMarker(zoom); // 필요 시 lazy load
        _drawZoomMarker(zoom);
      },

      markers: currentMarkers,
      zoomControlsEnabled: true,
    );
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
              final newType = index == 0 ? "가공" : "수확";
              final filtered = byproductsCategory
                  .where((item) => item["type"] == newType)
                  .map((item) => item["name"]!)
                  .toSet()
                  .toList();
              final newByproduct = filtered.isNotEmpty ? filtered.first : null;

              // threshold 먼저 받아오기
              final newThreshold = await adminData.getThreshold(newType, newByproduct);

              setState(() {
                selectedType = newType;
                selectedByproductName = newByproduct;
                threshold = newThreshold;
              });

              // 마커 새로 생성
              await reloadProvinceMarkers();
              await reloadDistrictMarkers();
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
              if (value == null) return;

              // threshold 먼저 받아오기
              final newThreshold = await adminData.getThreshold(selectedType, value);

              setState(() {
                selectedByproductName = value;
                threshold = newThreshold;
              });

              await reloadProvinceMarkers();
              await reloadDistrictMarkers();
            },
          ),
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
        body: Stack(
          children: [
            _buildMapSection(),

            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

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
