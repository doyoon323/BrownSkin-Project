import 'package:brownskin_app/model/polygon_data.dart';
import 'package:brownskin_app/pages/admin/tester.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/common/constants.dart';
import 'dart:async';
import 'package:brownskin_app/pages/admin/setThreshold_admin.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../common/location_service.dart';
import '../../common/widgets.dart';
import 'admin_data_provider.dart';
import 'admin_marker_factory.dart';



class AdminHomePage extends StatefulWidget {
  final String token;
  const AdminHomePage({required this.token, super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with TickerProviderStateMixin {
  // dropdown
  String selectedType = "수확"; // default = 수확
  String? selectedByproductName = "사과"; // default = 사과

  //UI
  bool isLoading = true;
  double? threshold;

  //Maps
  Set<Marker> _provinceMarkers = {};
  Set<Marker> _districtMarkers = {};
  Set<Marker> currentMarkers = {};
  GoogleMapController? _controller;

  late final PolygonService polygonService;
  late final AdminData adminData;
  late final AdminMarker markerHelper;

  double? total_weight;
  int selectedIndex = 0;

  //race condition flag
  bool _isReloadingDistrict = false;

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
    markerHelper = AdminMarker(token: widget.token);
    adminData = AdminData(token: widget.token);
    polygonService = PolygonService();

    initData();
    polygonService.createPolygonsFromConsts().then((_) => setState(() {}));
  }


  Future<void> initData() async {
    threshold = await adminData.getThreshold(selectedType, selectedByproductName);
    final provinceWeightData = await adminData.getWeightData(selectedType, selectedByproductName, null, null);
    _provinceMarkers = await markerHelper.generateProvinceMarkers(provinceWeightData, threshold!, _onProvinceMarkerTap,);
    total_weight = adminData.lastTotalWeight ?? 0.0 ;

    setState(() {
      currentMarkers = _provinceMarkers;
      isLoading = false;
    });

    allAreas = await adminData.updateRegionData();
    _startDistrictPreloadStream();
  }

  void _startDistrictPreloadStream() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      preloadAllDistrictLatLng().then((_) async {
        if (!mounted) return;
        final stream = markerHelper.graduallyDistrictMarkers(
          selectedType, selectedByproductName, threshold!,
          _onDistrictMarkerTap, adminData,
        );
        await for (final marker in stream) {
          if (!mounted) break;
          _districtMarkers.removeWhere((m) => m.markerId == marker.markerId);
          _districtMarkers.add(marker);
        }
      });
    });
  }

  Future<void> lazyLoadDistrictMarker(double zoom) async {
    if (zoom <= 7) return;

    final bounds = await _controller!.getVisibleRegion();
    final visibleDistricts = await _getVisibleDistricts(bounds);
    if (visibleDistricts.isEmpty) return;

    final provinceWeightDataMap = await _getProvinceWeightData(visibleDistricts);
    await _generateDistrictMarkers(visibleDistricts, provinceWeightDataMap);
  }


  Future<List<MapEntry<String, String>>> _getVisibleDistricts(LatLngBounds bounds) async {
    final entries = <MapEntry<String, String>>[
      for (final entry in allAreas.entries)
        for (final district in entry.value) MapEntry(entry.key, district)
    ];

    final results = await Future.wait(entries.map((e) => getLatLngFromAddress(e.key, e.value)),);

    return [
      for (int i = 0; i < results.length; i++)
        if (results[i] != null && latLngInBounds(results[i]!, bounds)) entries[i]
    ];
  }

  Future<Map<String, Map<String, dynamic>>> _getProvinceWeightData(List<MapEntry<String, String>> districts) async {
    final Map<String, Map<String, dynamic>> result = {};
    final provinces = districts.map((e) => e.key).toSet();

    for (final province in provinces)
      result[province] = await adminData.getWeightData(selectedType, selectedByproductName, province, null);

    print("${adminData.lastTotalWeight}");
    return result;
  }

  Future<void> _generateDistrictMarkers(
      List<MapEntry<String, String>> districts,
      Map<String, Map<String, dynamic>> provinceWeightDataMap) async {

    for (final entry in districts) {
      final province = entry.key;
      final district = entry.value;

      final Set<Marker> markers = await markerHelper.generateSpecificDistrictMarkers(
        province: province,
        districts: [district],
        districtWeightData: provinceWeightDataMap[province]!,
        threshold: threshold!,
        onTap: _onDistrictMarkerTap,
      );

      for (final marker in markers) {
        _districtMarkers.removeWhere((m) => m.markerId == marker.markerId);
        _districtMarkers.add(marker);
      }
    }
  }

  Future<void> reloadProvinceMarkers() async {
    final provinceWeightData = await adminData.getWeightData(selectedType, selectedByproductName, null, null,);
    final markers = await markerHelper.generateProvinceMarkers(provinceWeightData, threshold!, _onProvinceMarkerTap,);
    _provinceMarkers = markers;
    setState(() => total_weight = adminData.lastTotalWeight );
  }


  Future<void> reloadDistrictMarkers() async {
    if (_isReloadingDistrict) return; // 중복 호출 방지
    _isReloadingDistrict = true;

    try {
      final zoom = await _controller?.getZoomLevel() ?? 7.0;
      await lazyLoadDistrictMarker(zoom); // 필요 시 lazy load

      unawaited(Future(() async {
        final stream = markerHelper.graduallyDistrictMarkers(
          selectedType, selectedByproductName, threshold!,
          _onDistrictMarkerTap, adminData,
        );

        await for (final marker in stream) {
          if (!mounted) break;
          _districtMarkers.removeWhere((m) => m.markerId == marker.markerId);
          _districtMarkers.add(marker);
        }
      }));
    } finally {
      _isReloadingDistrict = false;
    }
  }


  Future<void> reloadMarkers() async {
    final zoom = await _controller?.getZoomLevel() ?? 7.0;
    setState(()  => isLoading = true);

    if (zoom <= 7) {
      await reloadProvinceMarkers();
      reloadDistrictMarkers();
    } else {
      await reloadDistrictMarkers();
      reloadProvinceMarkers();
    }


    isLoading = false;
    _drawZoomMarker(zoom);
  }


  void _drawZoomMarker(double zoom) {
    setState(() => currentMarkers = zoom <= 7 ? _provinceMarkers : _districtMarkers);
  }


  Widget _buildMapSection() {
    final _center = LatLng(36.5,127.8);
    return GoogleMap(
      polygons: polygonService.getPolygons(),
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(target: _center , zoom: 7),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(
        context: context,
        title: '관리자 시스템', 
        token: widget.token,
        showBackButton: false,
        showActions: true,
        onRefresh: () async {
          await reloadMarkers(); 
        },
      ),

      body: SafeArea(
        child: Stack(
          children: [
            _buildMapSection(),
            if (isLoading)
              Positioned.fill(
                child: Container(color: Colors.white.withOpacity(0.9), child: Center(child: buildLoadingWidget()))
              ),
            Positioned(top: 0, left: 0, right: 0, child: _buildFilterBar()),
            Positioned(top: 85, left: 0, right: 0, child: _buildSummaryCards()),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavigationBar(
        context,
        [
          BottomNavItem(icon: Icons.home_rounded, label: '홈', isSelected: selectedIndex == 0, onTap: () => _onItemTapped(context, 0)),
          BottomNavItem(icon: Icons.settings_rounded, label: '임계 설정', isSelected: selectedIndex == 1, onTap: () => _onItemTapped(context, 1)),
          BottomNavItem(icon: Icons.science_outlined, label: '시연용(임시)', isSelected: selectedIndex == 2, onTap: () => _onItemTapped(context, 2)),
        ],
        color: Colors.white,
      ),
    );
  }


  Future<void> _onItemTapped(BuildContext context, int index) async {
    setState(() => selectedIndex = index);
    if (index == 0) return;
    if (index == 1) {
      final result = await Navigator.push<int>(context,
        MaterialPageRoute(builder: (context) => SetThresholdAdminPage(token: widget.token)));
      if (result == null) {
        setState(() => selectedIndex = 0);
        return;
      }
      setState(() => selectedIndex = result);
      threshold = await adminData.getThreshold(selectedType, selectedByproductName);
      await reloadMarkers();
    }
    if (index == 2) {
    Navigator.push<int>(context,
          MaterialPageRoute(builder: (context) => Tester()));
    setState(() => selectedIndex = 0);
    }
  }


  Widget _buildFilterBar() {
    final filteredByproducts = byproductsCategory.where((item) => item["type"] == selectedType)
        .map((item) => item["name"]!).toSet()
        .toList();
    return Container(
      margin: const EdgeInsets.only(top: 4, left: 16, right: 16),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight)
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildToggleContainer()),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _buildDropdown(filteredByproducts)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedByproductName,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.w500),
          items: items.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
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
    );
  }

  Widget _buildToggleContainer() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ["가공", "수확"].map((type) {
          return Expanded(child: _buildToggleButton(type, selectedType == type, () async => await _onTypeChanged(type)));
        }).toList(),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown.shade600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(color: Colors.brown.shade600.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
          ] : null,
        ),
        child: Center(
          child: Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 14))
        ),
      ),
    );
  }

  /// 타입 변경 헬퍼 메서드
  Future<void> _onTypeChanged(String newType) async {
    final filtered = byproductsCategory.where((item) => item["type"] == newType).map((item) => item["name"]!).toSet()
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


  List<Map<String, dynamic>> getSummaryCardData() {
    final double disposalRate = 15.2;
    final double recyclingRate = 84.8;
    return [
      {
        'title': '총 무게량',
        'value': total_weight?.toStringAsFixed(1) ?? '-',
        'unit': 'kt',
        'icon': Icons.scale_rounded,
        'gradient': const LinearGradient(colors:[Color(0xFF4E3730), Color(0xFF5A2805)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        'percentage': null,
      },
      {
        'title': '폐기율',
        'value': disposalRate.toStringAsFixed(1),
        'unit': '%',
        'icon': Icons.delete_outline_rounded,
        'gradient': const LinearGradient(colors: [Color(0xFF684226), Color(0xFF533B21)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        'percentage': disposalRate / 100,
      },
      {
        'title': '자원순환율',
        'value': recyclingRate.toStringAsFixed(1),
        'unit': '%',
        'icon': Icons.recycling_rounded,
        'gradient': const LinearGradient(colors:[Colors.brown, Color(0xFF6C4348)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        'percentage': recyclingRate / 100,
      },
    ];
  }

  Widget _buildSummaryCard({
    required String title, required String value, required String unit,
    required IconData icon, required LinearGradient gradient,
    double? percentage,
  }) {
    return Container(
      width: 120, height: 30,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: gradient),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
              Expanded(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 2),
                          Text(unit, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                        ]),
                    ),
                    if (percentage != null)
                      Positioned(bottom: 0, right: 0,
                        child: SizedBox(
                          width: 30, height: 30,
                          child: CircularProgressIndicator(
                            value: percentage,
                            strokeWidth: 2,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        )
                      )]
                ),
              )],
          ),
        ),
      ));
  }

  Widget _buildSummaryCards() {
    final summaryCardData = getSummaryCardData();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 75,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaryCardData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = summaryCardData[index];
          return _buildSummaryCard(
            title: item['title'],
            value: item['value'],
            unit: item['unit'],
            icon: item['icon'],
            gradient: item['gradient'],
            percentage: item['percentage'],
          );
        },
      ),
    );
  }
}