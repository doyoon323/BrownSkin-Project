import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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

    final List features = geoJson['features'];

    // 서울만 따로 빼고
    final seoulFeature = features.firstWhere(
          (f) => f['properties']['name'] == '서울특별시',
      orElse: () => null,
    );


    for (final feature in geoJson['features']) {
      final geometry = feature['geometry'];
      final String name = feature['properties']['name'];


      print("폴리곤 생성: $name");

      final Color provinceColor = provinceColors[name] ?? Colors.green;

      if (geometry['type'] == 'Polygon') {
        final coords = parseCoordinates(geometry['coordinates'][0]);
        print("서울 Polygon 점 개수: ${coords.length}");
        addPolygon(name, coords, color: provinceColor);
      } else if (geometry['type'] == 'MultiPolygon') {
        final parts = parseMultiPolygon(geometry['coordinates']);
        for (var i = 0; i < parts.length; i++) {
          addPolygon('$name-$i', parts[i], color: provinceColor);
        }
      }
    }

    // 서울 마지막에 추가
    if (seoulFeature != null) {
      final geometry = seoulFeature['geometry'];
      final Color provinceColor = provinceColors["서울특별시"] ?? Colors.green;

      if (geometry['type'] == 'Polygon') {
        final coords = parseCoordinates(geometry['coordinates'][0]);
        addPolygon("서울특별시", coords, color: provinceColor);
      } else if (geometry['type'] == 'MultiPolygon') {
        final parts = parseMultiPolygon(geometry['coordinates']);
        for (var i = 0; i < parts.length; i++) {
          addPolygon("서울특별시-$i", parts[i], color: provinceColor);
        }
      }
    }
  }

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
        strokeColor: Color(0xFFF2F2F2).withOpacity(0.8), // 경계선 흰색으로 고정
        strokeWidth: 2,
        fillColor: (color ?? Colors.green), // 불투명 색상
      ),
    );
  }

  Set<Polygon> getPolygons() => _polygons;
}