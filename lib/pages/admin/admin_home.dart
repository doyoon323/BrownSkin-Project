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
  final LatLng _center = const LatLng(36.5,127.8); //지도를 켰을 때 중심 좌표

  final polygonService = PolygonService(); // 지역별 경계선
  late final adminData = AdminData(token: widget.token);
  late final markerHelper;


  double? total_weight; //전국 무게량
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
    //print('⚡ initData 시작');

    // 1. 지역 데이터 로드
    final sw1 = Stopwatch()..start();

    //DB에서 시도 목록을 받아온다.
    allAreas = await adminData.updateRegionData();
    sw1.stop();
    //print('✅ updateRegionData 완료: ${sw1.elapsedMilliseconds} ms');


    // 2. 임계값 로드
    final sw2 = Stopwatch()..start();
    threshold = await adminData.getThreshold(selectedType, selectedByproductName);
    sw2.stop();
    //print('✅ getThreshold 완료: ${sw2.elapsedMilliseconds} ms');

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

    total_weight = adminData.lastTotalWeight; //초기 총량

    _provinceMarkers = await markerHelper.generateProvinceMarkers(
      provinceWeights: provinceWeightData,
      threshold: threshold!,
      onTap: _onProvinceMarkerTap,
    );

    sw3.stop();
    //print('✅ generateProvinceMarkers 완료: ${sw3.elapsedMilliseconds} ms');

    // 6. UI 표시
    setState(() {
      currentMarkers = _provinceMarkers;
      isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 5. 구별 좌표 preload 비동기로 시작
      preloadAllDistrictLatLng().then((_) async {
        final stream = markerHelper.updateDistrictMarkers(
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
    //print('🎉 initData 총 소요 시간: ${totalStopwatch.elapsedMilliseconds} ms');
  }



  Future<void> lazyLoadDistrictMarker(double zoom) async {
    ////print("[LazyLoad] lazyLoadDistrictMarker() started with zoom=$zoom");
    if (zoom <= 7) return; //province 마커를 보이는 경우

    final totalSw = Stopwatch()..start();

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


    if (visibleDistricts.isEmpty) {
      ////print("[LazyLoad] No visible districts to load.");
    }

    // 3. weight data province별로 미리 조회
    final Map<String, Map<String, dynamic>> provinceWeightDataMap = {};

    for (final province in visibleDistricts.map((e) => e.key).toSet()) {
      var data = await adminData.getWeightData( //갱신된 데이터
        selectedType,
        selectedByproductName,
        province,
        null,
      );
      //print("😍 getWeight of $province: $data");
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
        onTap: _onDistrictMarkerTap,
      );

      if (markers.isNotEmpty) {
        _districtMarkers.addAll(markers);
      }
    }
    totalSw.stop();
    //print('🎉 lazyLoadDistrictMarker 완료 (${totalSw.elapsedMilliseconds} ms)');
    ////print("[Debug] Province markers=${_provinceMarkers.length}, District markers=${_districtMarkers.length}");

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
    ////print("[Reload] reloadProvinceMarkers() started");

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
    _provinceMarkers = markers;
    total_weight = adminData.lastTotalWeight;
    ////print("[Debug] Province markers=${_provinceMarkers.length}, District markers=${_districtMarkers.length}");
    ////print("[Reload] reloadProvinceMarkers() completed. Province markers count=${_provinceMarkers.length}");

    sw.stop();
  }


  Future<void> reloadDistrictMarkers() async {
    ////print("[Reload] reloadDistrictMarkers() started");
    final sw = Stopwatch()..start();

    //화면에 보이는 것 우선 반영
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    await lazyLoadDistrictMarker(zoom); // 필요 시 lazy load
    ////print("[Reload] lazyLoadDistrictMarker() completed");

    ////print("[Debug] Province markers=${_provinceMarkers.length}, District markers=${_districtMarkers.length}");

    /*
    //남은 district all 로드하되, 필요한 것 중 이미 생성한 건  안 그려도 된다.
    unawaited(Future(() async {
      final stream = markerHelper.updateDistrictMarkers(
        selectedType: selectedType,
        selectedByproductName: selectedByproductName,
        threshold: threshold!,
        existingMarkers: _districtMarkers,
        onTap: _onDistrictMarkerTap,
        adminData: adminData,
      );

      await for (final marker in stream) {
        // 새 마커만 district에 추가
        _districtMarkers.removeWhere((m) => m.markerId == marker.markerId);
        _districtMarkers.add(marker);
        ////print("[Reload] Added/Updated marker ${marker.markerId.value}");

      }

      setState(() {
        currentMarkers = (zoom <= 7)
            ? _provinceMarkers
            : _districtMarkers;
      });
      ////print("[Reload] reloadDistrictMarkers() completed. District markers count=${_districtMarkers.length}");
    }));

     */

    sw.stop();
    //print('✅ reloadDistrictMarkers 완료 (${sw.elapsedMilliseconds} ms)');
  }


  Future<void> reloadMarkers() async {
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    ////print("[Reload] Start reloadMarkers() zoom=$zoom");


    setState(() {
      isLoading = true;
    });

    if (zoom <= 7) {
      await reloadProvinceMarkers();

      setState(() {
        _drawZoomMarker(zoom);
        isLoading = false;
      });

      /*
      //백그라운드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 5. 구별 좌표 preload 비동기로 시작
      preloadAllDistrictLatLng().then((_) async {
        final stream = markerHelper.updateDistrictMarkers(
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
       */
    } else {
      await reloadDistrictMarkers();
      await reloadProvinceMarkers();

      setState(() {
        _drawZoomMarker(zoom);
        isLoading = false;
      });
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
        await reloadMarkers();
      }
    }



  void _drawZoomMarker(double zoom) {
    //////print("[Zoom] _drawZoomMarker() currentZoom=$zoom _lastZoomLevel=$_lastZoomLevel");
      setState(() {
        currentMarkers = zoom <= 7 ? _provinceMarkers : _districtMarkers;
        //////print("[Zoom] Switched currentMarkers to ${zoom <= 7 ? "province" : "district"} markers");
      });
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















// 개선된 Filter Bar
  Widget _buildFilterBar() {
    final filteredByproducts = byproductsCategory
        .where((item) => item["type"] == selectedType)
        .map((item) => item["name"]!)
        .toSet()
        .toList();

    return Container(
      margin: const EdgeInsets.only(top:4,left: 16, right: 16),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(7), // 기존 16 → 12로 줄이기
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // 가공/수확 토글 버튼 (개선된 디자인)
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              "가공",
                              selectedType == "가공",
                                  () async => await _onTypeChanged("가공"),
                            ),
                          ),
                          Expanded(
                            child: _buildToggleButton(
                              "수확",
                              selectedType == "수확",
                                  () async => await _onTypeChanged("수확"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 드롭다운 (개선된 디자인)
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedByproductName,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade600),
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          items: filteredByproducts.map((name) {
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value == null) return;
                            final newThreshold = await adminData.getThreshold(selectedType, value);
                            setState(() {
                              selectedByproductName = value;
                              threshold = newThreshold;
                            });
                            await reloadMarkers();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// 토글 버튼 위젯
  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.green.shade600.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

// 타입 변경 헬퍼 메서드
  Future<void> _onTypeChanged(String newType) async {
    final filtered = byproductsCategory
        .where((item) => item["type"] == newType)
        .map((item) => item["name"]!)
        .toSet()
        .toList();
    final newByproduct = filtered.isNotEmpty ? filtered.first : null;
    final newThreshold = await adminData.getThreshold(newType, newByproduct);

    setState(() {
      selectedType = newType;
      selectedByproductName = newByproduct;
      threshold = newThreshold;
    });

    await reloadMarkers();
  }

// 개선된 Summary Cards
  Widget _buildSummaryCards() {
    final double disposalRate = 15.2;
    final double recyclingRate = 84.8;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 75,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSummaryCard(
            title: "총 무게량",
            value: "${total_weight?.toStringAsFixed(1)}",
            unit: "kt",
            icon: Icons.scale_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5),Color(0xFF1E88E5),],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            percentage: null,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: "폐기율",
            value: disposalRate.toStringAsFixed(1),
            unit: "%",
            icon: Icons.delete_outline_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFFF23920), Color(0xFFEB4231)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            percentage: disposalRate / 100,
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            title: "자원순환율",
            value: recyclingRate.toStringAsFixed(1),
            unit: "%",
            icon: Icons.recycling_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF32D957), Color(0xFF28B44B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            percentage: recyclingRate / 100,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required LinearGradient gradient,
    double? percentage,
  }) {
    return Container(
      width: 120,
      height: 30, // 높이 살짝 줄임 (원하면 조절 가능)
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // 값
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 퍼센트 원형 바 (오른쪽 하단)
                    if (percentage != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 2,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      body: SafeArea( // 🔹 반드시 SafeArea로 감싸기
        child: Stack(
          children: [
            _buildMapSection(),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                  child: Center(child: _buildLoadingWidget()),
                ),
              ),

            // 🔻 AppBar 대신 필터바가 상단 차지
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFilterBar(),
            ),

            // 🔻 SummaryCard 위치도 조정
            Positioned(
              top: 85, // 기존 140 → 필터 바 높이 고려해서 늘림
              left: 0,
              right: 0,
              child: _buildSummaryCards(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }

// 개선된 로딩 위젯
  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '데이터를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '잠시만 기다려주세요',
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
}
