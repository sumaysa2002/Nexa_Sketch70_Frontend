import 'package:http/http.dart' as http;
import 'package:offline_gnss69_new/export.dart';

class TaskRemoteRepository {

  final taskLocalRepository = TaskLocalRepository();

  /// ── ping เช็คว่า backend (API) ตอบสนองไหม ────────────
  Future<bool> pingApi({required String token}) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.backendUri}/tasks/projects"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }


  /// ── สร้างโครงการใหม่ (admin เท่านั้นที่สร้างได้) ──────────────────────────────────────
  Future<ProjectModel> createProject({
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

    try{
      final res = await http.post(
        Uri.parse("${Constants.backendUri}/tasks/create_project"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'name_project_id':    nameProjectId,
          'project_name':       projectName,
          'project_details':    projectDetails,
          'province':           province,
          'sensor':             sensor,
          'gsd_num':            gsdNum,
          'gsd_unit':           gsdUnit,
          'survey_main':        surveyMain,
          'survey_sub':         surveySub,
          'project_start_date': projectStartDate,
          'project_end_date':   projectEndDate,
          'project_note':       projectNote,
          'member_ids':         memberIds,
        }),
      );

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'] ?? 'สร้างโครงการไม่สำเร็จ';
      }

      final project = ProjectModel.fromJson(jsonDecode(res.body));

      // cache โครงการที่สร้างสำเร็จ >> ลง SQLite
      await taskLocalRepository.insertProject(project);

      return project;

    } catch (e) {

      try {
        // ถ้า API fail >> บันทึกลง SQLite >> sync ทีหลัง
        final offlineProject = ProjectModel(
          id:                 -DateTime.now().millisecondsSinceEpoch, // temp id
          nameProjectId:      nameProjectId,
          projectName:        projectName,
          projectDetails:     projectDetails,
          province:           province,
          sensor:             sensor,
          gsdNum:             gsdNum,
          gsdUnit:            gsdUnit,
          surveyMain:         surveyMain,
          surveySub:          surveySub,
          projectStartDate:   projectStartDate,
          projectEndDate:     projectEndDate,
          projectNote:        projectNote,
          memberIds:          memberIds,
          projectTimeCreated: DateTime.now().toIso8601String(),
        );

        await taskLocalRepository.insertProject(offlineProject, isSynced: 1);
        return offlineProject;
      } catch (e) {
        rethrow;
      }
    }
  }


  /// ── ดึงโครงการทั้งหมด แยกตาม Admin (เรียงจากใหม่ >> เก่า) ────────────────────────────
  Future<List<ProjectModel>> getProjects({required String token}) async {
    try {
      // sync โครงการที่ค้างก่อน
      await syncProjects(token: token);

      final res = await http.get(
        Uri.parse("${Constants.backendUri}/tasks/projects"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'ดึงข้อมูลโครงการไม่สำเร็จ';
      }

      final List<dynamic> data = jsonDecode(res.body);
      final projects = data.map((e) => ProjectModel.fromJson(e)).toList();

      await taskLocalRepository.upsertProjects(projects);

      return projects;
    } catch (e) {
      final localProjects = await taskLocalRepository.getProjects();
      return localProjects;
    }
  }


  /// ── อัปเดทข้อมูลโครงการ ────────────
  Future<ProjectModel> updateProject({
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

      final res = await http.put(
        Uri.parse("${Constants.backendUri}/tasks/update_project/$projectId"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'name_project_id':    nameProjectId,
          'project_name':       projectName,
          'project_details':    projectDetails,
          'province':           province,
          'sensor':             sensor,
          'gsd_num':            gsdNum,
          'gsd_unit':           gsdUnit,
          'survey_main':        surveyMain,
          'survey_sub':         surveySub,
          'project_start_date': projectStartDate,
          'project_end_date':   projectEndDate,
          'project_note':       projectNote,
          'member_ids':         memberIds,
        }),
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'แก้ไขโครงการไม่สำเร็จ';
      }

      final project = ProjectModel.fromJson(jsonDecode(res.body)).copyWith(
        userRole:  userRole,
        memberIds: memberIds,
      );

      await taskLocalRepository.updateProject(project);

      return project;

    } catch (e) {
      // ดึงข้อมูลจาก SQLite เพื่อเอา projectTimeCreated และ userRole
      final existingProjects = await taskLocalRepository.getProjects();
      final existing = existingProjects.where((p) => p.id == projectId).firstOrNull;

      // ถ้า API fail >> บันทึกลง SQLite >> sync ทีหลัง
      final offlineProject = ProjectModel(
        id:               projectId,
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
        userRole:         userRole ?? existing?.userRole,
        projectTimeCreated: existing?.projectTimeCreated,
      );
      await taskLocalRepository.updateProjectPending(offlineProject);
      return offlineProject;
    }
  }


  /// ── ลบโครงการ (admin เท่านั้นที่ลบได้) >> ใช้ id project ในการลบ ────────────
  Future<void> deleteProject({
    required String token,
    required int projectId,
  }) async {
    final res = await http.delete(
      Uri.parse("${Constants.backendUri}/tasks/delete_project/$projectId"),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
    );

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)['error'] ?? 'ลบโครงการไม่สำเร็จ';
    }
  }


  /* ============================================================
    ส่วนจัดการ sync Projects
  ============================================================ */
  /// ── sync โครงการที่สร้างขณะ offline ขึ้น server ────────────────────────────
  Future<bool> syncProjects({required String token}) async {
    try {

      // ดึงโครงการที่ยังไม่ได้ sync
      final unsyncedProjects = await taskLocalRepository.getUnsyncedProjects();
      if (unsyncedProjects.isEmpty) return true;

      // แปลงเป็น List<Map> แล้วส่งทีเดียวทั้ง array
      final projectListInMap = unsyncedProjects.map((p) => p.toJson()).toList();

      final res = await http.post(
        Uri.parse("${Constants.backendUri}/tasks/sync_projects"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(projectListInMap),
      );

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'];
      }

      for (final project in unsyncedProjects) {
        await taskLocalRepository.deleteProject(project.id);
      }

      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('syncProjects error: $e');
      return false;
    }
  }


  /// ── sync โครงการที่แก้ไขขณะ offline ขึ้น server ────────────────────────────
  Future<bool> syncUpdatedProjects({required String token}) async {
    try {
      final pendingProjects = await taskLocalRepository.getUpdatedPendingProjects();
      if (pendingProjects.isEmpty) return true;

      for (final project in pendingProjects) {
        try {
          final res = await http.put(
            Uri.parse("${Constants.backendUri}/tasks/update_project/${project.id}"),
            headers: {
              'Content-Type': 'application/json',
              'x-auth-token': token,
            },
            body: jsonEncode({
              'name_project_id':    project.nameProjectId,
              'project_name':       project.projectName,
              'project_details':    project.projectDetails,
              'province':           project.province,
              'sensor':             project.sensor,
              'gsd_num':            project.gsdNum,
              'gsd_unit':           project.gsdUnit,
              'survey_main':        project.surveyMain,
              'survey_sub':         project.surveySub,
              'project_start_date': project.projectStartDate,
              'project_end_date':   project.projectEndDate,
              'project_note':       project.projectNote,
              'member_ids':         project.memberIds,
            }),
          );

          if (res.statusCode == 200) {
            // sync สำเร็จ >> is_updated_pending = 0
            await taskLocalRepository.markUpdateSynced(project.id);
          }
        } catch (_) {
          continue;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

}