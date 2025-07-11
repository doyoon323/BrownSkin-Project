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

  AdminMarker({required this.token});

  Future<Set<Marker>> generateProvinceMarkers({
    required Map<String, dynamic> provinceWeights,
    required double threshold,
    required Future<void> Function(LatLng) onTap,
  }) async {
    Set<Marker> markers = {};

    for (var province in allAreas.keys) {
      try {
        LatLng latLng = await getLatLngFromAddress(province, "");
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          continue;
        }

        double weight = (provinceWeights[province] as num?)?.toDouble() ?? 0.0;
        double percent = threshold <= 0 ? 0.0 : (weight / threshold).clamp(0.0, 1.0);

        List<Color> color = threshold <= 0
            ? [Colors.grey, Colors.grey]
            : getGradientColorsByPercentage(percent);

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
          zIndex: weight, // 중요도에 따라 위로
          onTap: () => onTap(latLng),
        );

        markers.add(marker);
      } catch (e) {
        continue;
      }
    }
    return markers;
  }

  Future<Set<Marker>> generateDistrictMarkers({
    required String province,
    required Map<String, dynamic> districtWeightData,
    required double threshold,
    required void Function(LatLng) onTap,
  }) async {
    Set<Marker> markers = {};

    for (var district in allAreas[province]!) {
      try {
        LatLng latLng = await getLatLngFromAddress(province, district);
        if (latLng.latitude == 0 && latLng.longitude == 0) {
          continue;
        }

        double weight = (districtWeightData[district] as num?)?.toDouble() ?? 0.0;
        double percent = threshold <= 0 ? 0.0 : (weight / threshold).clamp(0.0, 1.0);

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
          zIndex: weight, // 중요도에 따라 위로
          onTap: () => onTap(latLng),
        );

        markers.add(marker);
      } catch (e) {
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
    final provinceWeightData = await adminData.getWeightData(
      selectedType,
      selectedByproductName,
      null,
      null,
    );

    final provinceMarkers = await generateProvinceMarkers(
      provinceWeights: provinceWeightData,
      threshold: threshold,
      onTap: provinceOnTap,
    );

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

    final districtMarkers = districtResults.expand((m) => m).toSet();

    return AllMarkers(
      provinceMarkers: provinceMarkers,
      districtMarkers: districtMarkers,
    );
  }

  List<Color> getGradientColorsByPercentage(double percent) {
    int r, g, b;
    if (percent <= 0.5) {
      final ratio = percent / 0.5;
      r = (0 + (249 - 0) * ratio).round();
      g = (208 + (217 - 208) * ratio).round();
      b = (98 + (51 - 98) * ratio).round();
    } else {
      final ratio = (percent - 0.5) / 0.5;
      r = (249 + (244 - 249) * ratio).round();
      g = (217 + (68 - 217) * ratio).round();
      b = (51 + (68 - 51) * ratio).round();
    }
    final base = Color.fromARGB(255, r, g, b);
    return [
      base,
      Color.fromARGB(
        255,
        (r + 10).clamp(0, 255).toInt(),
        (g + 10).clamp(0, 255).toInt(),
        (b + 10).clamp(0, 255).toInt(),
      ),
    ];
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap({
    required String province,
    required String label,
    required Color colorStart,
    required Color colorEnd,
    required double percentage,
  }) async {
    const double minSize = 120;
    const double maxSize = 140;
    final double size = minSize + percentage * (maxSize - minSize);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Offset center = Offset(size / 2, size / 2);
    final double radius = size / 2;

    final Paint paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          colorStart.withOpacity(1.0),
          colorEnd.withOpacity(1.0),
        ],
        [0.0, 1.0],
      );

    canvas.drawCircle(center, radius, paint);

    final String shortProvince = province.length > 2 ? province.substring(0, 2) : province;
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
            color: Colors.white,
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        TextSpan(
          text: label,
          style: TextStyle(
            fontSize: baseFontSize,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    );

    textPainter.layout(
      maxWidth: size * 0.85,
    );

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + 4,
      ),
    );

    final img = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}