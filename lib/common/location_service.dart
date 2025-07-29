import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'constants.dart';


//여기서 주기적으로 area DB 최신 갱신하고, cache에 넣어두면 UI에도 반영 가능할 듯

final Map<String, Map<String, LatLng>> _latLngCache = {
  "광주": {"": LatLng(35.1601037626652, 126.851629955742)},
  "부산": {"": LatLng(35.1798200522897, 129.075087492149)},
  "인천": {"": LatLng(37.4560044656442, 126.705258070068)},
  "대전": {"": LatLng(36.350538899283, 127.38483484675)},
  "경기": {"": LatLng(37.2749769872422, 127.00892996953)},
  "서울": {"": LatLng(37.5668260046608, 126.978652258309)},
  "대구": {"": LatLng(35.8713802646199, 128.601805491072)},
  "세종": {"": LatLng(36.4800649113757, 127.289195324698)},
  "울산": {"": LatLng(35.5395955247124, 129.311603446506)},
  "경북": {"": LatLng(36.5759962255809, 128.505799255401)},
  "충북": {"": LatLng(36.6353581959949, 127.491457326501)},
  "전북": {"": LatLng(35.8201963639265, 127.108976712011)},
  "제주": {"": LatLng(33.488917903259, 126.498229141199)},
  "충남": {"": LatLng(36.6588292532859, 126.672776193822)},
  "전남": {"": LatLng(34.8160821478838, 126.462788333376)},
  "경남": {"": LatLng(35.2377742104524, 128.69189688916)},
  "강원": {"": LatLng(37.8853257858209, 127.729829010354)}
};

Future<void> preloadAllDistrictLatLng({int batchSize = 10}) async {
  final tasks = <Future>[];

  for (final entry in allAreas.entries) {
    final province = entry.key;
    for (final district in entry.value) {
      tasks.add(getLatLngFromAddress(province, district));

      // 일정 개수마다 대기
      if (tasks.length >= batchSize) {
        await Future.wait(tasks);
        tasks.clear();
      }
    }
  }
  // 남은 작업 처리
  if (tasks.isNotEmpty) await Future.wait(tasks);
}

Future<LatLng?> getLatLngFromAddress(String addr1, String addr2) async {
  // 1. 캐시 확인
  if (_latLngCache[addr1]?.containsKey(addr2) == true)
    return _latLngCache[addr1]![addr2]!;

  final normAddr1 = normalizeProvinceName(addr1);
  final query = addr2.isEmpty ? normAddr1 : "$normAddr1 $addr2";

  final url = Uri.parse('https://dapi.kakao.com/v2/local/search/address.json?query=$query');
  final response = await http.get(
    url,
    headers: {'Authorization': 'KakaoAK 75acb2a58d477b9c94d5c3e61790980b'},
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body['documents'].isEmpty) {
      print("⚠️ 주소 결과 없음: $query");
      return null;
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

bool latLngInBounds(LatLng point, LatLngBounds bounds) {
  final lat = point.latitude;
  final lng = point.longitude;

  final southWest = bounds.southwest;
  final northEast = bounds.northeast;

  return lat >= southWest.latitude &&
      lat <= northEast.latitude &&
      lng >= southWest.longitude &&
      lng <= northEast.longitude;
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