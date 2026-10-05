part of 'point_task_cubit.dart';

sealed class PointTaskState { const PointTaskState(); }

final class PointTaskInitial extends PointTaskState {}

final class PointTaskLoading extends PointTaskState {}

final class PointTaskError extends PointTaskState {
  final String error;
  const PointTaskError(this.error);
}

/// สร้าง Point สำเร็จ
final class CreatePointSuccess extends PointTaskState {
  final PointModel point;
  const CreatePointSuccess(this.point);
}

/// ดึง Point ทั้งหมดสำเร็จ
final class GetPointsSuccess extends PointTaskState {
  final List<PointModel> points;
  const GetPointsSuccess(this.points);
}

/// Update point
final class UpdatePointSuccess extends PointTaskState {
  final PointModel point;
  const UpdatePointSuccess(this.point);
}

/// ลบ Point สำเร็จ
final class DeletePointSuccess extends PointTaskState {
  final int pointId;
  const DeletePointSuccess(this.pointId);
}

/// สร้าง Point ไม่ได้ (offline)
final class CreatePointOfflineError extends PointTaskState {}

/// แก้ไข Point ไม่ได้ (offline)
final class UpdatePointOfflineError extends PointTaskState {}

/// ลบ Point ไม่ได้ (offline)
final class DeletePointOfflineError extends PointTaskState {}