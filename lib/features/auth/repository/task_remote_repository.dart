import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:nexa_sketch/export.dart';

/// offline >> server ปลายทางไม่พร้อม (gateway 502/503/504)
class _ServerUnavailableException implements Exception {
  const _ServerUnavailableException();
}

class TaskRemoteRepository {

  /* ============================================================
    Server Error / Time Out
  ============================================================ */
  /// ── error จาก server ─────────────
  static bool _isOfflineError(Object e) =>
      e is SocketException ||
          e is TimeoutException ||
          e is HandshakeException ||
          e is http.ClientException ||
          e is _ServerUnavailableException;

  /// ── ดึงข้อความ error จาก response ──
  static String _errorFrom(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['error'] is String) return body['error'] as String;
    } catch (_) {}
    return fallback;
  }

  /// ── gateway ตอบแทน server ที่ล่ม (502/503/504) >> ถือว่า offline ──
  static http.Response _checkGateway(http.Response res) {
    if (res.statusCode == 502 || res.statusCode == 503 || res.statusCode == 504) {
      throw const _ServerUnavailableException();
    }
    return res;
  }

  static const _timeout     = Duration(seconds: 15);
  static const _syncTimeout = Duration(seconds: 30);



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

    // ผู้สร้างโครงการ (admin)
    final currentUser = await AuthLocalRepository().getUser();

    // // ถ้า server สร้างไปแล้วแต่ response หาย
    final clientUuid = generateClientUuid();

    try {
      final res = await http.post(
        Uri.parse("${Constants.backendUri}/tasks/create_project"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'client_uuid':        clientUuid,

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
      ).timeout(_timeout).then(_checkGateway);

      // ไม่บันทึก offline >> error อื่นจาก server (400 / 401 / 403 / 500)
      if (res.statusCode != 201) {
        throw ServerException(res.statusCode, _errorFrom(res, 'สร้างโครงการไม่สำเร็จ'));
      }

      final project = ProjectModel.fromJson(jsonDecode(res.body)).copyWith(
        memberIds:          memberIds,
        creatorAdminId:     currentUser?.id,
        projectTimeCreated: DateTime.now().toUtc().toIso8601String(),
      );

      // cache ลง SQLite
      try {
        await taskLocalRepository.insertProject(project);
      } catch (e) {
        if (kDebugMode) debugPrint('createProject cache error: $e');
      }

      return project;

    } catch (e) {
      // ไม่ใช่ปัญหาการเชื่อมต่อ >> ส่ง error ต่อให้หน้าจอแสดง
      if (!_isOfflineError(e)) rethrow;

      // ติดต่อ server ไม่ได้ >> บันทึกลง SQLite แล้ว sync ทีหลัง
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
        projectTimeCreated: DateTime.now().toUtc().toIso8601String(),
        creatorAdminId:     currentUser?.id,
        clientUuid:         clientUuid,
      );

      await taskLocalRepository.insertProject(offlineProject, isSynced: 1);
      return offlineProject;
    }
  }


  /// ── ดึงโครงการทั้งหมด แยกตาม Admin (เรียงจากใหม่ >> เก่า) ────────────────────────────
  Future<List<ProjectModel>> getProjects({required String token}) async {
    try {
      // sync ข้อมูลที่ค้างก่อน
      await SyncService.instance.syncAll(token);

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

      // รวมโครงการที่สร้าง แก้ไข ตอน offline
      final pendingCreate = await taskLocalRepository.getUnsyncedProjects(includeBlocked: true);
      final pendingUpdate = {
        for (final p in await taskLocalRepository.getUpdatedPendingProjects(includeBlocked: true)) p.id: p,
      };

      return [
        ...pendingCreate,
        for (final p in projects) pendingUpdate[p.id] ?? p,
      ];
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
    // ข้อมูลเดิมในเครื่อง >> และใช้ตอนบันทึก offline
    final existing = (await taskLocalRepository.getProjects())
        .where((p) => p.id == projectId)
        .firstOrNull;

    ProjectModel buildLocal() => ProjectModel(
      id:                 projectId,
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
      userRole:           userRole ?? existing?.userRole,
      projectTimeCreated: existing?.projectTimeCreated,
      creatorAdminId:     existing?.creatorAdminId,
      clientUuid:         existing?.clientUuid,
    );

    // โครงการที่สร้างตอน offline
    if (projectId < 0) {
      final offlineProject = buildLocal();
      await taskLocalRepository.updateProject(offlineProject, resetSyncError: true);
      return offlineProject;
    }

    try {
      final res = await http.put(
        Uri.parse("${Constants.backendUri}/tasks/update_project/$projectId"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(_updateBody(buildLocal())),
      ).timeout(_timeout).then(_checkGateway);

      if (res.statusCode != 200) {
        throw ServerException(res.statusCode, _errorFrom(res, 'แก้ไขโครงการไม่สำเร็จ'));
      }

      final project = ProjectModel.fromJson(jsonDecode(res.body)).copyWith(
        userRole:           userRole ?? existing?.userRole,
        memberIds:          memberIds,
        creatorAdminId:     existing?.creatorAdminId,
        projectTimeCreated: existing?.projectTimeCreated,
      );

      // cache ลง SQLite
      try {
        await taskLocalRepository.updateProject(project);
      } catch (e) {
        if (kDebugMode) debugPrint('updateProject cache error: $e');
      }
      return project;

    } catch (e) {
      // ไม่บันทึก offline >> ส่ง error
      if (!_isOfflineError(e)) rethrow;

      // แก้สมาชิกตอน offline ไม่ได้ (ต้องให้ server ตรวจสิทธิ์/กลุ่มก่อน)
      if (existing != null &&
          !_sameIds(existing.memberIds, memberIds)) {
        throw 'กรุณาเชื่อมต่ออินเทอร์เน็ตก่อนดำเนินการแก้ไขสมาชิกโครงการ';
      }

      // ติดต่อ server ไม่ได้ >> บันทึกลง SQLite >> sync ทีหลัง
      final offlineProject = buildLocal();
      await taskLocalRepository.updateProjectPending(offlineProject);
      return offlineProject;
    }
  }

  static bool _sameIds(List<int> a, List<int> b) =>
      a.toSet().length == b.toSet().length && a.toSet().containsAll(b);

  /// ── update project (updateProject และ syncUpdatedProjects) ──
  // includeMembers = false >> ไม่ส่ง member_ids (ใช้ตอน sync ไม่ให้แก้ไขสมาชิกขณะ offline)
  static Map<String, dynamic> _updateBody(ProjectModel p, {bool includeMembers = true}) => {
    'name_project_id':    p.nameProjectId,
    'project_name':       p.projectName,
    'project_details':    p.projectDetails,
    'province':           p.province,
    'sensor':             p.sensor,
    'gsd_num':            p.gsdNum,
    'gsd_unit':           p.gsdUnit,
    'survey_main':        p.surveyMain,
    'survey_sub':         p.surveySub,
    'project_start_date': p.projectStartDate,
    'project_end_date':   p.projectEndDate,
    'project_note':       p.projectNote,
    if (includeMembers) 'member_ids': p.memberIds,
  };


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
  Future<SyncResult> syncProjects({
    required String token,
    bool includeBlocked = false,
  }) async {
    final result = SyncResult();

    final raw = await taskLocalRepository.getUnsyncedProjects(includeBlocked: includeBlocked);
    if (raw.isEmpty) return result;

    // ต้องมี client uuid
    final unsynced = <ProjectModel>[];
    for (final p in raw) {
      unsynced.add(await taskLocalRepository.ensureClientUuid(p));
    }

    // server รับครั้งละไม่เกิน 50 โครงการ
    for (var i = 0; i < unsynced.length; i += 50) {
      final chunk = unsynced.sublist(i, min(i + 50, unsynced.length));
      try {
        result.add(await _syncProjectChunk(token, chunk));
      } catch (e) {
        if (_isOfflineError(e)) {
          result.offline = true;
          return result;
        }
        // error ทั้งชุด (เช่น 403 ไม่ใช่ admin / 500) >> บันทึกทุกแถวในชุดนี้
        final permanent = e is ServerException && e.isPermanent;
        final message = safeErrorMessage(e, fallback: 'sync โครงการไม่สำเร็จ');
        for (final p in chunk) {
          await taskLocalRepository.markSyncError(p.id, message, blocked: permanent);
          result.failed++;
        }
        if (kDebugMode) debugPrint('syncProjects error: $e');
      }
    }
    return result;
  }

  Future<SyncResult> _syncProjectChunk(String token, List<ProjectModel> chunk) async {
    final result = SyncResult();

    final res = await http.post(
      Uri.parse("${Constants.backendUri}/tasks/sync_projects"),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: jsonEncode(chunk.map((p) => p.toJson()).toList()),
    ).timeout(_syncTimeout).then(_checkGateway);

    if (res.statusCode != 200) {
      throw ServerException(res.statusCode, _errorFrom(res, 'sync โครงการไม่สำเร็จ'));
    }

    final body = jsonDecode(res.body);
    final List<dynamic> items = body is Map ? (body['results'] as List<dynamic>? ?? []) : [];

    final byUuid = {for (final p in chunk) p.clientUuid!: p};

    for (final item in items) {
      if (item is! Map) continue;
      final local = byUuid[item['client_uuid']];
      if (local == null) continue;

      if (item['status'] == 'created' || item['status'] == 'exists') {
        // response มาจากตาราง projects อย่างเดียว
        final synced = ProjectModel.fromJson(Map<String, dynamic>.from(item['project'] as Map)).copyWith(
          memberIds:          local.memberIds,
          userRole:           local.userRole,
          creatorAdminId:     local.creatorAdminId,
          projectTimeCreated: local.projectTimeCreated,
          clientUuid:         local.clientUuid,
        );
        await taskLocalRepository.replaceTempWithSynced(local.id, synced);
        result.synced++;
      } else {
        await taskLocalRepository.markSyncError(
          local.id,
          (item['error'] as String?) ?? 'sync โครงการไม่สำเร็จ',
          blocked: true,
        );
        result.failed++;
      }
    }
    return result;
  }


  /// ── sync โครงการที่แก้ไขขณะ offline ขึ้น server ────────────────────────────
  Future<SyncResult> syncUpdatedProjects({
    required String token,
    bool includeBlocked = false,
  }) async {
    final result = SyncResult();
    final pendingProjects =
    await taskLocalRepository.getUpdatedPendingProjects(includeBlocked: includeBlocked);

    for (final project in pendingProjects) {
      // โครงการ offline ยังไม่มีบน server
      if (project.id < 0) {
        await taskLocalRepository.markUpdateSynced(project.id);
        continue;
      }

      try {
        final res = await http.put(
          Uri.parse("${Constants.backendUri}/tasks/update_project/${project.id}"),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': token,
          },
          body: jsonEncode(_updateBody(project, includeMembers: false)),
        ).timeout(_timeout).then(_checkGateway);

        if (res.statusCode != 200) {
          throw ServerException(res.statusCode, _errorFrom(res, 'แก้ไขโครงการไม่สำเร็จ'));
        }

        // sync สำเร็จ >> is_updated_pending = 0
        await taskLocalRepository.markUpdateSynced(project.id);
        result.synced++;

      } catch (e) {
        if (_isOfflineError(e)) {
          result.offline = true;
          break;
        }
        final permanent = e is ServerException && e.isPermanent;
        final message = (e is ServerException && e.statusCode == 404)
            ? 'ไม่พบโครงการนี้ในระบบ'
            : safeErrorMessage(e, fallback: 'แก้ไขโครงการไม่สำเร็จ');
        await taskLocalRepository.markSyncError(project.id, message, blocked: permanent);
        result.failed++;
      }
    }
    return result;
  }

}