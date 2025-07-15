import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../pages/admin/global.dart';



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

  final query = addr2.isEmpty ? addr1 : "$addr1 $addr2";
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