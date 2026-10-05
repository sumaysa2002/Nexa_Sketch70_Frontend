import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

class Wexport {

  /// ── เซฟไฟล์ ToGallery ──────────────────
  static Future<bool> saveToGallery({
      required Uint8List bytes,
      required String filename,
      required String extension,
  }) async {
    try {

      // สร้างไฟล์ชั่วคราวในโฟลเดอร์
      final tempDir = await getTemporaryDirectory();
      final temppath = '${tempDir.path}/$filename.$extension';
      final file = File(temppath);
      await file.writeAsBytes(bytes);

      // album
      await Gal.putImage(
        temppath,
        album: 'Drawing',
      );

      // ลบไฟล์ชั่วคราวทิ้ง
      await file.delete();

      return true;
    } catch (e) {
      debugPrint('Save to gallery error: $e');
      return false;
    }
  }
}

  enum ExportType {
    png,
    jpeg,
  }

  String exportExtension(ExportType type) {
    switch (type) {
      case ExportType.png:
        return 'png';
      case ExportType.jpeg:
        return 'jpeg';
    }
  }

  String normalizeFileName(String name, String extension) {
    final cleanName = name.trim().isEmpty ? 'export' : name.trim();

    if (cleanName.toLowerCase().endsWith('.$extension')) {
      return cleanName.substring(0, cleanName.length - extension.length - 1);
    }

    return cleanName;
  }

  Future<Uint8List?> buildExportBytes(
      ExportType type,
      Future<Uint8List?> Function(String format) getBytes,
      ) async {
    switch (type) {
      case ExportType.png:
      case ExportType.jpeg:
        return await getBytes(exportExtension(type));
    }
  }