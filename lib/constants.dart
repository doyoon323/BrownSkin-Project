import 'package:flutter_naver_map/flutter_naver_map.dart';

//const String BASE_URL = 'http://127.0.0.1:8000';
const String BASE_URL = 'http://10.0.2.2:8000'; //맥북 로컬
//const String BASE_URL = "https://961d-203-252-33-1.ngrok-free.app"; //핸드폰

final byproductsCategory = [
  //전체 품목, 추후 17 종까지 늘어날 예정
  {"name": "배추", "type": "수확"},
  {"name": "사과", "type": "가공"},
  {"name": "사과", "type": "수확"},
  {"name": "무", "type": "수확"},
  {"name": "옥수수", "type": "수확"},
];

final Map<String, NLatLng> provinceCoordinates = {
  "서울": NLatLng(37.5665, 126.9780),
  "부산": NLatLng(35.1796, 129.0756),
  "대구": NLatLng(35.8714, 128.6014),
  "인천": NLatLng(37.4563, 126.7052),
  "광주": NLatLng(35.1595, 126.8526),
  "대전": NLatLng(36.3504, 127.3845),
  "울산": NLatLng(35.5384, 129.3114),
  "세종": NLatLng(36.4801, 127.2891),
  "경기": NLatLng(37.4138, 127.5183),
  "강원": NLatLng(37.8228, 128.1555),
  "충북": NLatLng(36.6358, 127.4913),
  "충남": NLatLng(36.5184, 126.8000),
  "전북": NLatLng(35.7175, 127.1530),
  "전남": NLatLng(34.8161, 126.4630),
  "경북": NLatLng(36.4919, 128.8889),
  "경남": NLatLng(35.4606, 128.2132),
  "제주": NLatLng(33.4996, 126.5312),
};

