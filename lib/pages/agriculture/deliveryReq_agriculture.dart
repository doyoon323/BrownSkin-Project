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
      appBar: AppBar(title: const Text('배송 요청')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('부산물 유형 선택:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedType,
              hint: const Text("유형을 선택하세요"),
              isExpanded: true,
              items: widget.userByproduct.keys.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() { selectedType = value; selectedByproduct = null; });
              },
            ),
            const SizedBox(height: 16),
            if (selectedType != null) ...[
              const Text('품목 선택:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedByproduct,
                hint: const Text("품목을 선택하세요"),
                isExpanded: true,
                items: widget.userByproduct[selectedType]!.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text("${item['name']} (남은 무게: ${item['weight_float']}kg)"),
                  );
                }).toList(),
                onChanged: (value) { setState(() { selectedByproduct = value; }); },
              ),
              const SizedBox(height: 16),
              const Text('무게 입력 (kg):'),
              const SizedBox(height: 8),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(), hintText: "예: 100",
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: sendDeliveryRequest,
                child: const Text('수거 요청 보내기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> sendDeliveryRequest() async {
    if (selectedType == null || selectedByproduct == null || weightController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 정보를 입력하세요")),
      );
      return;
    }

    final double? inputWeight = double.tryParse(weightController.text.trim());
    if (inputWeight == null || inputWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("유효한 무게를 입력하세요")),
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
        const SnackBar(content: Text("요청이 성공적으로 전송되었습니다")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("요청 실패: ${response.body}")),
      );
    }
  }
}
