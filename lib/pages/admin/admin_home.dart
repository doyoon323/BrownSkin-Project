import 'package:brownskin_app/model/polygon_data.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';
import 'dart:ui' as ui;

import 'dart:async';
import 'package:brownskin_app/pages/admin/setThreshold_admin.dart';
import 'package:brownskin_app/pages/admin/global.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
/// refactoring ver 1.0 기능 분리
/// refactoring ver 2.0 (예정)  - 1. 줌인할 때 범위에 해당하는 마커만 먼저 그리기 2. 15분~30분마다 자동으로 화면 갱신하기 3.

  // dropdown 저장용 변수
  String selectedType = "수확"; // default = 수확
  String? selectedByproductName = "사과"; // default = 사과


  double? threshold; //default


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
  late final adminData = AdminData(token: widget.token);

  late final markerHelper;


  late final Future<void> Function(LatLng) _onProvinceMarkerTap = (LatLng latLng) async {
    const targetZoom = 8.0;
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: targetZoom),
      ),
    );
  };

  late final Future<void> Function(LatLng) _onDistrictMarkerTap = (LatLng latLng) async {
    const targetZoom = 10.0;
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
    // 1. 지역 데이터 로드
    allAreas = await adminData.updateRegionData();

    // 2. 임계값 로드
    threshold = await adminData.getThreshold(selectedType, selectedByproductName);

    // 3. Marker Helper 생성
    markerHelper = AdminMarker(token: widget.token);

    final allMarkers = await markerHelper.generateAllMarkers(
      allAreas: allAreas,
      selectedType: selectedType,
      selectedByproductName: selectedByproductName,
      threshold: threshold!,
      provinceOnTap: _onProvinceMarkerTap,
      districtOnTap: _onDistrictMarkerTap,
      adminData: adminData,
    );

    setState(() {
      _provinceMarkers = allMarkers.provinceMarkers;
      _districtMarkers = allMarkers.districtMarkers;
    });

    // 6. 초기 마커 표시
    currentMarkers = _provinceMarkers;

    // 7. 로딩 종료
    setState(() {
      isLoading = false;
    });
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


  Future<void> _reloadMarkers() async {
    // 새로 마커 생성
    final allMarkers = await markerHelper.generateAllMarkers(
      allAreas: allAreas,
      selectedType: selectedType,
      selectedByproductName: selectedByproductName,
      threshold: threshold!,
      provinceOnTap: _onProvinceMarkerTap,
      districtOnTap: _onDistrictMarkerTap,
      adminData: adminData,
    );

    // 현재 줌 레벨
    final zoom = await _controller?.getZoomLevel() ?? 7.0;

    setState(() {
      _provinceMarkers = allMarkers.provinceMarkers;
      _districtMarkers = allMarkers.districtMarkers;
      // ✅ 현재 마커 즉시 갱신
      currentMarkers = zoom <= 7
          ? _provinceMarkers
          : _districtMarkers;
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
        threshold = await adminData.getThreshold(selectedType, selectedByproductName);
        await _reloadMarkers();
      }
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
