import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import 'korea_boundaries.dart';


class PolygonService {

  final Map<String, Color> provinceColors = {
    "서울특별시": Color(0xFF1A2421), // Dark Jungle Green
    "부산광역시": Color(0xFF0B6623), // Forest Green
    "대구광역시":  Color(0xFFA8E4A0), // Hunter Green
    "인천광역시": Color(0xFF78866B), // Camouflage Green
    "광주광역시": Color(0xFF4B5320), // Army Green
    "대전광역시": Color(0xFF4A5D23), // Dark Moss Green
    "울산광역시": Color(0xFF708238), // Olive Green
    "세종특별자치시": Color(0xFF8F9779), // Artichoke Green
    "경기도": Color(0xFF568203), // Avocado Green
    "강원도": Color(0xFF87A96B), // Asparagus Green
    "충청북도": Color(0xFF9DC183), // Sage Green
    "충청남도": Color(0xFFD8E4BC), // Gin Green
    "전라북도": Color(0xFF48A860), // Chateau Green
    "전라남도": Color(0xFF74C365), // Mantis Green
    "경상북도":Color(0xFF3F704D), // Granny Smith Apple
    "경상남도": Color(0xFF2E8B57), // Sea Green
    "제주특별자치도": Color(0xFF00A86B), // Jade Green
  };

  final Set<Polygon> _polygons = {};

  /// 하드 코딩된 좌표로부터 Polygon 생성
  Future<void> createPolygonsFromConsts() async {
    polygonCoords.forEach((id, coords) {
      // id는 'Gyeonggi_do-0' 처럼 들어있으므로 name을 추출
      final name = id.split('-').first;
      addPolygon(
        id,
        coords,
        color: provinceColors[name] ?? Colors.red,
      );
    });
  }
  void addPolygon(String id, List<LatLng> outerRing,{ Color? color}) {
    if (outerRing.isEmpty) {
      throw ArgumentError("좌표 리스트가 비어있습니다.");
    }
    if (outerRing.length < 3) {
      throw ArgumentError("폴리곤은 최소 3개의 점이 필요합니다.");
    }
    if (_polygons.any((p) => p.polygonId.value == id)) {
      throw ArgumentError("$id Polygon이 이미 존재합니다.");
    }

    _polygons.add(
      Polygon(
        polygonId: PolygonId(id),
        points: outerRing,
        strokeColor: Color(0xFFF2F2F2).withOpacity(0.8),
        strokeWidth: 2,
        fillColor: (color ?? Colors.green).withOpacity(1.0),
      ),
    );
  }

  Set<Polygon> getPolygons() => _polygons;
}