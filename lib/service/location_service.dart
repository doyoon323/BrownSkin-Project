import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';



  Future<LatLng> getLatLngFromAddress(String addr1, String addr2) async {
    print("🔍 getLatLngFromAddress(): $addr1 $addr2");

    final url = Uri.parse(
        'https://dapi.kakao.com/v2/local/search/address.json?query=${addr1 + addr2}'
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
        print("⚠️ 주소 결과 없음: $addr1 $addr2");
        print("⚠️ Province '$addr1 $addr2' 마커 생성 실패");
        return LatLng(0, 0);
      }
      final doc = body['documents'][0];
      print("✅ 좌표 결과: ${doc['y']}, ${doc['x']}");
      return LatLng(
        double.parse(doc['y']),
        double.parse(doc['x']),
      );
    } else {
      print("❌ API 호출 실패: ${response.statusCode}");
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  }

