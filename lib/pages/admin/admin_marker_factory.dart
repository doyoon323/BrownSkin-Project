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
  }) async {
    //print("✅ generateProvinceMarkers() 시작");
    //print("✅ generateProvinceMarkers()에 전달된 provinceWeights: $provinceWeights");
    
    Set<Marker> markers = {};

    for (var province in allAreas.keys) {
      //print("🔍 [$province] 마커 생성 시작");

      // 좌표 조회
      try {
        LatLng latLng = await getLatLngFromAddress(province, "");
        //print("✅ [$province] 좌표: ${latLng.latitude}, ${latLng.longitude}");


        if (latLng.latitude == 0 && latLng.longitude == 0) {
          //print("⚠️ [$province] 유효하지 않은 좌표. 스킵");
          continue;
        }

        // 무게
        double weight = 0.0;
        if (provinceWeights.containsKey(province)) {
          weight = (provinceWeights[province] as num).toDouble();
        }
        //print("✅ [$province] weight: $weight");

        // 퍼센트
        double percent = threshold <= 0
            ? 0.0
            : (weight / threshold).clamp(0.0, 1.0);
        //print("✅ [$province] percent: $percent");

        // 색상
        List<Color> color = threshold <= 0
            ? [Colors.grey, Colors.grey]
            : getGradientColorsByPercentage(percent);
        //print("✅ [$province] color: $color");

        // 마커 비트맵 생성
        final BitmapDescriptor icon = await createCustomMarkerBitmap(
          province: province,
          label: "${weight.toInt()}",
          colorStart: color[0],
          colorEnd: color[1],
          percentage: percent,
        );
        print("✅ 마커 생성: $province weight=$weight label=${weight.toInt()} percent=$percent");

        // 마커 생성
        Marker marker = Marker(
            markerId: MarkerId(province),
            position: latLng,
            icon: icon,
            onTap: () => onTap(latLng)
        );

        markers.add(marker);
        //print("✅ [$province] Marker 추가 완료");

      }
      catch (e) {
        //print("⚠️ getLatLngFromAddress 실패: $e");
        continue; // 다음 province로 넘어가기
      }
    }

    //print("✅ generateProvinceMarkers() 종료 (총 ${markers.length}개)");
    return markers;
  }

  Future<Set<Marker>> generateDistrictMarkers({
    required String province,
    required Map<String, dynamic> districtWeightData,
    required double threshold,
    required void Function(LatLng) onTap,
  }) async {
    Set<Marker> markers = {};

    print("✅ districts 리스트: $districtWeightData");

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

        print("✅$province $district weight 데이터: $weight");
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


  Future<AllMarkers> generateAllMarkers({
    required Map<String, List<String>> allAreas,
    required String selectedType,
    required String? selectedByproductName,
    required double threshold,
    required Future<void> Function(LatLng) provinceOnTap,
    required Future<void> Function(LatLng) districtOnTap,
    required AdminData adminData,
  }) async {
    // 시도 마커 생성
    final provinceWeightData = await adminData.getWeightData(
      selectedType,
      selectedByproductName,
      null,
      null,
    );
    print("🔄 generateAllMarkers() 호출됨: $selectedType, $selectedByproductName");
    print("🔄 generateAllMarkers() 호출됨: $provinceWeightData");


    final provinceMarkers = await generateProvinceMarkers(
      provinceWeights: provinceWeightData,
      threshold: threshold,
      onTap: provinceOnTap,
    );

    // 구 마커 생성
    final districtResults = await Future.wait(
      allAreas.entries.map((entry) async {
        final province = entry.key;
        final districtWeightData = await adminData.getWeightData(
          selectedType,
          selectedByproductName,
          province,
          null,
        );
        return generateDistrictMarkers(
          province: province,
          districtWeightData: districtWeightData,
          threshold: threshold,
          onTap: (latLng) => districtOnTap(latLng),
        );
      }),
    );

    final districtMarkers = districtResults
        .expand((markers) => markers as Iterable<Marker>)
        .toSet();

    return AllMarkers(
      provinceMarkers: provinceMarkers,
      districtMarkers: districtMarkers,
    );
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


    final Offset center = Offset(size / 2, size / 2);
    final double radius = size / 2;

    final Paint backgroundPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          colorStart.withOpacity(1.0),    // 바깥 색
          colorEnd.withOpacity(1.0), // 중심 색
        ],
        [0.0, 1.0],
      );


    // 동그란 원 그리기
    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );


    final String shortProvince =
    province.length > 2 ? province.substring(0, 2) : province;

    // 폰트 크기
    final double baseFontSize = size / 4.2;
    final double provinceFontSize = shortProvince.length >= 5
        ? baseFontSize * 0.8
        : baseFontSize;

    // 텍스트
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

    // 중앙에 여백 확보
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