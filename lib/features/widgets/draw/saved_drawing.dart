import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';
part 'saved_drawing.g.dart';

@HiveType(typeId: 1)
  class SavedDrawing extends HiveObject {
    @HiveField(0)
    String name;

    @HiveField(1)
    Uint8List imageBytes;

    @HiveField(2)
    String format;

    // Draw Data
    @HiveField(3)
    List<Map<String, dynamic>> strokes;

    @HiveField(4)
    List<Map<String, dynamic>>? texts;

    @HiveField(5)
    List<Map<String, dynamic>>? widgetsData;

    @HiveField(6)
    bool? azimuthLayer;
    
    @HiveField(7)
    List<Map<String, dynamic>>? shapes;

    @HiveField(8)
    List<Map<String, dynamic>>? circles;

    @HiveField(9)
    Uint8List? backgroundImageData;

    @HiveField(10)
    List<Map<String, dynamic>>? curves;

    SavedDrawing({
      required this.name,
      required this.imageBytes,
      required this.format,
      required this.strokes,
      this.texts,
      this.widgetsData,
      this.azimuthLayer,
      this.shapes,
      this.circles,
      this.backgroundImageData,
      this.curves,
    });

    /// ── แปลงข้อมูลเวกเตอร์ เป็น JSON string ──────────────────
    String toDrawDataJson() {
      return jsonEncode({
        'strokes': strokes,
        'texts': texts,
        'widgetsData': widgetsData,
        'azimuthLayer': azimuthLayer,
        'shapes': shapes,
        'circles': circles,
        'curves': curves,
        'backgroundImageData': backgroundImageData != null
            ? base64Encode(backgroundImageData!)
            : null,
      });
    }

    /// ── JSON string เป็น SavedDrawing ──────────────────
    static SavedDrawing fromDrawDataJson(String jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return SavedDrawing(
        name: 'restored',
        imageBytes: Uint8List(0),
        format: 'draft',
        strokes: (map['strokes'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        texts: (map['texts'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        widgetsData: (map['widgetsData'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        azimuthLayer: map['azimuthLayer'] as bool?,
        shapes: (map['shapes'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        circles: (map['circles'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        curves: (map['curves'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        backgroundImageData: map['backgroundImageData'] != null
            ? base64Decode(map['backgroundImageData'] as String)
            : null,
      );
    }

}
