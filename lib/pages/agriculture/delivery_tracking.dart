import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:brownskin_app/common/constants.dart';
import 'dart:ui' as ui;

class DeliveryTrackingPage extends StatefulWidget {
  final String token;
  final int deliveryId;
  
  const DeliveryTrackingPage({
    super.key,
    required this.token,
    required this.deliveryId,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;
  
  // 배송 상태
  DeliveryStatus _currentStatus = DeliveryStatus.accepted;
  bool _isExpanded = false;

  // 배송 위치 리스트
  List<LatLng> _sortedLocations = [];

  // 지도 관련
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // 배송 정보
  DeliveryInfo? _deliveryInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _initializeTracking() {
    _fetchDeliveryInfo();
    _startLocationTracking();
  }

  // 배송 정보 초기 로드
  Future<void> _fetchDeliveryInfo() async {
    String url = "$BASE_URL/api/track-delivery?id=${widget.deliveryId}";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        DeliveryInfo tempDeliveryInfo = await DeliveryInfo.fromJson(data);
        // `locations`를 timestamp 순으로 정렬
        List<LatLng> sortedLocations = sortLocationsByTimestamp(data['locations']);

        // 마지막 위치를 tempDeliveryInfo의 location으로 설정
        if (sortedLocations.isNotEmpty) {
          tempDeliveryInfo.transporterLocation = sortedLocations.last;
        }

        setState(() {
          _deliveryInfo = tempDeliveryInfo;
          _sortedLocations = sortedLocations;
          _currentStatus = _deliveryInfo!.status;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('배송 정보 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  // 주기적으로 배송 위치 업데이트
  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateDeliveryLocation();
    });
  }

  Future<void> _updateDeliveryLocation() async {
    /*
    try {
      final response = await http.get(
        Uri.parse('https://your-api.com/delivery/${widget.deliveryId}/location'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newLocation = LatLng(
          data['latitude'].toDouble(),
          data['longitude'].toDouble(),
        );
        
        setState(() {
          _currentLocation = newLocation;
          _currentStatus = DeliveryStatus.values.firstWhere(
            (status) => status.name == data['status'],
            orElse: () => _currentStatus,
          );
          _updateMarkers();
          _updatePolylines();
        });
        
        // 지도 카메라 이동
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(newLocation),
        );
      }
    } catch (e) {
      print('위치 업데이트 실패: $e');
    }
    */
  }

  Future<void> _updateMarkers() async {
    final BitmapDescriptor transporterIcon = await createCustomMarkerBitmap(
        backgroundColor: Colors.orange[600]!,
        iconData: Icons.local_shipping,
        label: '유통사');
    final BitmapDescriptor disposerIcon = await createCustomMarkerBitmap(
        backgroundColor: Colors.green[600]!,
        iconData: Icons.eco,
        label: '배출사');
    final BitmapDescriptor preprocessorIcon = await createCustomMarkerBitmap(
        backgroundColor: Colors.brown[600]!,
        iconData: Icons.settings,
        label: '전처리사');
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('transporter_location'),
          position: _deliveryInfo!.transporterLocation,
          icon: transporterIcon,
        ),
        if (_deliveryInfo != null) ...[
          Marker(
            markerId: const MarkerId('disposer_location'),
            position: _deliveryInfo!.disposerLocation,
            icon: disposerIcon,
          ),
          Marker(
            markerId: const MarkerId('preprocessor_location'),
            position: _deliveryInfo!.preprocessorLocation,
            icon: preprocessorIcon,
          ),
        ],
      };
    });
  }

  void _updatePolylines() {
    final polyline = Polyline(
      polylineId: PolylineId('previous_route'),
      color: Colors.orange,
      width: 5,
      points: _sortedLocations,
    );
    final polyline2 = Polyline(
      polylineId: PolylineId('expected_route'),
      color: Colors.blue,
      width: 5,
      points: [
        _deliveryInfo!.transporterLocation,  // 출발지
        _currentStatus==DeliveryStatus.transit
            ? _deliveryInfo!.preprocessorLocation  // 전처리사 이동 중
            : _deliveryInfo!.disposerLocation,  // 배출사 이동 중
      ],
    );

    setState(() {
      _polylines = {polyline, polyline2};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('실시간 추적 - 배송 번호 #${widget.deliveryId}'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 배송 상태 섹션
                _buildDeliveryStatusSection(),
                // 지도 섹션
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _updateMarkers();
                      _updatePolylines();
                    },
                    initialCameraPosition: CameraPosition(
                      target: _deliveryInfo!.transporterLocation,
                      zoom: 14.0,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDeliveryStatusSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 현재 상태 표시
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentStatus.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentStatus.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentStatus.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  ),
                ),
              ],
            ),
          ),
          // 상세 정보 (확장 가능)
          if (_isExpanded) _buildDetailedInfo(),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          _buildStatusTimeline(),
          const SizedBox(height: 16),
          if (_deliveryInfo != null) _buildDeliveryDetails(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: DeliveryStatus.values.map((status) {
        final isCompleted = status.index <= _currentStatus.index;
        final isCurrent = status == _currentStatus;
        
        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? status.color : Colors.grey[300],
                shape: BoxShape.circle,
                border: isCurrent ? Border.all(color: status.color, width: 3) : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  status.displayName,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDeliveryDetails() {
    return Column(
      children: [
        const Divider(),
        _buildInfoRow('타입/이름', "${_deliveryInfo!.byprodType} / ${_deliveryInfo!.byprodName}"),
        _buildInfoRow('무게', "${_deliveryInfo!.byprodWeight} kg"),
        _buildInfoRow('요청 날짜', _deliveryInfo!.reqDate),
        _buildInfoRow('수거지', _deliveryInfo!.disposerAddress),
        _buildInfoRow('배송지', _deliveryInfo!.preprocessorAddress),
        _buildInfoRow('배송 업체', _deliveryInfo!.transporterName),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// 배송 상태 enum
enum DeliveryStatus {
  accepted('수락됨', '배송 요청이 수락되었습니다', Colors.orange),
  //pickupInProgress('수거 이동 중', '수거지로 이동 중입니다', Colors.purple),
  transit('전처리사 이동 중', '전처리사로 이동 중입니다', Colors.blue),
  //outForDelivery('배송 중', '최종 배송지로 이동 중입니다', Colors.teal),
  delivered('배송 완료', '배송이 완료되었습니다', Colors.green);

  const DeliveryStatus(this.displayName, this.description, this.color);
  
  final String displayName;
  final String description;
  final Color color;
}

// 주소로부터 위도/경도를 가져오는 함수
Future<LatLng> getLatLngFromAddress(String addr1, String addr2) async {
  print("🔍 getLatLngFromAddress(): $addr1 $addr2");

  final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/address.json?query=${addr1 + addr2}'
  );

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'KakaoAK 75acb2a58d477b9c94d5c3e61790980b'
    },
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body['documents'].isEmpty) {
      print("⚠️ 주소 결과 없음: $addr1 $addr2");
      print("⚠️ Province '$addr1 $addr2' 마커 생성 실패");
      return LatLng(0, 0);
    }
    final doc = body['documents'][0];
    print("✅ 좌표 결과: ${doc['y']}, ${doc['x']}");
    return LatLng(
      double.parse(doc['y']),
      double.parse(doc['x']),
    );
  } else {
    print("❌ API 호출 실패: ${response.statusCode}");
    throw Exception('API 호출 실패: ${response.statusCode}');
  }
}

// 위치 정보 파싱 및 정렬 함수
List<LatLng> sortLocationsByTimestamp(List<dynamic> jsonList) {
  // timestamp 순으로 정렬하고 LatLng 객체로 변환
  List<LocationPoint> locations = jsonList
      .map((json) => LocationPoint.fromJson(json))
      .toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));  // timestamp 순 정렬

  print("🔍 sortLocationsByTimestamp(): ${locations.length} locations sorted by timestamp");

  // LatLng 리스트로 변환
  List<LatLng> latLngList = locations.map((loc) => LatLng(loc.lat, loc.lng)).toList();

  // 로그로 LatLng 리스트 출력 (위도/경도만)
  for (final loc in latLngList) {
    print("📍 LatLng: ${loc.latitude}, ${loc.longitude}");
  }

  return latLngList;
}

