import 'dart:async';
import 'dart:math';

import 'package:nexa_sketch/export.dart';

/// ── สร้าง UUID v4 สำหรับใช้เป็น idempotency key (ไม่ต้องเพิ่ม package) ──
String generateClientUuid() {
  final rnd = Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant RFC 4122
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// ── สรุปผลการ sync หนึ่งรอบ ───────────────────────────────────────
class SyncResult {
  int synced = 0;   // ส่งขึ้น server สำเร็จ
  int failed = 0;   // server ตอบ error (บันทึกไว้ใน sync_error แล้ว)
  bool offline = false; // ติดต่อ server ไม่ได้ระหว่าง sync >> หยุดรอบนี้

  void add(SyncResult other) {
    synced += other.synced;
    failed += other.failed;
    offline = offline || other.offline;
  }
}

/// ── จุดเดียวที่ sync ข้อมูล offline ทั้งหมด ──────────────────────
/// ลำดับ: สร้างโครงการ >> แก้โครงการ >> สร้างหมุด >> แก้หมุด
class SyncService with WidgetsBindingObserver {
  SyncService._();
  static final SyncService instance = SyncService._();

  final _syncedController = StreamController<SyncResult>.broadcast();

  /// แจ้งเมื่อ sync แล้วมีข้อมูลขึ้น server อย่างน้อย 1 รายการ (ใช้ให้หน้าจอโหลดข้อมูลใหม่)
  Stream<SyncResult> get onSynced => _syncedController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _started = false;

  Future<SyncResult>? _running;
  bool _rerun = false;
  bool _rerunRetryBlocked = false;

  /// ── เมื่ออินเทอร์เน็ตกลับมา ──
  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.ethernet);
      if (online) _syncWithStoredToken();
    });

    _syncWithStoredToken();
  }

  /// ── กรณีหยุด ─────────────────────
  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncWithStoredToken();
  }

  /// ── sync ด้วย token (logout แล้ว token ว่าง >> ไม่ทำอะไร) ──
  Future<void> _syncWithStoredToken() async {
    try {
      final token = await SpService().getToken();
      if (token == null || token.isEmpty) return;
      await syncAll(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[SyncService] auto sync error: $e');
    }
  }

  /// ── sync ทุกอย่างที่ค้างอยู่ ─────────────────────────────────────
  /// retryBlocked = true >> รวมรายการที่เคยเจอ error ถาวรด้วย (ใช้ตอนผู้ใช้กด sync เอง)
  Future<SyncResult> syncAll(String token, {bool retryBlocked = false}) {
    final running = _running;
    if (running != null) {
      _rerun = true;
      _rerunRetryBlocked = _rerunRetryBlocked || retryBlocked;
      return running;
    }

    final future = _loop(token, retryBlocked).whenComplete(() => _running = null);
    _running = future;
    return future;
  }

  Future<SyncResult> _loop(String token, bool retryBlocked) async {
    final total = SyncResult();
    do {
      _rerun = false;
      final r = await _runOnce(token, retryBlocked);
      total.add(r);
      retryBlocked = _rerunRetryBlocked;
      _rerunRetryBlocked = false;
      if (r.offline) break;
    } while (_rerun);

    // แจ้งหลัง lock ถูกปล่อยแล้ว >> ผู้ฟังเรียก getProjects/getPoints ต่อได้โดยไม่ติด lock
    if (total.synced > 0) {
      Future(() => _syncedController.add(total));
    }
    return total;
  }

  Future<SyncResult> _runOnce(String token, bool retryBlocked) async {
    final result = SyncResult();
    final taskRepo  = TaskRemoteRepository();
    final pointRepo = PointTaskRemoteRepository();

    try {
      final steps = <Future<SyncResult> Function()>[
            () => taskRepo.syncProjects(token: token, includeBlocked: retryBlocked),
            () => taskRepo.syncUpdatedProjects(token: token, includeBlocked: retryBlocked),
            () => pointRepo.syncUnsyncedPoints(token: token, includeBlocked: retryBlocked),
            () => pointRepo.syncUpdatedPendingPoints(token: token, includeBlocked: retryBlocked),
      ];
      for (final step in steps) {
        final r = await step();
        result.add(r);
        if (r.offline) break; // เน็ตหลุดกลางทาง >> ไม่ต้องลองขั้นถัดไป
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[SyncService] sync error: $e');
    }
    return result;
  }

  /// ── รายการที่ sync ไม่ผ่าน (ข้อความพร้อมแสดงผู้ใช้) ─────────────────
  Future<List<String>> describeSyncIssues() async {
    final projects = await TaskLocalRepository().getSyncErrors();
    final points   = await PointTaskLocalRepository().getSyncErrors();
    return [
      for (final r in projects) 'โครงการ "${r['project_name']}": ${r['sync_error']}',
      for (final r in points) 'หมุด "${r['point_name']}": ${r['sync_error']}',
    ];
  }
}