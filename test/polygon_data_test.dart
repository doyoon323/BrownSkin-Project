import 'package:flutter_test/flutter_test.dart';
import 'package:brownskin_app/model/polygon_data.dart';

void main() {
  group('PolygonService GeoJSON 테스트', () {
    final service = PolygonService();

    test('GeoJSON 파일이 깨지지 않고 로드된다', () async {
      final geoJson = await service.loadGeoJson();

      // Map인지 확인
      expect(geoJson, isA<Map<String, dynamic>>());

      // features 키가 있어야 함
      expect(geoJson.containsKey('features'), true);
    });

    test('GeoJSON에 17개의 시도 데이터가 들어있다', () async {
      final geoJson = await service.loadGeoJson();
      final features = geoJson['features'] as List<dynamic>;

      expect(features.length, 17, reason: '시도 개수가 17개인지 확인');
    });
  });
}