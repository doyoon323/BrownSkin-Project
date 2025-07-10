//이 파일은 배송사, 전처리사, 농가요청화면의 공통함수를 뺀 파일입니다...

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /// GET 요청 후 JSON 파싱해서 List<Map<String, dynamic>>로 반환
  static Future<List<Map<String, dynamic>>> fetchList({
    required String url,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Authorization": "Token $token"},
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(utf8.decode(response.bodyBytes));
        if (parsed is Map && parsed.containsKey('results')) {
          return List<Map<String, dynamic>>.from(parsed['results']);
        } else if (parsed is List) {
          return List<Map<String, dynamic>>.from(parsed);
        }
      } else {
        print('GET 요청 실패 ($url): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('GET 요청 중 예외 발생 ($url): $e');
    }

    return [];
  }
}
