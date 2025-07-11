import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';


final Map<String, LatLng> _latLngCache = {};

Future<LatLng> getLatLngFromAddress(String addr1, String addr2) async {
  final key = '$addr1 $addr2';


  if (_latLngCache.containsKey(key)) {
    //print("✅ 캐시된 좌표 사용: $key");
    return _latLngCache[key]!;
  }

  //print("🔍 getLatLngFromAddress(): $key");

  final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=$key'
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
      print("⚠️ 주소 결과 없음: $key");
      return LatLng(0, 0);
    }
    final doc = body['documents'][0];
    final latLng = LatLng(
      double.parse(doc['y']),
      double.parse(doc['x']),
    );

    //print("✅ 좌표 결과: ${doc['y']}, ${doc['x']}");

    // ✅ 캐시에 저장
    _latLngCache[key] = latLng;

    return latLng;
  } else {
    print("❌ API 호출 실패: ${response.statusCode}");
    throw Exception('API 호출 실패: ${response.statusCode}');
  }
}