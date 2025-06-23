import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:brownskin_app/model/ByProduct.dart';
import 'dart:async';


//관리자 홈 화면 (부산물 데이터를 시각화하여 보여준다)
class AdminHomePage extends StatefulWidget {
  /* 인증 토큰을 매개변수로 받아 저장 */
  final String token;
  const AdminHomePage({required this.token, super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with TickerProviderStateMixin {

  List<ByProduct> data = []; //전체 데이터
  List<String> usernames = []; // 사용자 이름 추출
  List<double> weights = []; // 무게 추출

  //UI 구성
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 최초 페이지 로딩 시 데이터 불러오기
    getData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

/* 서버에서 데이터를 받아오는 함수 */
  Future<void> getData() async {
    /* 로딩 상태로 UI 갱신 */
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      /* 첫 페이지 URL */
      String? nextUrl = "http://10.0.2.2:8000/api/byprod-list?page=1";
      List<ByProduct> allData = [];

      /* 페이지 순회하며 모든 데이터를 받아옴 */
      while (nextUrl != null) {
        var result = await http.get(
          Uri.parse(nextUrl),
          headers: {
            /* 현재는 관리자 token을 직접 입력한 상태 (추후 DB 또는 로그인 기반 동적 처리 예정) */
            'Authorization': 'Token 1320615697a307cd25763951e3fe5b4a7e2364b6',
          },
        );

        /* 서버 인증 성공 시 */
        if (result.statusCode == 200) {
          final body = jsonDecode(utf8.decode(result.bodyBytes));
          final List<dynamic> results = body['results'];

          try {
            /* JSON 데이터를 모델 객체로 변환하여 리스트에 추가 */
            allData.addAll(results.map((item) => ByProduct.fromJson(item)));
          } catch (e) {
            print('파싱 오류: $e');
            throw Exception('데이터 파싱 중 오류가 발생했습니다.');
          }

          /* 다음 페이지 URL 설정 (없으면 null) */
          nextUrl = body['next'] as String?;
        } else {
          throw Exception('서버 오류: ${result.statusCode}');
        }
      }

      /* 정렬 및 데이터 상태 업데이트 */
      usernames = allData.map((e) => e.username).toList();
      weights = allData.map((e) => e.weight).toList();
      allData.sort((a, b) => a.company_name.compareTo(b.company_name));

      setState(() {
        data = allData;
        isLoading = false;
      });

      /* UI 실행 */
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }



/* UI */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      /* 상단 AppBar (제목 + 새로고침 버튼) */
      appBar: AppBar(
        title: const Text(
          '무게 데이터 관리',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),

            /* 새로고침 시 데이터 재요청 */
            onPressed: getData,
          ),
        ],
      ),

      /* 본문 : 로딩/에러/정상 UI 분기 처리 */
      body: isLoading
          ? _buildLoadingWidget()
          : errorMessage != null
          ? _buildErrorWidget()
          : _buildMainContent(),

      /* 하단  */
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }


/* 데이터 로딩 중 표시되는 위젯 */
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
          ),
          SizedBox(height: 16),
          Text(
            '데이터를 불러오는 중...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /* 오류 발생 시 표시되는 위젯 */
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? '알 수 없는 오류가 발생했습니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: getData,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  /* 데이터 시각화 메인 콘텐츠 위젯 */
  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCards(), // 통계 요약
            const SizedBox(height: 24),
            _buildChartCard(), // 무게 분포
            const SizedBox(height: 24),
            _buildDataTable(), // 상세 데이터 테이블
          ],
        ),
      ),
    );
  }


/* 통계 카드 레이아웃  */
  Widget _buildStatsCards() {
    final totalItems = data.length;
    final aboveThreshold = data.where((item) => item.is_above_threshold).length;
    final averageWeight = data.isEmpty
        ? 0.0
        : data.map((e) => e.weight).reduce((a, b) => a + b) / data.length;
    final maxWeight = data.isEmpty ? 0.0 : data.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '총 항목',
            totalItems.toString(),
            Icons.inventory,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '임계값 초과',
            aboveThreshold.toString(),
            Icons.warning,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '평균 무게',
            '${averageWeight.toStringAsFixed(1)}kg',
            Icons.scale,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '최대 무게',
            '${maxWeight.toStringAsFixed(1)}kg',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }


  /* 통계 카드(총 개수, 임계값 초과, 평균/최대 무게 등 요약) */
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /* 무게 분포 차트 UI */
  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 8),
              Text(
                '무게 분포 차트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem('정상', Colors.blue[400]!),
              const SizedBox(width: 16),
              _buildLegendItem('임계값 초과', Colors.red[400]!),
              const SizedBox(width: 16),
              _buildLegendItem('임계선', Colors.orange[600]!),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: _buildChart(data),
          ),
        ],
      ),
    );
  }


  /* 차트 범례용 아이템 위젯 */
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }


  /* 무게 데이터 시각화 막대 차트 */
  Widget _buildChart(List<ByProduct> data) {
    // 임계값 설정 (필요에 따라 조정 가능)
    final double thresholdValue = 150.0;

    final barGroups = data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.weight,
            color: item.is_above_threshold
                ? Colors.red[400]
                : Colors.blue[400],
            width: 20,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: item.is_above_threshold
                  ? [Colors.red[300]!, Colors.red[500]!]
                  : [Colors.blue[300]!, Colors.blue[500]!],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          )
        ],
      );
    }).toList();

    final xLabels = data.map((e) => e.username).toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 250,
        minY: 0,
        barGroups: barGroups,
        // 임계선 추가
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: thresholdValue,
              color: Colors.orange[600]!,
              strokeWidth: 2,
              dashArray: [8, 4], // 점선 효과
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                labelResolver: (line) => '임계값: ${thresholdValue.toInt()}kg',
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${value.toInt()}kg',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      index >= 0 && index < xLabels.length ? xLabels[index] : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  /* 사용자별 무게 데이터 테이블 */
  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Colors.indigo[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  '상세 데이터',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              columns: const [
                DataColumn(label: Text('사용자명', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('회사명', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('무게 (kg)', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('상태', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: data.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text(item.username)),
                    DataCell(Text(item.company_name)),
                    DataCell(Text(item.weight.toStringAsFixed(1))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.is_above_threshold
                              ? Colors.red[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.is_above_threshold ? '초과' : '정상',
                          style: TextStyle(
                            color: item.is_above_threshold
                                ? Colors.red[700]
                                : Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /* 하단 네비게이션 바 (UI만 구현) */
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
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

