import 'package:flutter/material.dart';
import 'package:nexa_sketch/export.dart';
import 'package:proj4dart/proj4dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nexa_sketch/models/point_model.dart';

/// แปลงพิกัด UTM เป็น lat/lng >> รองรับ Datum: 'WGS84, Indian 1975' และ UTM Zone: '47N, 48N'
class UtmMapService {
  static bool _ready = false;

  static void _init() {
    if (_ready) return;
    for (final z in ['47', '48']) {

      // WGS84
      Projection.add(
        'WGS84_$z',
        '+proj=utm +zone=$z +datum=WGS84 +units=m +no_defs',
      );

      // Indian 1975 (Everest 1830) >> WGS84 ตาม EPSG:2404x
      Projection.add(
        'IND75_$z',
        '+proj=utm +zone=$z +a=6377276.345 +b=6356075.41314024 '
            '+towgs84=210,814,289,0,0,0,0 +units=m +no_defs',
      );
    }
    _ready = true;
  }

  /// คืน null ถ้าข้อมูลไม่ครบ ไม่ถูกต้อง
  static ({double lat, double lng})? toLatLng({
    String? northing,
    String? easting,
    String? datum,
    String? utmZone,
  }) {
    final n = double.tryParse((northing ?? '').trim());
    final e = double.tryParse((easting ?? '').trim());
    final zone = (utmZone ?? '').toUpperCase().replaceAll('N', '').trim();
    if (n == null || e == null || (zone != '47' && zone != '48')) return null;

    final prefix = switch ((datum ?? '').trim()) {
      'WGS84' => 'WGS84_',
      'Indian 1975' => 'IND75_',
      _ => null,
    };
    if (prefix == null) return null;

    try {
      _init();
      final r = Projection.get('$prefix$zone')!
          .transform(Projection.WGS84, Point(x: e, y: n));
      final lat = r.y, lng = r.x;
      if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) return null;
      return (lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }

  static Uri mapsUri(double lat, double lng) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

  /// เปิด Google Maps + แจ้งเตือนเมื่อข้อมูลไม่ครบ
  static Future<void> openPointInGoogleMaps(
      BuildContext context,
      PointModel point,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final p = toLatLng(
      northing: point.northing,
      easting: point.easting,
      datum: point.datum,
      utmZone: point.utm,
    );
    if (p == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => alert_image_one_button(
          text: "ข้อมูลพิกัด Northing/Easting/Datum/UTM Zone\nไม่ครบหรือไม่ถูกต้อง",
          assets_image: "assets/images/question.png",
          onPressed: () {
            Navigator.of(context).pop();
          },
          text_button: "ตกลง",
        ),
      );
      return;
    }
    final ok = await launchUrl(
      mapsUri(p.lat, p.lng),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('เปิด Google Maps ไม่สำเร็จ')),
      );
    }
  }
}

/// ปุ่ม "ดูตำแหน่งบน Google Maps"
class Open_In_Map_Button extends StatelessWidget {
  final PointModel point;
  const Open_In_Map_Button({super.key, required this.point});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => UtmMapService.openPointInGoogleMaps(context, point),

        icon: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),

        label: const Text(
          'ดูตำแหน่งบน Google Maps',
          style: const TextStyle(fontFamily: 'NotoSansThai', fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF18181C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}