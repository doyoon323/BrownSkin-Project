import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import '../../service/location_service.dart';
import 'admin_data_provider.dart';
import 'global.dart';
import 'package:collection/collection.dart';

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






  Stream<Marker> updateDistrictMarkers({
    required String selectedType,
    required String? selectedByproductName,
    required double threshold,
    required Set<Marker> existingMarkers,
    required void Function(LatLng) onTap,
    required AdminData adminData,
  }) async* {
    final stopwatch = Stopwatch()..start();
    //print("[Update] Start updateDistrictMarkers()");
    //print("[Update] selectedType=$selectedType, selectedByproductName=$selectedByproductName");

    for (final province in allAreas.keys) {
      //print("[Update] Loading weight data for province=$province");
      final weightData = await adminData.getWeightData(
        selectedType,
        selectedByproductName,
        province,
        null,
      );
      //print("[Update] province=$province, raw result=${weightData['results']}");

      final districtWeightMap = weightData['results'] as Map<String, dynamic>?;

      // ✅ weight 데이터가 없으면 dummy 마커 생성
      if (districtWeightMap == null || districtWeightMap.isEmpty) {
        //print("[Update] province=$province has no district data. Creating dummy markers...");

        for (final district in allAreas[province] ?? []) {
          final markerId = MarkerId("$province $district");
          final latLng = await getLatLngFromAddress(province, district);
          if (latLng.latitude == 0 && latLng.longitude == 0) continue;

          double percent = threshold <= 0 ? 0.0 : (0.0 / threshold).clamp(0.0, 1.0);
          List<Color> colors = threshold <= 0
              ? [Colors.grey, Colors.grey]
              : getGradientColorsByPercentage(percent);

          final icon = await createCustomMarkerBitmap(
            province: district,
            label: "0",
            colorStart: colors[0],
            colorEnd: colors[1],
            percentage: percent,
          );

          yield Marker(
            markerId: markerId,
            position: latLng,
            icon: icon,
            zIndex: 0.0,
            anchor: Offset(0.5, 0.5),
            onTap: () => onTap(latLng),
          );
          //print("[Update] Dummy marker yielded for $province $district");
        }

        continue; // 다음 province로 이동
      }

      //print("[Update] province=$province district count=${districtWeightMap.length}");

      for (final district in districtWeightMap.keys) {
        final markerId = MarkerId("$province $district");
        //print("[Update] Processing $province $district");


        final existing = existingMarkers.firstWhereOrNull(
              (m) => m.markerId == markerId,
        );

        double newWeight = (districtWeightMap[district] as num?)?.toDouble() ?? 0.0;

        if (existing != null) {
          //print("[Update] Existing marker weight=${existing.zIndex}, new weight=$newWeight");
        } else {
          //print("[Update] No existing marker");
        }

        //print("[Debug][Check] province=$province, district=$district, weight(raw)=${districtWeightMap[district]}");
        //print("[Debug][Check] markerLabel=${newWeight.toInt()}, zIndex=$newWeight");

        bool shouldRebuild = true;
        if (existing != null) {
          final oldWeight = existing.zIndex;
          if ((oldWeight - newWeight).abs() < 0.01) {
            shouldRebuild = false;
            //print("[Update] Skipping rebuild: weight change insignificant");
          }
        }

        if (!shouldRebuild) continue;

        final latLng = await getLatLngFromAddress(province, district);
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          //print("[Update] Skipping $province $district: invalid LatLng");
          continue;
        }

        double percent = threshold <= 0 ? 0.0 : (newWeight / threshold).clamp(0.0, 1.0);
        List<Color> colors = threshold <= 0
            ? [Colors.grey, Colors.grey]
            : getGradientColorsByPercentage(percent);

        final icon = await createCustomMarkerBitmap(
          province: district,
          label: "${newWeight.toInt()}",
          colorStart: colors[0],
          colorEnd: colors[1],
          percentage: percent,
        );

        //print("[Update] Yielding new marker for $province $district weight=$newWeight");
        yield Marker(
          markerId: markerId,
          position: latLng,
          icon: icon,
          zIndex: newWeight,
          anchor: Offset(0.5, 0.5),
          onTap: () => onTap(latLng),
        );
      }
    }

    stopwatch.stop();
    print("✅ updateDistrictMarkers 완료 (${stopwatch.elapsedMilliseconds} ms)");
  }

  /// 구에 해당하는 모든 마커를 생성하는 함수
  Future<Set<Marker>> generateDistrictMarkers({
    required String province,
    required Map<String, dynamic> districtWeightData,
    required double threshold,
    required Set<Marker> existingMarkers,
    required void Function(LatLng) onTap,
  }) async {
    final stopwatch = Stopwatch()..start();
    Set<Marker> markers = {};
    for (var district in allAreas[province]!) {
      final markerId = MarkerId("$province $district");

      if (existingMarkers.any((m) => m.markerId == markerId)) {
        continue;
      }

      try {
        LatLng latLng = await getLatLngFromAddress(province, district);
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          continue;
        }

        double weight = districtWeightData.containsKey(district)
            ? (districtWeightData[district] as num).toDouble()
            : 0.0;

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
        print("⚠️ getLatLngFromAddress 실패: $e");
        continue;
      }
    }
    stopwatch.stop();
    print("✅ generateDistrictMarkers($province) 완료 (${stopwatch.elapsedMilliseconds} ms, 새 마커 ${markers.length}개)");
    return markers;
  }



  Future<Set<Marker>> generateSpecificDistrictMarkers({
    required String province,
    required List<String> districts,
    required Map<String, dynamic> districtWeightData,
    required double threshold,
    required void Function(LatLng) onTap,
  }) async {
    final Set<Marker> markers = {};

    //print("😆😆geenrateSpecifictDistrict : $province $districts");
    //print("😆😆data is : $districtWeightData");


    for (final district in districts) {
      final markerId = MarkerId("$province $district");
      final double weight = (districtWeightData[district] as num?)?.toDouble() ?? 0.0;
      //print("😆 new marker - markerId=$markerId, weihght : $weight ");


      final LatLng latLng = await getLatLngFromAddress(province, district);
      if (latLng.latitude == 0 && latLng.longitude == 0) {
        continue;
      }

      final double percent = threshold <= 0 ? 0.0 : (weight / threshold).clamp(0.0, 1.0);
      final List<Color> color = threshold <= 0
          ? [Colors.grey, Colors.grey]
          : getGradientColorsByPercentage(percent);

      final icon = await createCustomMarkerBitmap(
        province: district,
        label: "${weight.toInt()}",
        colorStart: color[0],
        colorEnd: color[1],
        percentage: percent,
      );

      markers.add(
        Marker(
          markerId: markerId,
          position: latLng,
          icon: icon,
          zIndex: weight,
          anchor: Offset(0.5, 0.5),
          onTap: () => onTap(latLng),
        ),
      );
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