import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class PolygonService {
  static const Map<String, Color> provinceColors = {
    "서울특별시": Colors.green,
    "부산광역시": Colors.teal,
    "대구광역시": Colors.lightGreen,
    "인천광역시": Colors.lime,
    "광주광역시": Color(0xFF008000), // Standard green
    "대전광역시": Color(0xFF006400), // DarkGreen
    "울산광역시": Color(0xFF228B22), // ForestGreen
    "세종특별자치시": Color(0xFF2E8B57), // SeaGreen
    "경기도": Color(0xFF66CDAA), // MediumAquamarine
    "강원도": Color(0xFF20B2AA), // LightSeaGreen
    "충청북도": Color(0xFF3CB371), // MediumSeaGreen
    "충청남도": Color(0xFF00FA9A), // MediumSpringGreen
    "전라북도": Color(0xFF00FF7F), // SpringGreen
    "전라남도": Color(0xFF7FFFD4), // Aquamarine
    "경상북도": Color(0xFF98FB98), // PaleGreen
    "경상남도": Color(0xFF90EE90), // LightGreen
    "제주특별자치도": Color(0xFF32CD32), // LimeGreen
  };

  final Set<Polygon> _polygons = {};

  /// GeoJSON 로드
  Future<Map<String, dynamic>> loadGeoJson() async {
    final jsonStr = await rootBundle.loadString('assets/korea_boundaries.json');
    return jsonDecode(jsonStr);
  }

  /// 좌표 리스트를 LatLng로 변환
  List<LatLng> parseCoordinates(List coords) {
    return coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
  }

  /// MultiPolygon 처리
  List<List<LatLng>> parseMultiPolygon(List coords) {
    return coords.map<List<LatLng>>(
          (polygon) => polygon[0].map<LatLng>((c) => LatLng(c[1], c[0])).toList(),
    ).toList();
  }

  /// GeoJSON -> Polygon 생성
  Future<void> createPolygonsFromGeoJson() async {
    final geoJson = await loadGeoJson();

    for (final feature in geoJson['features']) {
      final geometry = feature['geometry'];
      final String name = feature['properties']['name'];

      final Color provinceColor = provinceColors[name] ?? Colors.green;

      if (geometry['type'] == 'Polygon') {
        final coords = parseCoordinates(geometry['coordinates'][0]);
        addPolygon(name, coords, color: provinceColor);
      } else if (geometry['type'] == 'MultiPolygon') {
        final parts = parseMultiPolygon(geometry['coordinates']);
        for (var i = 0; i < parts.length; i++) {
          addPolygon('$name-$i', parts[i], color: provinceColor);
        }
      }
    }
  }


  /// Polygon 추가
  void addPolygon(String id, List<LatLng> coords, {Color? color}) {
    if (coords.isEmpty) {
      throw ArgumentError("좌표 리스트가 비어있습니다.");
    }
    if (coords.length < 3) {
      throw ArgumentError("폴리곤은 최소 3개의 점이 필요합니다.");
    }
    if (_polygons.any((p) => p.polygonId.value == id)) {
      throw ArgumentError("$id Polygon이 이미 존재합니다.");
    }

    _polygons.add(
      Polygon(
        polygonId: PolygonId(id),
        points: coords,
        strokeColor: color ?? Colors.green,
        fillColor: (color ?? Colors.green).withOpacity(0.3),
        strokeWidth: 2,
      ),
    );
  }

  Set<Polygon> getPolygons() => _polygons;
}