import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:brownskin_app/constants.dart';
import 'package:percent_indicator/percent_indicator.dart';

class PreprocessorHomePage extends StatefulWidget {
  final String token;
  const PreprocessorHomePage({super.key, required this.token});

  @override
  State<PreprocessorHomePage> createState() => _PreprocessorHomePageState();
}

class _PreprocessorHomePageState extends State<PreprocessorHomePage> {
  List<Map<String, dynamic>> receivedItems = [];
  List<Map<String, dynamic>> processingItems = [];
  List<Map<String, dynamic>> completedItems = [];
  bool isChartViewCompleted = false;

  // 갈색 테마 색상 정의
  static const Color primaryBrown = Color(0xFF8D6E63);
  static const Color lightBrown = Color(0xFFBCAAA4);
  static const Color darkBrown = Color(0xFF5D4037);
  static const Color accentBrown = Color(0xFFD7CCC8);
  static const Color backgroundBrown = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    fetchPreprocessItems();
  }

  Future<void> fetchPreprocessItems() async {
    final headers = {"Authorization": "Token ${widget.token}"};
    try {
      final pendingRes = await http.get(
        Uri.parse('$BASE_URL/api/my-preprocess?status=pending'),
        headers: headers,
      );
      final acceptedRes = await http.get(
        Uri.parse('$BASE_URL/api/my-preprocess?status=accepted'),
        headers: headers,
      );
      final completedRes = await http.get(
        Uri.parse('$BASE_URL/api/my-preprocess?status=completed'),
        headers: headers,
      );

      if (pendingRes.statusCode == 200 &&
          acceptedRes.statusCode == 200 &&
          completedRes.statusCode == 200) {
        setState(() {
          receivedItems =
              (jsonDecode(pendingRes.body)['results'] as List).cast<Map<String, dynamic>>();
          processingItems =
              (jsonDecode(acceptedRes.body)['results'] as List).cast<Map<String, dynamic>>();
          completedItems =
              (jsonDecode(completedRes.body)['results'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // 필요시 예외 처리
    }
  }

  Future<void> _startProcessing(Map<String, dynamic> item) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final startDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final completeDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      final body = {
        "id": item['id'].toString(),
        "start_date": startDate,
        "expected_complete_date": completeDate,
      };

      final response = await http.post(
        Uri.parse('$BASE_URL/api/accept-preprocess'),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPreprocessItems();
      }
    }
  }

  Future<void> _completeProcessing(Map<String, dynamic> item) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: Theme.of(context).copyWith(
          textTheme: TextTheme(
            titleLarge: TextStyle(color: darkBrown, fontWeight: FontWeight.bold),
            bodyMedium: TextStyle(color: darkBrown),
          ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('최종 무게 입력', style: TextStyle(color: darkBrown, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '최종 무게 (kg)',
              labelStyle: TextStyle(color: primaryBrown),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryBrown, width: 2),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: lightBrown),
              ),
            ),
            cursorColor: primaryBrown,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: lightBrown),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final finalWeight = controller.text.trim();
      final response = await http.post(
        Uri.parse('$BASE_URL/api/complete-preprocess'),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "id": item['id'].toString(),
          "final_weight": finalWeight,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchPreprocessItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundBrown,
        appBar: AppBar(
          title: Text('전처리사 홈', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: primaryBrown,
          elevation: 4,
          shadowColor: darkBrown.withOpacity(0.3),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: fetchPreprocessItems,
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: '입고'),
              Tab(text: '작업중'),
              Tab(text: '작업완료'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildReceivedTab(),
            _buildProcessingTab(),
            _buildCompletedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedTab() {
    return Container(
      color: backgroundBrown,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: receivedItems.map((item) {
          final displayWeight = item['weight_float']?.toString() ?? '정보 없음';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 6,
              shadowColor: darkBrown.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, accentBrown.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: lightBrown.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2, color: primaryBrown, size: 28),
                  ),
                  title: Text(
                    "${item['name']} (${item['type']})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkBrown,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "무게: ${displayWeight}kg\n상태: 입고\n입고일: ${item['req_date']}",
                      style: TextStyle(color: darkBrown.withOpacity(0.7), height: 1.4),
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _startProcessing(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                    ),
                    child: const Text('작업 시작', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProcessingTab() {
    return Container(
      color: backgroundBrown,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: processingItems.map((item) {
          final displayWeight = item['weight_float']?.toString() ?? '정보 없음';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 6,
              shadowColor: darkBrown.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.orange.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings, color: Colors.orange[700], size: 28),
                  ),
                  title: Text(
                    "${item['name']} (${item['type']})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: darkBrown,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "무게: ${displayWeight}kg\n상태: 작업중\n작업시작일: ${item['start_date']}\n예상출고일: ${item['expected_complete_date']}",
                      style: TextStyle(color: darkBrown.withOpacity(0.7), height: 1.4),
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _completeProcessing(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                    ),
                    child: const Text('작업 완료', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompletedTab() {
    return Container(
      color: backgroundBrown,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: darkBrown.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryBrown),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        isChartViewCompleted = !isChartViewCompleted;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: primaryBrown,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      isChartViewCompleted ? '카드 보기' : '그래프 보기',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isChartViewCompleted
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: completedItems.length,
                    itemBuilder: (context, index) {
                      final item = completedItems[index];
                      final double finalWeight =
                          double.tryParse(item['final_weight'].toString()) ?? 0;
                      final double originalWeight =
                          double.tryParse(item['weight_float'].toString()) ?? 1;
                      final double yield =
                          originalWeight > 0 ? (finalWeight / originalWeight) : 0;
                      
                      return Card(
                        elevation: 6,
                        shadowColor: darkBrown.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.green.withOpacity(0.05)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "${item['name']}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: darkBrown,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "(${item['type']})",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: darkBrown.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              CircularPercentIndicator(
                                radius: 45.0,
                                lineWidth: 8.0,
                                percent: yield.clamp(0.0, 1.0),
                                center: Text(
                                  "${(yield * 100).toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: darkBrown,
                                  ),
                                ),
                                progressColor: Colors.green[600],
                                backgroundColor: Colors.grey[200]!,
                                animation: true,
                                animationDuration: 800,
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: accentBrown.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${finalWeight.toStringAsFixed(1)}kg",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: darkBrown,
                                  ),
                                ),
                              ),
                              Text(
                                "${item['complete_date']}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: darkBrown.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: completedItems.map((item) {
                      final double finalWeight =
                          double.tryParse(item['final_weight'].toString()) ?? 0;
                      final double originalWeight =
                          double.tryParse(item['weight_float'].toString()) ?? 1;
                      final double yield =
                          originalWeight > 0 ? (finalWeight / originalWeight * 100) : 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 6,
                          shadowColor: darkBrown.withOpacity(0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.green.withOpacity(0.1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                              ),
                              title: Text(
                                "${item['name']} (${item['type']})",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: darkBrown,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "최종무게: ${finalWeight.toStringAsFixed(1)}kg\n상태: 완료\n작업완료일: ${item['complete_date']}\n수율: ${yield.toStringAsFixed(1)}%",
                                  style: TextStyle(color: darkBrown.withOpacity(0.7), height: 1.4),
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 3,
                                ),
                                child: const Text('출고', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}