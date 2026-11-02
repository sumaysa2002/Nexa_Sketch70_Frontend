import 'package:offline_gnss69_new/export.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  TaskCubit() : super(ProjectInitial());
  final taskRemoteRepository = TaskRemoteRepository();
  final taskLocalRepository = TaskLocalRepository();

  /// ── ping เช็คว่า backend (API) ตอบสนองไหม ────────────
  Future<bool> _isApiAvailable(String token) async {
    try {
      final result = await taskRemoteRepository.pingApi(token: token);
      return result;
    } catch (_) {
      return false;
    }
  }


  /// ── สร้างโครงการใหม่ ──────────────────────────────────────
  Future<void> createProject({
    required String token,
    String? nameProjectId,
    required String projectName,
    String? projectDetails,
    String? province,
    String? sensor,
    int? gsdNum,
    String? gsdUnit,
    String? surveyMain,
    String? surveySub,
    String? projectStartDate,
    String? projectEndDate,
    String? projectNote,
    List<int> memberIds = const [],
  }) async {
    try {
      emit(ProjectLoading());

      final project = await taskRemoteRepository.createProject(
        token:            token,
        nameProjectId:    nameProjectId,
        projectName:      projectName,
        projectDetails:   projectDetails,
        province:         province,
        sensor:           sensor,
        gsdNum:           gsdNum,
        gsdUnit:          gsdUnit,
        surveyMain:       surveyMain,
        surveySub:        surveySub,
        projectStartDate: projectStartDate,
        projectEndDate:   projectEndDate,
        projectNote:      projectNote,
        memberIds:        memberIds,
      );

      emit(CreateProjectSuccess(project));
    } catch (e) {
      emit(ProjectError(safeErrorMessage(e)));
    }
  }

  /// ── ดึงโครงการทั้งหมด แยกตาม Admin (เรียงจากใหม่ >> เก่า) ────────────────────────────
  Future<void> getAllProjects({required String token}) async {
    try {
      emit(ProjectLoading());
      final projects = await taskRemoteRepository.getProjects(token: token);

      emit(GetProjectsSuccess(projects));
    } catch (e) {
      final authLocal = AuthLocalRepository();
      final currentUser = await authLocal.getUser();
      final adminId = currentUser?.admin != null
          ? int.tryParse(currentUser!.admin!)
          : currentUser?.id;

      final localProjects = await taskLocalRepository.getProjects(adminId: adminId);
      if (localProjects.isNotEmpty) {
        emit(GetProjectsSuccess(localProjects));
      } else {
        emit(ProjectError(safeErrorMessage(e)));
      }
    }
  }

  /// ── อัปเดทข้อมูลโครงการ ────────────
  Future<void> updateProject({
    required String token,
    required int projectId,
    String? nameProjectId,
    required String projectName,
    String? projectDetails,
    String? province,
    String? sensor,
    int? gsdNum,
    String? gsdUnit,
    String? surveyMain,
    String? surveySub,
    String? projectStartDate,
    String? projectEndDate,
    String? projectNote,
    String? userRole,
    List<int> memberIds = const [],
  }) async {
    try {
      emit(ProjectLoading());

      final project = await taskRemoteRepository.updateProject(
        token:            token,
        projectId:        projectId,
        nameProjectId:    nameProjectId,
        projectName:      projectName,
        projectDetails:   projectDetails,
        province:         province,
        sensor:           sensor,
        gsdNum:           gsdNum,
        gsdUnit:          gsdUnit,
        surveyMain:       surveyMain,
        surveySub:        surveySub,
        projectStartDate: projectStartDate,
        projectEndDate:   projectEndDate,
        projectNote:      projectNote,
        userRole:         userRole,
        memberIds:        memberIds,
      );

      emit(UpdateProjectSuccess(project));

      final projects = await taskRemoteRepository.getProjects(token: token);
      emit(GetProjectsSuccess(projects));

    } catch (e) {
      emit(ProjectError(safeErrorMessage(e)));
    }
  }

  /// ── ลบโครงการ ──────────────────────────────────────────────
  Future<void> deleteProject({
    required String token,
    required int projectId,
  }) async {
    emit(ProjectLoading());

    // เช็ค API
    final apiAvailable = await _isApiAvailable(token);

    if (!apiAvailable) {
      emit(DeleteProjectOfflineError());
      return;
    }

    try {
      await taskRemoteRepository.deleteProject(token: token, projectId: projectId);

      // ลบเฉพาะโครงการที่ถูกลบบน server (ห้ามลบโครงการ offline ที่ยังไม่ได้ sync)
      await taskLocalRepository.deleteProject(projectId);

      emit(DeleteProjectSuccess(projectId));

      // reload projects
      final projects = await taskRemoteRepository.getProjects(token: token);
      emit(GetProjectsSuccess(projects));
    } catch (e) {
      emit(ProjectError(safeErrorMessage(e)));
    }
  }


  /* ============================================================
    ส่วนจัดการ sync Projects
  ============================================================ */
  /// ── sync ข้อมูลที่ค้างทั้งหมดขึ้น server (ผ่าน SyncService กัน sync ซ้อนกัน) ────────────
  Future<void> syncProjects({required String token}) async {
    await SyncService.instance.syncAll(token);
  }

  /// ── sync แล้ว reload รายการโครงการ ────────────
  Future<void> syncUpdatedProjects({required String token}) async {
    final result = await SyncService.instance.syncAll(token);
    if (result.synced == 0) return;

    final projects = await taskRemoteRepository.getProjects(token: token);
    emit(GetProjectsSuccess(projects));
  }



}