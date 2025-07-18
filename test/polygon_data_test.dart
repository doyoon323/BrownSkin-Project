import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brownskin_app/model/polygon_data.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  group('PolygonService GeoJSON 테스트', () {


    test('GeoJSON 시도 데이터 개수(17) 검사', () async {
      final service = PolygonService();
      await service.createPolygonsFromConsts();
      final polygons = service.getPolygons();

      // PolygonId에 들어간 name 파싱
      final uniqueProvinceNames = polygons
          .map((p) => p.polygonId.value.split('-').first)
          .toSet();

      debugPrint('로드된 시도 개수: ${uniqueProvinceNames.length}');
      debugPrint('시도 이름 목록: $uniqueProvinceNames');

      expect(uniqueProvinceNames.length, 17, reason: '시도 개수가 17개인지 확인');
    });
  });
}