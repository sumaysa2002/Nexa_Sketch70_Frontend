part of 'task_cubit.dart';

sealed class TaskState { const TaskState(); }

final class ProjectInitial extends TaskState {}

final class ProjectLoading extends TaskState {}

final class ProjectError extends TaskState {
  final String error;
  const ProjectError(this.error);
}

/// สร้างโครงการสำเร็จ
final class CreateProjectSuccess extends TaskState {
  final ProjectModel project;
  const CreateProjectSuccess(this.project);
}

/// ดึงโครงการทั้งหมดสำเร็จ
final class GetProjectsSuccess extends TaskState {
  final List<ProjectModel> projects;
  const GetProjectsSuccess(this.projects);
}

/// อัปเดทโครงการสำเร็จ
final class UpdateProjectSuccess extends TaskState {
  final ProjectModel project;
  const UpdateProjectSuccess(this.project);
}

/// ลบโครงการสำเร็จ
final class DeleteProjectSuccess extends TaskState {
  final int projectId;
  const DeleteProjectSuccess(this.projectId);
}

/// ลบโครงการไม่ได้ (offline)
final class DeleteProjectOfflineError extends TaskState {}
