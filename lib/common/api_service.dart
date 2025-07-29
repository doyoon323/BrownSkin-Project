//이 파일은 배송사, 전처리사, 농가요청화면의 공통 api껍데기를 뺀 파일입니다
//GET 과 POST

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiService {
  /// GET 요청 공통화 (요청 후 JSON 파싱해서 형식 반환)
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
        debugPrint('GET 요청 실패 ($url): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('GET 요청 중 예외 발생 ($url): $e');
    }

    return [];
  }
  //POST 함수 공통화
  static Future<http.Response?> postWithToken({
    required String endpoint,
    required String token,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse('$BASE_URL$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      if (response.statusCode >= 400) {
        debugPrint('POST 실패 [$endpoint]: ${response.statusCode} - ${response.body}');
      }

      return response;
    } catch (e) {
      debugPrint('POST 예외 발생 [$endpoint]: $e');
      return null;
    }
  }


  static Future<Map<String, dynamic>> fetchMap({
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
        if (parsed is Map<String, dynamic>) {
          return parsed;
        } else {
          print('Response is not a Map as expected.');
        }
      } else {
        print('GET request failed ($url): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception during GET request ($url): $e');
    }
    return {};
  }

}
