import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/constants.dart';

class DeliveryReqAgriculturePage extends StatefulWidget {
  final String token;
  final Map<String, List<Map<String, dynamic>>> userByproduct;

  const DeliveryReqAgriculturePage({required this.token, required this.userByproduct, super.key});

  @override
  State<DeliveryReqAgriculturePage> createState() => _DeliveryReqAgriculturePageState();
}

class _DeliveryReqAgriculturePageState extends State<DeliveryReqAgriculturePage> {
  String? selectedType;
  Map<String, dynamic>? selectedByproduct;
  final TextEditingController weightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text(
          '배송 요청',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.brown[50]!,
              Colors.brown[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '부산물 유형 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        hint: Text(
                          "유형을 선택하세요",
                          style: TextStyle(color: Colors.brown[400]),
                        ),
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        dropdownColor: Colors.brown[50],
                        items: widget.userByproduct.keys.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              style: TextStyle(color: Colors.brown[700]),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                            selectedByproduct = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (selectedType != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '품목 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.brown[300]!),
                        ),
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          value: selectedByproduct,
                          hint: Text(
                            "품목을 선택하세요",
                            style: TextStyle(color: Colors.brown[400]),
                          ),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          dropdownColor: Colors.brown[50],
                          items: widget.userByproduct[selectedType]!.map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(
                                "${item['name']} (남은 무게: ${item['weight_float']}kg)",
                                style: TextStyle(color: Colors.brown[700]),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedByproduct = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '무게 입력 (kg)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.brown[700]),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.brown[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.brown[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.brown[600]!, width: 2),
                          ),
                          hintText: "예: 100",
                          hintStyle: TextStyle(color: Colors.brown[400]),
                          filled: true,
                          fillColor: Colors.brown[25],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: sendDeliveryRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[600],
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.brown.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '수거 요청 보내기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> sendDeliveryRequest() async {
    if (selectedType == null || selectedByproduct == null || weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("모든 정보를 입력하세요"),
          backgroundColor: Colors.brown[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final double? inputWeight = double.tryParse(weightController.text.trim());
    if (inputWeight == null || inputWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("유효한 무게를 입력하세요"),
          backgroundColor: Colors.brown[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final url = Uri.parse('$BASE_URL/api/dispose-req');
    final response = await http.post(url, headers: {
      "Authorization": "Token ${widget.token}",
      "Content-Type": "application/x-www-form-urlencoded",
    }, body: {
      "type": selectedType!,
      "name": selectedByproduct!["name"],
      "weight": weightController.text.trim(),
    });

    if (response.statusCode >= 200 && response.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("요청이 성공적으로 전송되었습니다"),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("요청 실패: ${response.body}"),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}