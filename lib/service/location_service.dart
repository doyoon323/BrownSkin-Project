import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../pages/admin/global.dart';

//여기서 주기적으로 area DB 최신 갱신하고, cache에 넣어두면 UI에도 반영 가능할 듯

final Map<String, Map<String, LatLng>> _latLngCache = {};

Future<void> preloadAllDistrictLatLng({int batchSize = 10}) async {
  print("🌱 District 좌표 Preload 시작");
  final sw = Stopwatch()..start();
  final tasks = <Future>[];

  for (final entry in allAreas.entries) {
    final province = entry.key;
    for (final district in entry.value) {
      tasks.add(getLatLngFromAddress(province, district));

      // 일정 갯수마다 대기
      if (tasks.length >= batchSize) {
        await Future.wait(tasks);
        tasks.clear();
      }
    }
  }
  // 남은 작업 처리
  if (tasks.isNotEmpty) {
    await Future.wait(tasks);
  }
  sw.stop();
  print("🎉 District 좌표 Preload 총 소요 시간: ${sw.elapsedMilliseconds} ms");
}



Future<LatLng> getLatLngFromAddress(String addr1, String addr2) async {
  // 1. 캐시 확인
  if (_latLngCache[addr1]?.containsKey(addr2) == true) {
    return _latLngCache[addr1]![addr2]!;
  }

  final normAddr1 = normalizeProvinceName(addr1);
  final query = addr2.isEmpty ? normAddr1 : "$normAddr1 $addr2";

  final url = Uri.parse(
    'https://dapi.kakao.com/v2/local/search/address.json?query=$query',
  );

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'KakaoAK 75acb2a58d477b9c94d5c3e61790980b'
    },
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body['documents'].isEmpty) {
      print("⚠️ 주소 결과 없음: $query");
      return LatLng(0, 0);
    }

    final doc = body['documents'][0];
    final latLng = LatLng(
      double.parse(doc['y']),
      double.parse(doc['x']),
    );

    // 2. 캐시에 저장
    _latLngCache.putIfAbsent(addr1, () => {})[addr2] = latLng;

    return latLng;
  } else {
    print("❌ API 호출 실패: ${response.statusCode}");
    throw Exception('API 호출 실패: ${response.statusCode}');
  }
}

String normalizeProvinceName(String name) {
  return {
    '서울': '서울특별시',
    '부산': '부산광역시',
    '대구': '대구광역시',
    '인천': '인천광역시',
    '광주': '광주광역시',
    '대전': '대전광역시',
    '울산': '울산광역시',
    '세종': '세종특별자치시',
    '경기': '경기도',
    '강원': '강원도',
    '충북': '충청북도',
    '충남': '충청남도',
    '전북': '전라북도',
    '전남': '전라남도',
    '경북': '경상북도',
    '경남': '경상남도',
    '제주': '제주특별자치도',
  }[name] ?? name;
}