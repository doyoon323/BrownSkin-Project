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

    for (final feature in features) {
      final geometry = feature['geometry'];
      final String name = feature['properties']['name'];
      final Color provinceColor = provinceColors[name] ?? Colors.red;


      if (name == '경기도') {
        // 경기도 하드코딩 좌표 (경기도)
        final List<LatLng> gyeonggiCoords = [
          LatLng(37.45859429669539, 127.11674713187564),
          LatLng(37.43637048559158, 126.90192185647521),
          LatLng(37.5511754194035, 126.76474895751049),
          LatLng(37.42904817687088, 126.77035223152424),
          LatLng(37.32988698791891, 126.67106449501567),
          LatLng(37.111924478183454, 126.68612820151787),
          LatLng(37.1888808779548, 126.79710503013769),
          LatLng(37.02925100714912, 126.75100563879833),
          LatLng(36.90509655991407, 126.9086368769204),
          LatLng(36.96610951620199, 127.10442880537073),
          LatLng(36.89353353381547, 127.28855840198274),
          LatLng(37.0529979060048, 127.46803673152135),
          LatLng(37.042950020990205, 127.55979973400154),
          LatLng(37.13530729579704, 127.68790646576998),
          LatLng(37.30289227872186, 127.76768239764084),
          LatLng(37.55321122766271, 127.8494476999771),
          LatLng(37.628449266439425, 127.55898162627281),
          LatLng(37.838905235791906, 127.52927275935066),
          LatLng(37.95509527270969, 127.60299370955819),
          LatLng(38.016233286625365, 127.45798948551693),
          LatLng(38.10817136032753, 127.4410047744206),
          LatLng(38.14685891066471, 127.2232670267822),
          LatLng(38.29203792732757, 127.10928347342096),
          LatLng(38.22307678822598, 126.87296943934071),
          LatLng(38.127802544460295, 126.7480633194675),
          LatLng(38.06979000320887, 126.89308963723236),
          LatLng(38.01856307572189, 126.87254005350819),
          LatLng(37.95569988264043, 126.67038387779681),
          LatLng(37.784517209504884, 126.66700405635578),
          LatLng(37.76694862256429, 126.51456397746584),
          LatLng(37.586077393531376, 126.56574983556453),
          LatLng(37.63822828854139, 126.6594362051889),
          LatLng(37.57561931537229, 126.8509394260532),
          LatLng(37.70102523886384, 127.01584584752527),
          LatLng(37.68771674545948, 127.0959236405964),
          LatLng(37.56002336317411, 127.1011460799232),
          LatLng(37.54582646715933, 127.18355190345548),
          LatLng(37.45859429669539, 127.11674713187564),
        ];

        addPolygon(name, gyeonggiCoords,color: provinceColor);
        continue;
      }

      if (geometry['type'] == 'Polygon') {
        final List coords = geometry['coordinates'];
        final List<LatLng> outerRing = parseCoordinates(coords[0]);


        addPolygon(name, outerRing, color: provinceColor);
      } else if (geometry['type'] == 'MultiPolygon') {
        final parts = parseMultiPolygon(geometry['coordinates']);
        for (var i = 0; i < parts.length; i++) {
          addPolygon('$name-$i', parts[i], color: provinceColor);
        }
      }
    }
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