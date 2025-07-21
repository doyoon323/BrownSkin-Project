import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import '../../service/location_service.dart';
import 'admin_data_provider.dart';
import 'global.dart';

class AdminMarker {
  final String token;

  AdminMarker({required this.token,});


  Future<Marker?> _createMarker({
    required String label,
    required String id,
    required LatLng? latLng,
    required double weight,
    required double threshold,
    required void Function(LatLng) onTap,
  }) async {
    if (latLng == null) return null;

    final double percent = threshold <= 0 ? 0.0 : (weight / threshold).clamp(0.0, 1.0);
    final List<Color> colors = threshold <= 0 ? [Colors.grey, Colors.grey] : getGradientColorsByPercentage(percent);

    final icon = await createCustomMarkerBitmap(
      province: label,
      label: "${weight.toInt()}",
      colorStart: colors[0],
      colorEnd: colors[1],
      percentage: percent,
    );

    return Marker(
      markerId: MarkerId(id),
      position: latLng,
      icon: icon,
      zIndex: weight,
      anchor: Offset(0.5, 0.5),
      onTap: () => onTap(latLng),
    );
  }

  Future<Set<Marker>> generateProvinceMarkers({
    required Map<String, dynamic> provinceWeights,
    required double threshold,
    required Future<void> Function(LatLng) onTap,
  }) async {
    final futures = allAreas.keys.map((province) async {
      final latLng = await getLatLngFromAddress(province, "");
      if (latLng == null) return null;

      final weight = (provinceWeights[province] as num?)?.toDouble() ?? 0.0;

      return await _createMarker(
        label: province,
        id: province,
        latLng: latLng,
        weight: weight,
        threshold: threshold,
        onTap: onTap,
      );
    }).toList();

    final results = await Future.wait(futures);
    return results.whereType<Marker>().toSet();
  }


  Stream<Marker> graduallyDistrictMarkers({
    required String selectedType,
    required String? selectedByproductName,
    required double threshold,
    required void Function(LatLng) onTap,
    required AdminData adminData,
  }) async* {
    for (final province in allAreas.keys) {
      final weightData = await adminData.getWeightData(
        selectedType,
        selectedByproductName,
        province,
        null,
      );
      Map<String, dynamic> districtWeightMap = Map<String, dynamic>.from(weightData);
      final districts = allAreas[province] ?? [];

      for (final district in districts) {
        final markerId = "$province $district";
        final newWeight = districtWeightMap[district]?.toDouble() ?? 0.0;
        final latLng = await getLatLngFromAddress(province, district);

        final marker = await _createMarker(
          label: district,
          id: markerId,
          latLng: latLng,
          weight: newWeight,
          threshold: threshold,
          onTap: onTap,
        );

        if (marker != null) yield marker;
      }
    }
  }


  Future<Set<Marker>> generateSpecificDistrictMarkers({
    required String province,
    required List<String> districts,
    required Map<String, dynamic> districtWeightData,
    required double threshold,
    required void Function(LatLng) onTap,
  }) async {
    final markers = <Marker>{};
    for (final district in districts) {
      final markerId = "$province $district";
      final weight = (districtWeightData[district] as num?)?.toDouble() ?? 0.0;
      final latLng = await getLatLngFromAddress(province, district);

      final marker = await _createMarker(
        label: district,
        id: markerId,
        latLng: latLng,
        weight: weight,
        threshold: threshold,
        onTap: onTap,
      );

      if (marker != null) markers.add(marker);
    }
    return markers;
  }


  List<Color> getGradientColorsByPercentage(double percent) {
    int r, g, b;
    if (percent <= 0.5) {
      final ratio = percent / 0.5;
      r = (0 + (249 - 0) * ratio).round();        // R: 0 → 249
      g = (208 + (217 - 208) * ratio).round();    // G: 208 → 217
      b = (98 + (51 - 98) * ratio).round();       // B: 98 → 51

      // 중심색
      final baseColor = Color.fromARGB(255, r, g, b);
      // 테두리색: 중심색보다 약간 밝음
      final lighterR = (r + 10).clamp(0, 255).toInt();
      final lighterG = (g + 10).clamp(0, 255).toInt();
      final lighterB = (b + 10).clamp(0, 255).toInt();

      return [
        baseColor,
        Color.fromARGB(255, lighterR, lighterG, lighterB),
      ];
    } else {
      final ratio = (percent - 0.5) / 0.5;
      r = (249 + (244 - 249) * ratio).round();    // R: 249 → 244
      g = (217 + (68 - 217) * ratio).round();     // G: 217 → 68
      b = (51 + (68 - 51) * ratio).round();       // B: 51 → 68

      final baseColor = Color.fromARGB(255, r, g, b);

      final lighterR = (r + 10).clamp(0, 255).toInt();
      final lighterG = (g + 10).clamp(0, 255).toInt();
      final lighterB = (b + 10).clamp(0, 255).toInt();

      return [
        baseColor,
        Color.fromARGB(255, lighterR, lighterG, lighterB),
      ];
    }
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap({
    required String province,
    required String label,
    required Color colorStart,
    required Color colorEnd,
    required double percentage,
  }) async {
    // 마커 크기 범위
    const double minSize = 120;
    const double maxSize = 140;

    // 비율에 따라 크기 결정
    final double size = minSize + percentage * (maxSize - minSize);

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Padding 확보
    const double padding = 12.0;

    // 중심 좌표
    final Offset center = Offset(size / 2, size / 2);
    final double radius = (size / 2) - padding;

    // (1) 테두리 색 결정
    final borderColor = Color.fromARGB(
      255,
      (colorStart.red - 20).clamp(0, 255),
      (colorStart.green - 20).clamp(0, 255),
      (colorStart.blue - 20).clamp(0, 255),
    );

    // (2) 테두리 Paint
    final Paint borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = 9.0;

    // (3) 테두리 먼저 그리기
    canvas.drawCircle(
      center,
      radius,
      borderPaint,
    );

    // (4) 배경 원 그리기
    final Paint backgroundPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          colorStart.withOpacity(1.0),
          colorEnd.withOpacity(1.0),
        ],
        [0.0, 1.0],
      );

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    // 텍스트 처리
    final String shortProvince =
    province.length > 2 ? province.substring(0, 2) : province;

    final double baseFontSize = size / 4.2;
    final double provinceFontSize = shortProvince.length >= 5 ? baseFontSize * 0.8 : baseFontSize;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      children: [
        TextSpan(
          text: "$shortProvince\n",
          style: TextStyle(
            fontSize: provinceFontSize,
            color: const Color(0xFFF2F2F2),
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        TextSpan(
          text: "$label",
          style: TextStyle(
            fontSize: baseFontSize,
            color: const Color(0xFFF2F2F2),
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size * 0.85,
    );
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + 4,
      ),
    );
    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}