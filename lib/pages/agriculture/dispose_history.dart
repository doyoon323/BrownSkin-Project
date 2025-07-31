import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/api_service.dart';
import '../../common/constants.dart';
import '../../common/widgets.dart';

class HistoryPage extends StatefulWidget {
  final String type;
  final String name;
  final String token;
  final Future<bool> Function(String title, String type, String name, bool isAbandoned) onAddWeightDialog;
  final Color cardBrown;
  final Color lightbackgroundBrown;

  const HistoryPage({
    super.key,
    required this.type,
    required this.name,
    required this.token,
    required this.onAddWeightDialog,
    required this.cardBrown,
    required this.lightbackgroundBrown,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    final result = await getHistoryData(widget.type, widget.name, widget.token);
    setState(() {
      history = result;
      isLoading = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.cardBrown,
      appBar: _buildAppBar(),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : buildHistoryList(widget.name, history),
      bottomNavigationBar: _buildButtons(),
      );
  }


  PreferredSizeWidget _buildAppBar(){
    return AppBar(
        backgroundColor: widget.cardBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('${widget.name} 내역', style: const TextStyle(color: Colors.black)
        ));
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ActionButtonGroup(
        expanded: true,
        spacing: const EdgeInsets.only(right: 12),
        buttons: [
          ActionButtonData(
            label: "부산물 폐기",
            onPressed: () async {
              final added = await widget.onAddWeightDialog("부산물 폐기 등록", widget.type, widget.name, true);
              if (added) fetchHistory();
            },
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: widget.lightbackgroundBrown),
              foregroundColor: widget.lightbackgroundBrown,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
          ActionButtonData(
            label: "부산물 추가",
            onPressed: () async {
              final added = await widget.onAddWeightDialog("부산물 무게 추가", widget.type, widget.name, false);
              if (added) fetchHistory();
            },
            backgroundColor: widget.lightbackgroundBrown,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: widget.lightbackgroundBrown,
              foregroundColor: widget.cardBrown,
            ),
          ),
        ],
      ),
    );
  }
}


Map<String, List<Map<String, dynamic>>> cachedHistory = {};
Map<String, DateTime> lastFetchHistory = {};

Future<List<Map<String, dynamic>>> getHistoryData(String type, String name, String token) async {
  final key = "$type $name";
  final now = DateTime.now();
  final lastFetch = lastFetchHistory[key] ?? now.subtract(const Duration(days: 30));
  final fetchFrom = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(lastFetch);
  final url = '$BASE_URL/api/dispose-history?type=$type&name=$name&fetch_from=$fetchFrom';

  final response = await ApiService.fetchList(url: url, token: token);

  final newData = response.map((entry) {
    final statusMap = {"disposed": "추가", "abondoned": "폐기"};
    final status = statusMap[entry['status']] ?? "수거";

    return {
      'type': entry['type'],
      'name': entry['name'],
      'weight_diff_float': entry['weight_diff_float'],
      'current_weight_float': entry['current_weight_float'],
      'status': status,
      'timestamp': entry['timestamp'].substring(0, 10),
      'timestampFull': entry['timestamp'],
    };
  }).toList();

  if (newData.isNotEmpty) {
    newData.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    lastFetchHistory[key] = DateTime.parse(newData.first['timestamp']);
  } else {
    lastFetchHistory[key] = now;
  }

  cachedHistory[key] ??= [];
  final existingKeys = cachedHistory[key]!.map((e) => "${e['timestampFull']}_${e['type']}_${e['name']}").toSet();
  final uniqueNewData = newData.where((e) => !existingKeys.contains("${e['timestampFull']}_${e['type']}_${e['name']}"),);

  cachedHistory[key] = [...uniqueNewData, ...cachedHistory[key]!]
      .where((e) => DateTime.parse(e['timestamp']).isAfter(now.subtract(const Duration(days: 30)))).toList();
  return cachedHistory[key]!;
}

Widget buildHistoryList(String name, List<Map<String, dynamic>> history) {
  final latestWeight = history.isNotEmpty ? history.first["current_weight_float"] : 0.0;

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$name 부산물", style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 14),
        Text("${latestWeight.toStringAsFixed(1)} $weight_unit", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.separated(
            key: ValueKey(history.length),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final e = history[index];
              final weightDiff = e["weight_diff_float"] as num;
              final color = weightDiff > 0 ? Colors.black87 : const Color(0xFFED2939);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e["status"], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(e["timestamp"], style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} $weight_unit",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${(e["current_weight_float"] as num).toStringAsFixed(1)} $weight_unit",
                          style: TextStyle(fontSize: 13, color: Colors.brown[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}