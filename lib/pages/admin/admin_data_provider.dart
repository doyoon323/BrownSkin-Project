import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';


class AdminData {
  final String token;
  double? lastTotalWeight;

  AdminData({required this.token});

  /// 실제 업체가 존재하는 시도 데이터 동적 로드
  Future<Map<String, List<String>>> fetchProvinceData() async {
    String url = "$BASE_URL/api/addr-list";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
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
      //////print("getProvinceData 예외 발생: $e");
      return {};
    }
  }
  /// 실제 업체가 존재하는 구 데이터 동적 로드
  Future<List<String>> fetchDistrictData(String province) async {
    String url = "$BASE_URL/api/addr-list?addr1=$province";
    //////print("🌐 fetchDistrictData 요청 URL: $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      );
      //////print("✅ fetchDistrictData 응답 코드: ${response.statusCode}");
      //////print("✅ fetchDistrictData 응답 body: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        //////print("✅ fetchDistrictData 파싱 결과: $body");

        final List<dynamic> result = body['addr2_list'];
        //////print("✅ fetchDistrictData addr2_list: $result");

        return result.map((e) => e.toString()).toList();
      } else {
        throw Exception('시군구 정보 불러오기 실패 : ${response.statusCode}');
      }
    } catch (e) {
      //////print("⚠️ fetchDistrictData 예외 발생: $e");
      return [];
    }
  }

  /// 해당 지역의 total_weight 반환
  Future<Map<String, dynamic>> getWeightData(
      String type,
      String? byproduct,
      String? addr1,
      String? addr2,
      ) async {
    //print("‼️‼️[WeightAPI] 요청: type=$type, byproduct=$byproduct, province=$addr1 $addr2");
    final url = Uri.parse("$BASE_URL/api/sum-byprod").replace(
      queryParameters: {
        "type": type,
        "name": byproduct,
        if (addr1 != null) "addr1": addr1,
        if (addr2 != null) "addr2": addr2,
      },
    );

    //////print("🌐 getWeightData 요청 URL: $url");

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );
      //////print("✅ getWeightData 응답 코드: ${response.statusCode}");
      //////print("✅ getWeightData 응답 body: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        //print("✅ getWeightData 파싱 결과: $body");

        if (addr2 != null) {
          //print("✅ getWeightData 리턴 (구 or 업체 단위): $body");
          return body as Map<String, dynamic>;
        }

        lastTotalWeight = body["total_weight"];

        //print("✅ getWeightData 리턴 (시도 단위): ${body["results"]}");
        return body["results"] as Map<String, dynamic>;
      } else {
        throw Exception("API 실패: ${response.statusCode}");
      }
    } catch (e) {
      //////print("⚠️ getWeightData() 예외: $e");
      return {};
    }
  }


  /// 현재 선택된 카테고리의 임계치 반환
  Future<double> getThreshold(String type, String? byproduct) async {
    String url = "$BASE_URL/api/threshold?type=$type&name=$byproduct";

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      //////print("✅ Threshold API 응답: $body");
      return (body['weight_float'] as num?)?.toDouble() ?? -1;
    }
    else {
      throw Exception("get Threshold() 실패: ${response.statusCode}");
    }
  }

  /// 갱신한 시도별 구 목록 return
  Future<Map<String, List<String>>> updateRegionData() async {
    final Map<String, List<String>> updated = await fetchProvinceData();

    final provinceList = updated.keys.toList();
    final futures = provinceList.map((province) => fetchDistrictData(province));
    final results = await Future.wait(futures);

    for (int i = 0; i < provinceList.length; i++) {
      updated[provinceList[i]] = results[i];
    }
    return updated;
  }
  }
