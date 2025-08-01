import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/constants.dart';


class AdminData {
  final String token;
  double? lastTotalWeight;

  AdminData({required this.token});


  /// 실제 업체가 존재하는 구 데이터 동적 로드
  Future<List<String>> fetchDistrictData(String province) async {
    final body = await ApiService.fetchMap(url: "$BASE_URL/api/addr-list?addr1=$province", token: token);
    final List<dynamic> result = body['addr2_list'];
    return result.map((e) => e.toString()).toList();
  }

  /// 해당 지역의 total_weight 반환
  Future<Map<String, dynamic>> getWeightData(String type, String? byproduct,
      String? addr1, String? addr2,) async {
    final url = Uri.parse("$BASE_URL/api/sum-byprod").replace(
      queryParameters: {
        "type": type,
        "name": byproduct,
        if (addr1 != null) "addr1": addr1,
        if (addr2 != null) "addr2": addr2,
      },
    );

    final Map<String, dynamic> body = await ApiService.fetchMap(url: url.toString(), token: token);
    if (addr2 != null) return body;
    else if (addr1 == null) lastTotalWeight = body["total_weight"];

    return body["results"] ?? {};
  }


  /// 현재 선택된 카테고리의 임계치 반환
  Future<double> getThreshold(String type, String? byproduct) async {
    final body = await ApiService.fetchMap(url: "$BASE_URL/api/threshold?type=$type&name=$byproduct", token: token);
    if (body['weight_float'] is num)  return (body['weight_float'] as num).toDouble();
    else return -1;
  }

  /// 갱신한 시도별 구 목록 return
  Future<Map<String, List<String>>> updateRegionData() async {
    final Map<String, List<String>> updated = allAreas;
    final provinceList = updated.keys.toList();
    final results = <List<String>>[];

    for (final province in provinceList) {
      final districts = await fetchDistrictData(province);
      results.add(districts);
    }
    for (int i = 0; i < provinceList.length; i++)
      updated[provinceList[i]] = results[i];

    return updated;
  }
}