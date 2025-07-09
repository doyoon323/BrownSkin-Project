import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
    /*
    try {
      final response = await http.get(
        Uri.parse('https://your-api.com/delivery/${widget.deliveryId}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _deliveryInfo = DeliveryInfo.fromJson(data);
          _currentStatus = _deliveryInfo!.status;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('배송 정보 로드 실패: $e');
      setState(() => _isLoading = false);
    }
    */
    setState(() {
      _deliveryInfo = DeliveryInfo(
        id: widget.deliveryId,
        disposerAddress: '서울시 강남구 테헤란로 123',
        preprocessorAddress: '서울시 서초구 반포대로 456',
        disposerLocation: const LatLng(37.5665, 126.9780),
        transporterLocation: const LatLng(37.5500, 126.9900),
        preprocessorLocation: const LatLng(37.5700, 126.9900),
        transporterName: '홍길동',
        status: DeliveryStatus.accepted,
      );
      _currentStatus = _deliveryInfo!.status;
      _isLoading = false;
    });
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

  void _updateMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('transporter_location'),
          position: _deliveryInfo!.transporterLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: '배송 차량',
            snippet: _currentStatus.displayName,
          ),
        ),
        if (_deliveryInfo != null) ...[
          Marker(
            markerId: const MarkerId('disposer_location'),
            position: _deliveryInfo!.disposerLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(
              title: '배출사',
              snippet: '부산물 수거 위치',
            ),
          ),
          Marker(
            markerId: const MarkerId('preprocessor_location'),
            position: _deliveryInfo!.preprocessorLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(
              title: '전처리사',
              snippet: '최종 배송 위치',
            ),
          ),
        ],
      };
    });
  }

  void _updatePolylines() {
    final polyline = Polyline(
      polylineId: PolylineId('route_line'),
      color: Colors.blue,
      width: 5,
      points: [
        _deliveryInfo!.transporterLocation,  // 출발지
        _deliveryInfo!.disposerLocation,  // 도착지 (나중에 상태에 따라 배춠사 위치 또는 전처리사 위치로 변경)
      ],
    );

    setState(() {
      _polylines = {polyline};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('배송 추적 - ID #${widget.deliveryId}'),
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
        _buildInfoRow('배송 번호', widget.deliveryId.toString()),
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
  accepted('수락됨', '배송 요청이 수락되었습니다', Colors.blue),
  //pickupInProgress('수거 이동 중', '수거지로 이동 중입니다', Colors.orange),
  transit('전처리사 이동 중', '전처리사로 이동 중입니다', Colors.purple),
  //outForDelivery('배송 중', '최종 배송지로 이동 중입니다', Colors.teal),
  delivered('배송 완료', '배송이 완료되었습니다', Colors.green);

  const DeliveryStatus(this.displayName, this.description, this.color);
  
  final String displayName;
  final String description;
  final Color color;
}

// 배송 정보 모델
class DeliveryInfo {
  final int id;
  final String disposerAddress;
  final String preprocessorAddress;
  final LatLng disposerLocation;
  final LatLng transporterLocation;
  final LatLng preprocessorLocation;
  final String transporterName;
  final DeliveryStatus status;

  DeliveryInfo({
    required this.id,
    required this.disposerAddress,
    required this.preprocessorAddress,
    required this.disposerLocation,
    required this.transporterLocation,
    required this.preprocessorLocation,
    required this.transporterName,
    required this.status,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      id: json['id'].toInt(),
      disposerAddress: json['disposer_address'],
      preprocessorAddress: json['preprocessor_address'],
      disposerLocation: LatLng(
        json['disposer_lat'].toDouble(),
        json['disposer_lng'].toDouble(),
      ),
      transporterLocation: LatLng(
        json['transporter_lat'].toDouble(),
        json['transporter_lng'].toDouble(),
      ),
      preprocessorLocation: LatLng(
        json['preprocessor_lat'].toDouble(),
        json['preprocessor_lng'].toDouble(),
      ),
      transporterName: json['transporter_name'],
      status: DeliveryStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DeliveryStatus.accepted,
      ),
    );
  }
}