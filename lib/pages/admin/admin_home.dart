import 'package:brownskin_app/model/polygon_data.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';

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
  ///refactoring ver 3.0(예정) : 업체가 줄어들어 마커가 삭제되어야하는 케이스, 5분마다 데이터 자동 갱신 (or 새로고침 버튼 도입?)

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
  final Set<Marker> _districtMarkers = {}; //관리자가 가진 모든 구 정보
  Set<Marker> currentMarkers = {}; //현재 지도에 띄울 마커
  GoogleMapController? _controller;
  final LatLng _center = const LatLng(36.5,127.8); //지도를 켰을 때 중심 좌표

  late final polygonService; // 지역별 경계선
  late final adminData;
  late final markerHelper;


  double? total_weight = 0; //전국 무게량
  int selectedIndex = 0;


//마커 절반 먼저 그리고 ,
  late final Future<void> Function(LatLng) _onProvinceMarkerTap = (LatLng latLng) async {
    const targetZoom = 10.0;
    await _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: targetZoom)));
  };

  late final Future<void> Function(LatLng) _onDistrictMarkerTap = (LatLng latLng) async {
    const targetZoom = 12.0;
    await _controller?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: targetZoom)));
  };


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this,);

    _chartAnimationController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this,);

    markerHelper = AdminMarker(token: widget.token);
    adminData = AdminData(token: widget.token);
    polygonService = PolygonService();
    initData();
    polygonService.createPolygonsFromConsts().then((_) {setState(() {});});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  /// AllAreas, Province마커 생성을 완료하고, district preload를 해둔다
  Future<void> initData() async {
    threshold = await adminData.getThreshold(selectedType, selectedByproductName);

    final provinceWeightData = await adminData.getWeightData(
        selectedType, selectedByproductName, null, null);

    _provinceMarkers = await markerHelper.generateProvinceMarkers(
      provinceWeights: provinceWeightData,
      threshold: threshold!,
      onTap: _onProvinceMarkerTap,
    );
    total_weight = adminData.lastTotalWeight;

    // UI 반영
    setState(() {
      currentMarkers = _provinceMarkers;
      isLoading = false;
    });

//병목의 원인 -> shared 사용해볼것
    allAreas = await adminData.updateRegionData();

    // 비동기 처리
    WidgetsBinding.instance.addPostFrameCallback((_) {
      preloadAllDistrictLatLng().then((_) async {
        final stream = markerHelper.graduallyDistrictMarkers(
          selectedType: selectedType,
          selectedByproductName: selectedByproductName,
          threshold: threshold!,
          onTap: _onDistrictMarkerTap,
          adminData: adminData,
        );

        await for (final marker in stream) {
          _districtMarkers.add(marker);
        }
      });
    });


    //비동기 함수 사용시 mount 사용하라는데 ? 조사해보고 코드 추가할 것
  }



  Future<void> lazyLoadDistrictMarker(double zoom) async {
    if (zoom <= 7) return;

    final bounds = await _controller!.getVisibleRegion();
    final visibleDistricts = <MapEntry<String, String>>[];

    for (final entry in allAreas.entries) {
      final province = entry.key;
      for (final district in entry.value) {
        final LatLng? pos = await getLatLngFromAddress(province, district); /// 개선점 - 중복 api 호출 해결
        if (pos == null) continue;

        if (_latLngInBounds(pos, bounds))
          visibleDistricts.add(MapEntry(province, district));
      }
    }

    if (visibleDistricts.isEmpty) return;

    // 3. weight data province별로 미리 조회
    final Map<String, Map<String, dynamic>> provinceWeightDataMap = {};

    for (final province in visibleDistricts.map((e) => e.key).toSet()) {
      var data = await adminData.getWeightData( selectedType, selectedByproductName, province, null,);
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

      if (markers.isEmpty)  continue;
      for (final newMarker in markers) {
        _districtMarkers.removeWhere((m) => m.markerId == newMarker.markerId);
        _districtMarkers.add(newMarker);
      }
    }
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
    // weight 데이터 로드
    final provinceWeightData = await adminData.getWeightData(selectedType, selectedByproductName, null, null,
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
  }


  Future<void> reloadDistrictMarkers() async {
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    await lazyLoadDistrictMarker(zoom); // 필요 시 lazy load

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
        _districtMarkers.removeWhere((m) => m.markerId == marker.markerId);
        _districtMarkers.add(marker);
      }
    }));
  }


  Future<void> reloadMarkers() async {
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    setState(() { isLoading = true;});

    if (zoom <= 7) {
      await reloadProvinceMarkers();
      reloadDistrictMarkers(); //race condition 고려해야함
    } else {
      await reloadDistrictMarkers();
      reloadProvinceMarkers(); //race condition 고려해야함
    }

    setState(() {
      isLoading = false;
      _drawZoomMarker(zoom);
    });
  }


  Future<void> _onItemTapped(BuildContext context, int index) async {
      setState(() {
        selectedIndex = index;
      });

      if (index == 0) return; // 홈
      else if (index == 1) {// 임계 설정
        final result = await Navigator.push<int>(context, MaterialPageRoute(builder: (context) => SetThresholdAdminPage(token: widget.token)));

        if (result == null) {// 복귀했을 때 result 없으면 홈으로
          setState(() {selectedIndex = 0;});
          return;
        }
        setState(() {selectedIndex = result;});
        threshold = await adminData.getThreshold(selectedType, selectedByproductName);
        await reloadMarkers();
      }
    }



  void _drawZoomMarker(double zoom) {
      setState(() {
        currentMarkers = zoom <= 7 ? _provinceMarkers : _districtMarkers;
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

        final String style = await DefaultAssetBundle.of(context).loadString('assets/map_style.json');
        await _controller?.setMapStyle(style);
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
