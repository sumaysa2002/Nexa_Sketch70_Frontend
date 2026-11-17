import 'package:nexa_sketch/export.dart';

part 'trash_state.dart';

/// ── ประวัติการลบ / กู้คืน โครงการและหมุดรังวัด ──────────────────────
class TrashCubit extends Cubit<TrashState> {
  TrashCubit() : super(TrashInitial());

  final _repo = TrashRemoteRepository();

  void _emit(TrashState s) {
    if (!isClosed) emit(s);
  }

  TrashLoadFailed _loadFailed(Object e, String fallback) => TrashLoadFailed(
    safeErrorMessage(e, fallback: fallback),
    offline: e is TrashOfflineException,
  );

  /* ============================================================
    โครงการ
  ============================================================ */
  /// ── รายการโครงการที่ถูกลบ ──
  Future<void> loadDeletedProjects({required String token, bool silent = false}) async {
    if (!silent) _emit(TrashLoading());
    try {
      final items = await _repo.getDeletedProjects(token: token);
      _emit(DeletedProjectsLoaded(items));
    } catch (e) {
      _emit(_loadFailed(e, 'ดึงประวัติการลบโครงการไม่สำเร็จ'));
    }
  }

  /// ── หมุดภายในโครงการที่ถูกลบ ──
  Future<void> loadPointsOfDeletedProject({required String token, required int projectId}) async {
    _emit(TrashLoading());
    try {
      final points = await _repo.getPointsOfDeletedProject(token: token, projectId: projectId);
      _emit(DeletedProjectPointsLoaded(points));
    } catch (e) {
      _emit(_loadFailed(e, 'ดึงข้อมูลหมุดรังวัดไม่สำเร็จ'));
    }
  }

  /// ── กู้คืนโครงการ ──
  Future<void> restoreProject({
    required String token,
    required int projectId,
    bool reloadList = true,
  }) async {
    try {
      await _repo.restoreProject(token: token, projectId: projectId);
    } catch (e) {
      _emit(RestoreFailed(safeErrorMessage(e, fallback: 'กู้คืนโครงการไม่สำเร็จ')));
      return;
    }
    _emit(RestoreProjectSuccess(projectId));
    if (reloadList) await loadDeletedProjects(token: token, silent: true);
  }

  /* ============================================================
    หมุดรังวัด
  ============================================================ */
  /// ── หมุดที่ถูกลบของโครงการ (ลบหมุด ไม่ลบโครงการ) ──
  Future<void> loadDeletedPoints({
    required String token,
    required int projectId,
    bool silent = false,
  }) async {
    if (!silent) _emit(TrashLoading());
    try {
      final items = await _repo.getDeletedPoints(token: token, projectId: projectId);
      _emit(DeletedPointsLoaded(items));
    } catch (e) {
      _emit(_loadFailed(e, 'ดึงประวัติการลบหมุดรังวัดไม่สำเร็จ'));
    }
  }

  /// ── กู้คืนหมุดรังวัด ──
  Future<void> restorePoint({
    required String token,
    required int projectId,
    required int pointId,
  }) async {
    try {
      await _repo.restorePoint(token: token, pointId: pointId);
    } catch (e) {
      _emit(RestoreFailed(safeErrorMessage(e, fallback: 'กู้คืนหมุดรังวัดไม่สำเร็จ')));
      return;
    }
    _emit(RestorePointSuccess(pointId));
    await loadDeletedPoints(token: token, projectId: projectId, silent: true);
  }



  /* ============================================================
    ลบถาวร (ก่อนครบ 30 วัน)
  ============================================================ */
  /// ── ลบถาวรโครงการเดียว ──
  Future<void> purgeProject({required String token, required int projectId}) async {
    try {
      final n = await _repo.purgeProject(token: token, projectId: projectId);
      _emit(PurgeSuccess(n));
    } catch (e) {
      _emit(PurgeFailed(safeErrorMessage(e, fallback: 'ลบโครงการแบบถาวรไม่สำเร็จ')));
      return;
    }
    await loadDeletedProjects(token: token, silent: true);
  }

  /// ── ลบถาวรโครงการทั้งหมดในประวัติการลบ ──
  Future<void> purgeAllProjects({required String token}) async {
    try {
      final n = await _repo.purgeAllProjects(token: token);
      _emit(PurgeSuccess(n));
    } catch (e) {
      _emit(PurgeFailed(safeErrorMessage(e, fallback: 'ลบโครงการแบบถาวรไม่สำเร็จ')));
      return;
    }
    await loadDeletedProjects(token: token, silent: true);
  }

  /// ── ลบถาวรหมุดรังวัดเดียว ──
  Future<void> purgePoint({
    required String token,
    required int projectId,
    required int pointId,
  }) async {
    try {
      final n = await _repo.purgePoint(token: token, pointId: pointId);
      _emit(PurgeSuccess(n));
    } catch (e) {
      _emit(PurgeFailed(safeErrorMessage(e, fallback: 'ลบหมุดรังวัดแบบถาวรไม่สำเร็จ')));
      return;
    }
    await loadDeletedPoints(token: token, projectId: projectId, silent: true);
  }

  /// ── ลบถาวรหมุดรังวัดทั้งหมดในประวัติการลบของโครงการ ──
  Future<void> purgeAllPoints({required String token, required int projectId}) async {
    try {
      final n = await _repo.purgeAllPoints(token: token, projectId: projectId);
      _emit(PurgeSuccess(n));
    } catch (e) {
      _emit(PurgeFailed(safeErrorMessage(e, fallback: 'ลบหมุดรังวัดแบบถาวรไม่สำเร็จ')));
      return;
    }
    await loadDeletedPoints(token: token, projectId: projectId, silent: true);
  }
}