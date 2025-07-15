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
/// refactoring ver 2.0 (예정)  - 1. 줌인할 때 범위에 해당하는 마커만 먼저 그리기 2. 5분분마다 자동으로 화면 갱신하기

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

  Future<void> initData() async {
    final totalStopwatch = Stopwatch()..start();
    print('⚡ initData 시작');

    // 1. 지역 데이터 로드
    final sw1 = Stopwatch()..start();
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

    // 4. 마커 생성
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

    // 초기 마커 표시
    currentMarkers = _provinceMarkers;

    setState(() {
      isLoading = false;
    });

    totalStopwatch.stop();
    print('🎉 initData 총 소요 시간: ${totalStopwatch.elapsedMilliseconds} ms');
  }




  Future<void> _reloadMarkers() async {
    // 새로 마커 생성
    final sw = Stopwatch()..start();
    print('🔄 _reloadMarkers 시작');

    final swGen = Stopwatch()..start();
    final allMarkers = await markerHelper.generateAllMarkers(
      allAreas: allAreas,
      selectedType: selectedType,
      selectedByproductName: selectedByproductName,
      threshold: threshold!,
      provinceOnTap: _onProvinceMarkerTap,
      districtOnTap: _onDistrictMarkerTap,
      adminData: adminData,
    );
    swGen.stop();
    print('✅ generateAllMarkers 완료: ${swGen.elapsedMilliseconds} ms');

    // 현재 줌 레벨
    final swZoom = Stopwatch()..start();
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    swZoom.stop();
    print('✅ getZoomLevel 완료: ${swZoom.elapsedMilliseconds} ms');

    setState(() {
      _provinceMarkers = allMarkers.provinceMarkers;
      _districtMarkers = allMarkers.districtMarkers;
      currentMarkers = zoom <= 7
          ? _provinceMarkers
          : _districtMarkers;
    });

    sw.stop();
    print('🎉 _reloadMarkers 총 소요 시간: ${sw.elapsedMilliseconds} ms');
  }


  int selectedIndex = 0;
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
        await _reloadMarkers();
      }
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

        _drawZoomMarker(zoom);             // 최적화 (불필요 setState 방지)
        await lazyLoadDistrictMarker(zoom); // 필요 시 lazy load
      },

      markers: currentMarkers,
      zoomControlsEnabled: true,
    );
  }

  //로드는 처음부터 받아두는건 어떨까

  Future<void> lazyLoadDistrictMarker(double zoom) async {
    if (zoom <= 7) return;

    final totalSw = Stopwatch()..start();
    print('🔄 lazyLoadDistrictMarker START');

    // 1. bounds 얻기
    final swBounds = Stopwatch()..start();
    final bounds = await _controller!.getVisibleRegion();
    swBounds.stop();
    print('✅ getVisibleRegion: ${swBounds.elapsedMilliseconds} ms');

    // 2. 화면에 보이는 구 필터링
    final swFilter = Stopwatch()..start();
    final visibleDistricts = <String, List<String>>{};

    for (final entry in allAreas.entries) {
      final province = entry.key;
      for (final district in entry.value) {
        final LatLng pos = await getLatLngFromAddress(province, district);
        if (_latLngInBounds(pos, bounds)) {
          visibleDistricts.putIfAbsent(province, () => []).add(district);
        }
      }
    }
    swFilter.stop();
    print('✅ filter visibleDistricts: ${swFilter.elapsedMilliseconds} ms (총 ${visibleDistricts.length}개 province)');

    // 3. 마커 생성
    final swGenerate = Stopwatch()..start();
    final newMarkers = <Marker>{};

    for (final entry in visibleDistricts.entries) {
      final province = entry.key;
      final districts = entry.value;

      // weight 한번만 가져오기
      final swWeight = Stopwatch()..start();
      final districtWeightData = await adminData.getWeightData(
        selectedType,
        selectedByproductName,
        province,
        null,
      );
      swWeight.stop();
      print('✅ getWeightData($province): ${swWeight.elapsedMilliseconds} ms');

      // 개별 district 처리
      for (final district in districts) {
        final markerId = MarkerId("$province $district");
        if (!_districtMarkers.any((m) => m.markerId == markerId)) {
          final swMarker = Stopwatch()..start();

          final generated = await markerHelper.generateDistrictMarkers(
            province: province,
            districtWeightData: districtWeightData,
            threshold: threshold!,
            onTap: _onDistrictMarkerTap,
          );

          newMarkers.addAll(generated);

          swMarker.stop();
          print('✅ generateDistrictMarkers($province-$district): ${swMarker.elapsedMilliseconds} ms');
        }
      }
    }

    swGenerate.stop();
    print('✅ 마커 생성 총 시간: ${swGenerate.elapsedMilliseconds} ms (마커 ${newMarkers.length}개)');

    // 4. SetState
    if (newMarkers.isNotEmpty) {
      setState(() {
        _districtMarkers.addAll(newMarkers);
        if (zoom > 7) {
          currentMarkers = {..._provinceMarkers, ..._districtMarkers};
        }
      });
    }

    totalSw.stop();
    print('🎉 lazyLoadDistrictMarker TOTAL: ${totalSw.elapsedMilliseconds} ms');
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


  double? _lastZoomLevel;
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
              await _reloadMarkers();
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

              await _reloadMarkers();
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
