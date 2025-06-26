import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class AgriHome extends StatefulWidget {
  @override
  AgriHomeState createState() => AgriHomeState();
}


class AgriHomeState extends State<AgriHome>{
  final byproducts = [
    {"name":"배추", "type":"가공"},
    {"name":"사과", "type":"가공"},
    {"name":"사과" ,"type":"수확"},
    {"name":"참깨","type":"수확"},
    {"name":"옥수수","type":"수확"}
  ];
  Map<String,String?>? selected;
  //무게 입력
  final TextEditingController weightController = TextEditingController();
  final token = "4e5ffe467b0cb16db51cb3c13dc4bc8ab835f2f4"; //temp



  @override
  void initState() {
    super.initState();
  }


  Future<void> temp_login() async {
    final url = Uri.parse("http://10.0.2.2:8000/auth/api-token");
    final token = await http.post(url,
        body: {
          "username": "test2",
          "password" : "pbkdf2_sha256\$1000000\$qWBxYu1hdGJnwbS7BKf7OJ\$T624KHbrC9qbU/ndBPSpZYmfR4P8njPRCQ3DYUvG70E="
        }); //복호화된 함수라서 이거 쓰면 안된다고 함 ...

    if (token.statusCode == 200){

    }else{
      throw Exception('로그인 실패: ${token.statusCode}');
    }

  }


  //등록한 무게 저장
  Future<void> addWeight() async {
    final String? type = selected?['type'];
    final String weight = weightController.text.trim();

    // 에러 처리 : 무게 혹은 타입을 입력하지 않는 경우
    if (type == null || weight.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("무게와 타입을 모두 입력하세요")),
      );
      if (weight.isNotEmpty) weightController.clear();
      return;
    }

    // 에러 처리 : 유효한 값인지 확인
    final parsedWeight = double.tryParse(weight); // 이상한 값은 전부 null 처리
    if (parsedWeight == null || parsedWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("유효하지 않은 입력입니다.")),
      );
      if (weight.isNotEmpty) weightController.clear();
      return;
    }

    final url = Uri.parse("http://10.0.2.2:8000/api/add-weight");
    //무게 등록 값, 타입 POST
    try {
        final response = await http.post(url,
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              "Authorization": "Token $token",
            },
            body: {
              "weight": weight,
              "type": type,
            }
            );

        if (response.statusCode == 200) {
          print('addWeight 성공');
        } else {
          final err = response.body.isNotEmpty
              ? jsonDecode(response.body)['error'] ?? '알 수 없는 에러'
              : '알 수 없는 에러';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("실패: $err")),
          );
          print('addWeight 실패: $err');
        }

    } catch (e) {
      print("Network doesn't work : $e");
      rethrow;
    }
  }


  //데이터 시각화를 위해 현재 저장
  Future<void> getWeight() async {
    final token = "4e5ffe467b0cb16db51cb3c13dc4bc8ab835f2f4";
    final url = Uri.parse("http://10.0.2.2:8000/api/add-weight");
  }





  //임계치를 받고, 현재 무게를 가져서.. 데이터 시각화하기
  void cal(){
    var threshold; // total amount
    var prefix_sum; // value (표시할 값)
    double percent = prefix_sum / threshold;

/*
    //이런식으로 구할 수 있다고 함

    CircularPercentIndicator(
        percent: percent.clamp(0.0, 1.0), // 반드시 0.0 ~ 1.0 범위로 제한
        center: Text("${(percent * 100).toStringAsFixed(0)}%"),
        ...
    )
 */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(title: Text('부산물 입력')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // 1. 드롭다운
            Text(
              '부산물 유형 선택',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, String?>>(
                  value: selected,
                  hint: Text("부산물 유형을 선택해주세요"),
                  isExpanded: true,
                  items: byproducts.map((item) {
                    return DropdownMenuItem<Map<String, String?>>(
                      value: item,
                      child: Text(item['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selected = value;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 20),

            // 2. 무게 입력 텍스트란
            Text(
              '무게 입력 (kg)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '예: 100',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 30),

            // 3. 무게 입력 버튼
            ElevatedButton(
              onPressed: addWeight,//버튼 누르면 서버로 데이터 전송
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '입력',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      // 4. 하단 바 (예시용)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }



  /* 하단 네비게이션 바 (UI만 구현)  -> 추후 클릭 시 화면 이동하는 기능 구현해두어야함 */
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.indigo[600],
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Colors.white,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: '배송 요청 목록',
          ),
        ],
      ),
    );
  }

}

