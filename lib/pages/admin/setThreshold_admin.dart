import 'dart:convert';

import 'package:brownskin_app/pages/admin/home_admin.dart';
import 'package:flutter/material.dart';
import 'package:brownskin_app/constants.dart';
import 'package:http/http.dart' as http;

class SetThresholdAdminPage extends StatefulWidget {
  List<String> provinces = [];
  String token;

  SetThresholdAdminPage({required this.provinces, required this.token, super.key});


  @override
  _SetThresholdAdminPageState createState() => _SetThresholdAdminPageState();
}

class _SetThresholdAdminPageState extends State<SetThresholdAdminPage> {
  final TextEditingController _currentWeightController =
      TextEditingController();
  final TextEditingController _targetGoalController = TextEditingController();


  List<Map<String, String?>> byproductsCategory = [
    {"type": "가공", "name": "사과"},
    {"type": "수확", "name": "사과"},
    {"type": "수확", "name": "배추"},
    {"type": "수확", "name": "참깨"},
    {"type": "수확", "name": "옥수수"},
  ];



  @override
  void dispose() {
    _currentWeightController.dispose();
    _targetGoalController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    print("✅ initState() 호출됨 $widget.provinces");
  }




  Future<bool> setThreshold(int? weight) async {
    String? nextUrl = "$BASE_URL/api/threshold";

    final request = await http.post(
      Uri.parse(nextUrl),
      headers: {"Content-Type": "application/json",
        'Authorization': 'Token ${widget.token}'},
      body: {
        'type': selectedType,
        'name': selectedByproductName,
        'weight' : weight
      },
    );

    print(request.body);

    if (request.statusCode == 200) {
      final body = jsonDecode(utf8.decode(request.bodyBytes));
      return true;
    }

    return false;
  }


    int selectedIndex = 0;

  void _onItemTapped(BuildContext context, int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index == 0) {
      // 홈
      Navigator.pop(
        context,
        true
      );
    } else if (index == 1) {
      // 임계 설정 페이지로 이동

    }
  }

  String? selectedType;
  String? selectedByproductName;
  String? selectedProvince;




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main content area
                          // 부산물 유형 선택
                          const Text('부산물 유형 선택'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            hint: const Text("유형을 선택해주세요"),
                            items: ["가공", "수확"].map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value;
                                selectedByproductName = null;
                                //updateInfo(); // 유형 선택 시 갱신
                              });
                            },
                          ),


                          if (selectedType != null) ...[
                            const SizedBox(height: 16),
                            const Text('품목 선택'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedByproductName,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              hint: const Text("품목을 선택해주세요"),
                              items: byproductsCategory
                                  .where((item) => item['type'] == selectedType)
                                  .map(
                                    (item) =>
                                    DropdownMenuItem<String>(
                                      value: item['name'],
                                      child: Text(item['name']!),
                                    ),
                              ).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedByproductName = value;
                                  print(
                                      "value : $value and selectedByproductName : $selectedByproductName");
                                  //updateInfo(); // 품목 선택 시 갱신
                                });
                              },
                            ),

                            /*
                            const SizedBox(height: 16),
                            const Text('지역 선택'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: selectedProvince,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              hint: const Text("지역을 선택하세요"),
                              items: widget.provinces.map((province) {
                                return DropdownMenuItem(
                                    value: province, child: Text(province));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedProvince = value;
                                  //updateInfo(); // 지역 선택 시 갱신
                                });
                              },
                            ),*/
                          ],

                          const SizedBox(height: 35),
                          // Current weight input
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: _currentWeightController,
                              decoration: InputDecoration(
                                hintText: '현재 임계치: xxKG',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[400]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[400]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[600]!,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),



                          // Weight modification button
                          OutlinedButton(
                            onPressed: () async {
                              // Handle button press
                              print('무게 수정 버튼 클릭됨');
                              String inputText = _currentWeightController.text;
                              int? weightValue = int.tryParse(inputText);



                              bool result = await setThreshold(weightValue);
                              // 2. 결과에 따라 상태 변경
                              if (result) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('무게가 수정되었습니다'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(color: Colors.grey[600]!),
                              backgroundColor: Colors.white,
                            ),
                            child: Text(
                              '무게 수정 (버튼)',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // Spacer
                          SizedBox(height: 120),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),


      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }



  Widget buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '임계 설정',
        ),
      ],
    );
  }

}

