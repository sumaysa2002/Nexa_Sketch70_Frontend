import 'package:offline_gnss69_new/export.dart';

/// ── จัดการรูปภาพของ Point ที่สร้างแบบ Offline และยังไม่ได้ Sync ขึ้น Server (โครงสร้าง: {AppDocuments}/pending_points/{pointId}/{fieldName}.jpg) ────────
class PendingPointImageService {

  // ── คืน path โฟลเดอร์ของ point ตาม id (ใช้ id ติดลบตอนสร้าง offline) ──
  Future<Directory> _pointDir(int pointId) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/pending_points/$pointId');
    // ถ้ายังไม่มีโฟลเดอร์ >> สร้าง
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ── บันทึกรูป 1 field ลงเครื่อง คืนค่าเป็น path พร้อม prefix "local://" ──
  Future<String> saveImage({
    required int pointId,
    required String fieldName,
    required Uint8List bytes,
  }) async {
    final dir = await _pointDir(pointId);
    final file = File('${dir.path}/$fieldName.jpg'); // สร้างชื่อไฟล์ภาพ

    // evict cache >> ป้องกัน Image.file โชว์รูปเก่าที่ cache ไว้
    await FileImage(file).evict();

    await file.writeAsBytes(bytes, flush: true);

    // evict cache >> กันกรณี cache ถูกสร้างขึ้นแทรกระหว่างเขียน
    await FileImage(file).evict();

    return 'local://${file.path}';
  }

  // ── บันทึกหลายรูปพร้อมกัน (คืนค่าเป็น Map<fieldName, 'local://...'> เฉพาะ field ที่มีรูปจริง) ──────────
  Future<Map<String, String>> saveImages({
    required int pointId,
    required Map<String, Uint8List?> images,
  }) async {
    final result = <String, String>{};
    for (final entry in images.entries) {
      if (entry.value == null) continue;
      result[entry.key] = await saveImage(
        pointId: pointId,
        fieldName: entry.key,
        bytes: entry.value!,
      );
    }
    return result;
  }

  // ── เช็คว่า string เป็น local path หรือไม่ ──────────────────────
  bool isLocalPath(String? value) => value != null && value.startsWith('local://');

  // ── แปลง 'local://...' เป็น path จริงสำหรับ File() ────────────────
  String stripPrefix(String localPath) => localPath.replaceFirst('local://', '');

  // ── อ่าน bytes กลับจาก local path (ใช้ตอน sync ขึ้น server) ─────
  Future<Uint8List?> readBytes(String? value) async {
    if (value == null || !isLocalPath(value)) return null;
    final file = File(stripPrefix(value));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  // ── ลบโฟลเดอร์รูปทั้งหมดของ point (หลัง sync สำเร็จ หรือลบ point) ──
  Future<void> deletePointFolder(int pointId) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${baseDir.path}/pending_points/$pointId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  // ── ย้ายโฟลเดอร์ตอน point ได้ id จริงจาก server (ปกติไม่ต้องใช้เพราะ sync แล้วลบทิ้งเลย) ──
  Future<void> renamePointFolder({
    required int oldId,
    required int newId,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final oldDir = Directory('${baseDir.path}/pending_points/$oldId');
    final newDir = Directory('${baseDir.path}/pending_points/$newId');
    if (await oldDir.exists()) {
      if (await newDir.exists()) await newDir.delete(recursive: true);
      await oldDir.rename(newDir.path);
    }
  }
}