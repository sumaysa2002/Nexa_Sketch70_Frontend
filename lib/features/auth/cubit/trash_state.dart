part of 'trash_cubit.dart';

sealed class TrashState { const TrashState(); }

final class TrashInitial extends TrashState {}

final class TrashLoading extends TrashState {}

/// โหลดรายการไม่สำเร็จ (offline = true >> ติดต่อ server ไม่ได้)
final class TrashLoadFailed extends TrashState {
  final String message;
  final bool offline;
  const TrashLoadFailed(this.message, {this.offline = false});
}

/* ============================================================
    โครงการ
  ============================================================ */
/// รายการโครงการที่ถูกลบ
final class DeletedProjectsLoaded extends TrashState {
  final List<DeletedProject> items;
  const DeletedProjectsLoaded(this.items);
}

/// หมุดภายในโครงการที่ถูกลบ
final class DeletedProjectPointsLoaded extends TrashState {
  final List<PointModel> points;
  const DeletedProjectPointsLoaded(this.points);
}

/// กู้คืนโครงการสำเร็จ
final class RestoreProjectSuccess extends TrashState {
  final int projectId;
  const RestoreProjectSuccess(this.projectId);
}

/* ============================================================
    หมุดรังวัด
  ============================================================ */
/// หมุดที่ถูกลบของโครงการ (ลบหมุด ไม่ลบโครงการ)
final class DeletedPointsLoaded extends TrashState {
  final List<DeletedPoint> items;
  const DeletedPointsLoaded(this.items);
}

/// กู้คืนหมุดรังวัดสำเร็จ
final class RestorePointSuccess extends TrashState {
  final int pointId;
  const RestorePointSuccess(this.pointId);
}

/// กู้คืนไม่สำเร็จ (ทั้งโครงการและหมุดรังวัด)
final class RestoreFailed extends TrashState {
  final String message;
  const RestoreFailed(this.message);
}

/* ============================================================
    ลบถาวร (ก่อนครบ 30 วัน)
  ============================================================ */
/// ลบถาวรสำเร็จ
final class PurgeSuccess extends TrashState {
  final int count; // จำนวนรายการที่ถูกลบ
  const PurgeSuccess(this.count);
}

/// ลบถาวรไม่สำเร็จ
final class PurgeFailed extends TrashState {
  final String message;
  const PurgeFailed(this.message);
}