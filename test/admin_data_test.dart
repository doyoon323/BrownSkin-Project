import 'package:flutter_test/flutter_test.dart';
import 'package:brownskin_app/pages/admin/admin_data_provider.dart';

void main() {

  test('fetchProvinceData() 성공 케이스', () async {
    const testToken = "test-token";
    final service = AdminData(token: testToken);

    final result = await service.fetchProvinceData();

    expect(result, isA<Map<String, List<String>>>());
    expect(result.isNotEmpty, true);
  });

  test('fetchProvinceData() 성공 케이스', () async {
    const testToken = "test-token";
    final service = AdminData(token: testToken);


    final result = await service.fetchProvinceData();
    expect(result, isA<Map<String, List<String>>>());

    expect(result.isNotEmpty, false);
  });



  group('WeightService 테스트', () {
    // ★ 실제 token 넣어야 합니다.
    const testToken = "YOUR_TEST_TOKEN";
    final service = AdminData(token: testToken);

    test('API 응답이 Map<String, dynamic> 형태인지 검사', () async {
      final data = await service.getWeightData(
        "수확",
        "사과",
        null, // addr1 없이 요청
        null,
      );

      expect(data, isA<Map<String, dynamic>>());
      expect(data.containsKey("total_weight"), true);

      // results도 있으면 검사
      if (data.containsKey("results")) {
        expect(data["results"], isA<Map<String, dynamic>>());
      }
    });

    test('addr1, addr2 포함 요청 시 결과가 Map인지 검사', () async {
      final data = await service.getWeightData(
        "수확",
        "사과",
        "경기도",
        "수원시",
      );

      expect(data, isA<Map<String, dynamic>>());

      // addr2까지 필터 걸면 results 대신 단일 weight 반환되는 상황도 고려
      // total_weight는 항상 있어야 함
      expect(data.containsKey("total_weight"), true);
    });
  });
}