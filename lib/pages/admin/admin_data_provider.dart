import 'dart:convert';
import 'package:brownskin_app/pages/admin/global.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';


class AdminData {
  final String token;

  AdminData({required this.token});

  /// 실제 업체가 존재하는 시도 데이터 동적 로드
  Future<Map<String, List<String>>> fetchProvinceData() async {
    String url = "$BASE_URL/api/addr-list";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token ${this.token}'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> result = body['addr1_list'];

        return {
          for (final province in result) province.toString(): []
        };
      } else {
        throw Exception('지역 정보 불러오기 실패 : ${response.statusCode}');
      }
    } catch (e) {
      print("getProvinceData 예외 발생: $e");
      return {};
    }
  }

  /// 실제 업체가 존재하는 구 데이터 동적 로드
  Future<List<String>> fetchDistrictData(String province) async {
    String url = "$BASE_URL/api/addr-list?addr1=$province";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token ${this.token}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        final List<
            dynamic> result = body['addr2_list']; // API 결과 예: {"addr2_list": ["강남구","송파구"]}

        return result.map((e) => e.toString()).toList();
      } else {
        throw Exception('시군구 정보 불러오기 실패 : ${response.statusCode}');
      }
    } catch (e) {
      print("getDistrictData 예외 발생: $e");
      return [];
    }
  }

  /// 해당 지역의 total_weight 반환 : return => {total_weight, result:{'서울':w1,'부산':w2}} or {total_weight}
  Future<Map<String, dynamic>> getWeightData(String type, String? byproduct,
      String? addr1, String? addr2) async {
    final url = Uri.parse("$BASE_URL/api/sum-byprod").replace(
      queryParameters: {
        "type": type,
        "name": byproduct,
        if (addr1 != null) "addr1": addr1,
        if (addr2 != null) "addr2": addr2,
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token ${this.token}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));

        if (addr2 != null) { // 구 단위 or 업체 단위
          return body as Map<String, dynamic>;
        }
        // 시도 단위
        return body["results"] as Map<String, dynamic>;
      } else {
        throw Exception("API 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("getProvinceWeightData() 예외: $e");
      return {};
    }
  }


  /// 현재 선택된 카테고리의 임계치 반환
  Future<double> getThreshold(String type, String? byproduct) async {
    String url = "$BASE_URL/api/threshold?type=$type&name=$byproduct";

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token ${this.token}'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      print("✅ Threshold API 응답: $body");
      return (body['weight_float'] as num?)?.toDouble() ?? -1;
    }
    else {
      throw Exception("get Threshold() 실패: ${response.statusCode}");
    }
  }

  /// 갱신한 시도별 구 목록 return
  Future<Map<String, List<String>>> updateRegionData() async {
    print("✅ updateRegionData 호출됨");
    final Map<String, List<String>> updated = await fetchProvinceData();
    print("✅ 시도 데이터: $updated");

    final provinceList = updated.keys.toList();
    final futures = provinceList.map((province) => fetchDistrictData(province));
    final results = await Future.wait(futures);

    for (int i = 0; i < provinceList.length; i++) {
      updated[provinceList[i]] = results[i];
    }
    print("✅ 구까지 포함된 데이터: $updated");
    return updated;
  }
  }
