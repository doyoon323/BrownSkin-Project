import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import '../../service/location_service.dart';
import 'admin_data_provider.dart';
import 'global.dart';

class AllMarkers {
  final Set<Marker> provinceMarkers;
  final Set<Marker> districtMarkers;

  AllMarkers({
    required this.provinceMarkers,
    required this.districtMarkers,
  });
}

class AdminMarker {
  final String token;

  AdminMarker({
    required this.token,
  });


  Future<Set<Marker>> generateProvinceMarkers({
    required Map<String, dynamic> provinceWeights,
    required double threshold,
    required Future<void> Function(LatLng) onTap,
  })
  async {
    print("✅ generateProvinceMarkers() 병렬 처리 시작");
    final stopwatch = Stopwatch()..start();

    // 병렬 Future 리스트
    final futures = allAreas.keys.map((province) async {
      final itemStopwatch = Stopwatch()..start();
      try {
        // 좌표 가져오기 (-> 추후 서버에 위치정보 저장하여 api의 호출 수를 줄이는 방안으로 최적화 필요)
        LatLng latLng = await getLatLngFromAddress(province, "");
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          print("⚠️ [$province] 좌표 없음 (skip)");
          return null;
        }

        // weight 계산
        double weight = provinceWeights.containsKey(province)
            ? (provinceWeights[province] as num).toDouble()
            : 0.0;

        double percent = threshold <= 0
            ? 0.0
            : (weight / threshold).clamp(0.0, 1.0);

        List<Color> color = threshold <= 0
            ? [Colors.grey, Colors.grey]
            : getGradientColorsByPercentage(percent);

        // 비트맵 생성
        final BitmapDescriptor icon = await createCustomMarkerBitmap(
          province: province,
          label: "${weight.toInt()}",
          colorStart: color[0],
          colorEnd: color[1],
          percentage: percent,
        );

        Marker marker = Marker(
          markerId: MarkerId(province),
          position: latLng,
          icon: icon,
          zIndex: weight,
          anchor: Offset(0.5, 0.5),
          onTap: () => onTap(latLng),
        );

        print("✅ [$province] 마커 생성 완료 (${itemStopwatch.elapsed.inMilliseconds} ms)");
        return marker;
      } catch (e) {
        print("⚠️ [$province] 에러: $e (${itemStopwatch.elapsed.inMilliseconds} ms)");
        return null;
      }
    }).toList();

    final results = await Future.wait(futures);
    final markers = results.whereType<Marker>().toSet();

    print("🎉 generateProvinceMarkers() 총 소요 시간: ${stopwatch.elapsed.inMilliseconds} ms (마커 ${markers.length}개)");
    return markers;
  }


  Future<Set<Marker>> generateDistrictMarkers({
    required String province,
    required Map<String, dynamic> districtWeightData,
    required double threshold,
    required void Function(LatLng) onTap,
    required AdminData adminData,
  }) async {
    Set<Marker> markers = {};

    //print("✅ districts 리스트: $districtWeightData");

    for (var district in allAreas[province]!) {
      try {
        LatLng latLng = await getLatLngFromAddress(province, district);
        //print("✅ LatLng for $province $district: ${latLng.latitude}, ${latLng.longitude}");
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          continue;
        }

        double weight = districtWeightData.containsKey(district)
            ? (districtWeightData[district] as num).toDouble()
            : 0.0;

        //print("✅ weight 데이터: $weight");
        //print("✅ 최종 weight: $weight");

        double percent = threshold <= 0
            ? 0.0
            : (weight / threshold).clamp(0.0, 1.0);

        List<Color> color = threshold <= 0
            ? [Colors.grey, Colors.grey]
            : getGradientColorsByPercentage(percent);

        final BitmapDescriptor icon = await createCustomMarkerBitmap(
          province: district,
          label: "${weight.toInt()}",
          colorStart: color[0],
          colorEnd: color[1],
          percentage: percent,
        );

        Marker marker = Marker(
          markerId: MarkerId("$province $district"),
          position: latLng,
          icon: icon,
          zIndex: weight,
          anchor: Offset(0.5, 0.5), // 중심 anchoring!
          onTap: () {
            onTap(latLng);
          },
        );

        markers.add(marker);
      } catch (e) {
        //print("⚠️ getLatLngFromAddress 실패: $e");
        continue;
      }
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
    // padding 고려해서 radius 줄임
    final double radius = (size / 2) - padding;

    // (1) 테두리 색 결정
    final borderColor = Color.fromARGB(
      255,
      (colorStart.red - 20).clamp(0, 255),
      (colorStart.green - 20).clamp(0, 255),
      (colorStart.blue - 20).clamp(0, 255),
    );

    // (2) 테두리 Paint
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;

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
    final double provinceFontSize = shortProvince.length >= 5
        ? baseFontSize * 0.8
        : baseFontSize;

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

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}