// 배송 정보 모델
class DeliveryInfo {
  final int id;
  final String disposerAddress;
  final String preprocessorAddress;
  final LatLng disposerLocation;
  LatLng transporterLocation;
  final LatLng preprocessorLocation;
  final String transporterName;
  final String byprodType;
  final String byprodName;
  final double byprodWeight;
  final String reqDate;
  DeliveryStatus status;

  DeliveryInfo({
    required this.id,
    required this.disposerAddress,
    required this.preprocessorAddress,
    required this.disposerLocation,
    required this.transporterLocation,
    required this.preprocessorLocation,
    required this.transporterName,
    required this.byprodType,
    required this.byprodName,
    required this.byprodWeight,
    required this.reqDate,
    required this.status,
  });

  static Future<DeliveryInfo> fromJson(Map<String, dynamic> json) async {
    return DeliveryInfo(
      id: json['id'].toInt(),
      disposerAddress: "${json['disposer']['addr1']} ${json['disposer']['addr2']}",
      preprocessorAddress: "${json['preprocessor']['addr1']} ${json['preprocessor']['addr2']}",
      disposerLocation: await getLatLngFromAddress(json['disposer']['addr1'], json['disposer']['addr2']),
      //transporterLocation: await getLatLngFromAddress(json['transporter']['addr1'], json['transporter']['addr2']),
      transporterLocation: LatLng(37.4979, 127.0276), // placeholder
      preprocessorLocation: await getLatLngFromAddress(json['preprocessor']['addr1'], json['preprocessor']['addr2']),
      transporterName: json['transporter']['company_name'],
      byprodType: json['type'],
      byprodName: json['name'],
      byprodWeight: json['weight_float'].toDouble(),
      reqDate: json['req_date'],
      status: DeliveryStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DeliveryStatus.accepted,
      ),
    );
  }
}
// 위치 정보 모델
class LocationPoint {
  final int id;
  final double lat;
  final double lng;
  final DateTime timestamp;

  LocationPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'],
      lat: json['lat'],
      lng: json['lng'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  LatLng toLatLng() => LatLng(lat, lng);
}

// 마커 위젯을 생성하고 BitmapDescriptor로 변환하는 함수
Future<BitmapDescriptor> createCustomMarkerBitmap({
  required Color backgroundColor,
  required IconData iconData,
  required String label,
  Size size = const Size(150, 105), // 기본 크기 설정
}) async {
  // Canvas와 PictureRecorder 초기화
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);

  // 배경 그리기
  final Paint paint = Paint()..color = backgroundColor;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(24)
    ),
    paint
  );

  // 테두리 추가
  final Paint borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(24)
    ),
    borderPaint
  );

  // 아이콘 그리기
  final TextPainter iconPainter = TextPainter(
    textDirection: TextDirection.ltr
  );

  iconPainter.text = TextSpan(
    text: String.fromCharCode(iconData.codePoint),
    style: TextStyle(
      fontSize: 48,
      fontFamily: iconData.fontFamily,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      package: iconData.fontPackage,
    ),
  );

  iconPainter.layout();
  iconPainter.paint(
    canvas,
    Offset(
      (size.width - iconPainter.width) / 2,
      size.height * 0.2
    )
  );

  // 텍스트 그리기
  final TextPainter textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  textPainter.text = TextSpan(
    text: label,
    style: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );

  textPainter.layout(maxWidth: size.width - 10);
  textPainter.paint(
    canvas,
    Offset(
      (size.width - textPainter.width) / 2,
      size.height * 0.65
    )
  );

  // 이미지로 변환
  final img = await pictureRecorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );

  final data = await img.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}