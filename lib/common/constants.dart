//const String BASE_URL = 'http://127.0.0.1:8000';
//const String BASE_URL = 'http://10.0.2.2:8000'; //맥북 로컬

// ignore_for_file: constant_identifier_names

const String BASE_URL = 'http://brownskin.duckdns.org:8000'; //클라우드 서버(ec2)

const String weight_unit = "kt";

final byproductsCategory = [
  // 전체 품목
  {"name": "사과", "type": "가공"},
  {"name": "배", "type": "가공"},
  {"name": "참깨", "type": "가공"},
  {"name": "들깨", "type": "가공"},
  {"name": "두부", "type": "가공"},


  {"name": "사과", "type": "수확"},
  {"name": "배", "type": "수확"},
  {"name": "배추", "type": "수확"},
  {"name": "무", "type": "수확"},
  {"name": "양파", "type": "수확"},
  {"name": "파", "type": "수확"},
  {"name": "토마토", "type": "수확"},
  {"name": "포도", "type": "수확"},
  {"name": "감귤", "type": "수확"},
  {"name": "오미자", "type": "수확"},
  {"name": "매실", "type": "수확"},
  {"name": "옥수수", "type": "수확"},
  {"name": "볏짚", "type": "수확"},
  {"name": "콩", "type": "수확"},
  {"name": "버섯", "type": "수확"},
];



Map<String, List<String>> allAreas = {
  "서울특별시": [],
  "부산광역시": [],
  "대구광역시": [],
  "인천광역시": [],
  "광주광역시": [],
  "대전광역시": [],
  "울산광역시": [],
  "세종특별자치시": [],
  "경기도": [],
  "강원도": [],
  "충청북도": [],
  "충청남도": [],
  "전라북도": [],
  "전라남도": [],
  "경상북도": [],
  "경상남도": [],
  "제주특별자치도": [],
};

