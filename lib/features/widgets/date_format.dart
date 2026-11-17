/// รับ DateTime หรือ String (yyyy-MM-dd / ISO8601) >> 'dd/MM/yyyy'
String displayDate(Object? value, {String fallback = '-'}) {
  final DateTime? d = value is DateTime
      ? value
      : (value is String ? DateTime.tryParse(value) : null);
  if (d == null) return fallback; // ถ้า null / parse ไม่ได้ >> คืน [fallback]
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

/// DateTime >> 'yyyy-MM-dd' (ค่าที่ใช้บันทึกลงฐานข้อมูล / ส่ง API)
String isoDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}