import 'package:nexa_sketch/export.dart';

/// แปลงเวลาจาก server (ISO8601) เป็นเวลาท้องถิ่น
DateTime? _parseTrashDate(dynamic v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

int _parseInt(dynamic v) => v is num ? v.toInt() : 0;

String? _parseName(dynamic v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

/// ── โครงการที่อยู่ใน "ประวัติการลบ" ──────────────────────────
class DeletedProject {
  final ProjectModel project;
  final DateTime? deletedAt;
  final String? deletedByName;
  final int daysLeft;     // จำนวนวันที่เหลือก่อนถูกลบถาวร
  final int pointCount;   // จำนวนหมุดที่ยังอยู่ในโครงการ

  const DeletedProject({
    required this.project,
    this.deletedAt,
    this.deletedByName,
    this.daysLeft = 0,
    this.pointCount = 0,
  });

  factory DeletedProject.fromJson(Map<String, dynamic> json) => DeletedProject(
    project:       ProjectModel.fromJson(json),
    deletedAt:     _parseTrashDate(json['deleted_at']),
    deletedByName: _parseName(json['deleted_by_name']),
    daysLeft:      _parseInt(json['days_left']),
    pointCount:    _parseInt(json['point_count']),
  );
}

/// ── หมุดรังวัดที่อยู่ใน "ประวัติการลบ" ──────────────────────────
class DeletedPoint {
  final PointModel point;
  final DateTime? deletedAt;
  final String? deletedByName;
  final int daysLeft;

  const DeletedPoint({
    required this.point,
    this.deletedAt,
    this.deletedByName,
    this.daysLeft = 0,
  });

  factory DeletedPoint.fromJson(Map<String, dynamic> json) => DeletedPoint(
    point:         PointModel.fromJson(json),
    deletedAt:     _parseTrashDate(json['deleted_at']),
    deletedByName: _parseName(json['deleted_by_name']),
    daysLeft:      _parseInt(json['days_left']),
  );
}