/// ── รูปแบบวันที่ที่ใช้แสดงในแอป ─────────────────────────────────────
/// เก็บ/ส่งขึ้น server เป็น yyyy-MM-dd (isoDate)
/// แสดงบนหน้าจอเป็น dd/MM/yyyy (displayDate)
///
/// หมายเหตุ: ไม่ตั้งชื่อ formatDate เพราะชนกับ package date_format

/// รับ DateTime หรือ String (yyyy-MM-dd / ISO8601) >> 'dd/MM/yyyy'
/// ถ้า null / parse ไม่ได้ >> คืน [fallback]
String displayDate(Object? value, {String fallback = '-'}) {
  final DateTime? d = value is DateTime
      ? value
      : (value is String ? DateTime.tryParse(value) : null);
  if (d == null) return fallback;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

/// DateTime >> 'yyyy-MM-dd' (ค่าที่ใช้บันทึกลงฐานข้อมูล / ส่ง API)
String isoDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}