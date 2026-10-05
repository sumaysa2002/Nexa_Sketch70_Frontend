import 'dart:io';
import 'package:flutter/material.dart';
import 'package:offline_gnss69_new/export.dart';

/// ── แสดงรูปของ point ไม่ว่าจะเป็น filename จาก server หรือ local path ──────────────────
Widget buildPointImage(
    String? value, {
      required int projectId,
      required int pointId,
      BoxFit fit = BoxFit.cover,
    }) {
  if (value == null || value.trim().isEmpty) {
    return _placeholder();
  }

  /// ── รูปที่ยังไม่ sync — อ่านจากไฟล์ในเครื่อง ──────────────────
  if (value.startsWith('local://')) {
    final path = value.replaceFirst('local://', '');
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  /// ── รูปที่ sync แล้ว — อ่านจาก server ──────────────────
  final url = '${Constants.backendUri}/uploads/point/$projectId/$pointId/$value';
  return Image.network(
    url,
    fit: fit,
    errorBuilder: (_, __, ___) => _placeholder(),
  );
}

Widget _placeholder() => Container(
  color: Colors.grey.shade100,
  child: const Center(
    child: Icon(Icons.photo_outlined, size: 36, color: Colors.grey),
  ),
);