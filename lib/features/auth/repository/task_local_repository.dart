import 'package:nexa_sketch/export.dart';

class TaskLocalRepository {
  static const String _tableName = "projects";

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// ── สร้างตารางใหม่ใน SQLite ──────────────────────────────────────
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "gnss_projects.db");

    return openDatabase(
        path,
        version: 6,
        onCreate: (db, version) {
          return db.execute('''
          CREATE TABLE $_tableName (
            id                  INTEGER PRIMARY KEY,
            name_project_id     TEXT,
            project_name        TEXT NOT NULL,
            project_details     TEXT,
            province            TEXT,
            sensor              TEXT,
            gsd_num             INTEGER,
            gsd_unit            TEXT,
            survey_main         TEXT,
            survey_sub          TEXT,
            project_start_date  TEXT,
            project_end_date    TEXT,
            project_note        TEXT,
            member_ids          TEXT,
            project_time_created TEXT,
            user_role           TEXT,       -- จำสถานะ 'Editor' | 'Viewer'
            is_synced            INTEGER NOT NULL DEFAULT 0, -- sync create
            is_updated_pending   INTEGER NOT NULL DEFAULT 0,  -- sync update
            creator_admin_id     INTEGER, -- id ของ admin ที่สร้างโครงการ

            client_uuid          TEXT,                        -- idempotency key (กันโครงการซ้ำตอน sync)
            sync_error           TEXT,                        -- ข้อความ error ล่าสุดตอน sync
            sync_attempts        INTEGER NOT NULL DEFAULT 0,  -- จำนวนครั้งที่ sync ไม่ผ่าน
            sync_blocked         INTEGER NOT NULL DEFAULT 0   -- 1 = error ถาวร (4xx) หยุด auto sync รอผู้ใช้
          )
        ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE $_tableName ADD COLUMN user_role TEXT");
          }
          if (oldVersion < 3) {
            // เพิ่ม column สำหรับผู้ใช้เดิม
            await db.execute("ALTER TABLE $_tableName ADD COLUMN is_updated_pending INTEGER NOT NULL DEFAULT 0");
          }
          if (oldVersion < 4) {
            // เพิ่ม column
            await db.execute("ALTER TABLE $_tableName ADD COLUMN creator_admin_id INTEGER");
          }

          if (oldVersion < 5) {
            await db.execute(
                "UPDATE $_tableName SET is_synced = 0 WHERE is_synced = 1"
            );
          }

          if (oldVersion < 6) {
            for (final sql in [
              "ALTER TABLE $_tableName ADD COLUMN client_uuid TEXT",
              "ALTER TABLE $_tableName ADD COLUMN sync_error TEXT",
              "ALTER TABLE $_tableName ADD COLUMN sync_attempts INTEGER NOT NULL DEFAULT 0",
              "ALTER TABLE $_tableName ADD COLUMN sync_blocked INTEGER NOT NULL DEFAULT 0",
            ]) {
              try {
                await db.execute(sql);
              } catch (_) {}
            }
            final pending = await db.query(
              _tableName,
              columns: ['id'],
              where: 'is_synced = 1 AND client_uuid IS NULL',
            );
            for (final row in pending) {
              await db.update(
                _tableName,
                {'client_uuid': generateClientUuid()},
                where: 'id = ?',
                whereArgs: [row['id']],
              );
            }
          }
        }
    );
  }

  /// ── Insert โครงการเดียว ───────────────────────────────────
  Future<void> insertProject(ProjectModel project, {int isSynced = 0}) async {
    final db = await database;
    final map = _toMap(project);
    map['is_synced'] = isSynced;
    map.addAll(_clearSyncErrorMap);
    await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ── แก้ไขโครงการตอน offline ─────────────
  Future<Set<int>> _pendingUpdateIds(Database db) async {
    final rows = await db.query(
      _tableName,
      columns: ['id'],
      where: 'is_updated_pending = 1',
    );
    return rows.map((r) => r['id'] as int).toSet();
  }

  /// ── Insert หลายโครงการพร้อมกัน (ข้ามโครงการที่ยังมีการแก้ไข offline รอ sync) ────────────
  Future<void> insertProjects(List<ProjectModel> projects) async {
    final db = await database;
    final pendingIds = await _pendingUpdateIds(db);
    final batch = db.batch();
    for (final project in projects) {
      if (pendingIds.contains(project.id)) continue;
      batch.insert(
        _tableName,
        _toMap(project),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// ── upsert project (ข้ามโครงการที่ยังมีการแก้ไข offline รอ sync) ─────────────────────────────
  Future<void> upsertProjects(List<ProjectModel> projects) async {
    final db = await database;
    final pendingIds = await _pendingUpdateIds(db);

    final batch = db.batch();

    for (final project in projects) {
      if (pendingIds.contains(project.id)) continue;
      batch.insert(
        _tableName,
        _toMap(project),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// ── ดึงโครงการทั้งหมดจาก SQLite ──────────────────────────
  Future<List<ProjectModel>> getProjects({int? adminId}) async {
    final db = await database;

    // กรองเฉพาะโครงการตาม admin
    final result = adminId != null
        ? await db.query(
      _tableName,
      where: 'creator_admin_id = ?',
      whereArgs: [adminId],
      orderBy: 'project_time_created DESC',
    )
        : await db.query(_tableName, orderBy: 'project_time_created DESC');

    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── อัปเดทข้อมูลโครงการใน SQLite ────────────────────────
  Future<void> updateProject(ProjectModel project, {bool resetSyncError = false}) async {
    final db = await database;
    final map = _toMap(project);
    if (resetSyncError) map.addAll(_clearSyncErrorMap);
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// ── ลบโครงการ ─────────────────────────────────────────────
  Future<void> deleteProject(int projectId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }

  /// ── จำนวนโครงการที่ยังไม่ได้ส่งขึ้น server (สร้างหรือแก้ไขตอน offline) ──
  Future<int> countPending() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tableName WHERE is_synced = 1 OR is_updated_pending = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// ── ล้างข้อมูลโครงการทั้งหมด ─────────────────────────────────────
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }


  /* ============================================================
    ส่วนจัดการ sync Projects (create)
  ============================================================ */
  /// ── ดึงโครงการที่ยังไม่ได้ sync >> ข้ามโครงการที่เคยเจอ error ถาวร (รอผู้ใช้กด sync เองหรือแก้ข้อมูล) ──────────────────────────
  Future<List<ProjectModel>> getUnsyncedProjects({bool includeBlocked = false}) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: includeBlocked ? 'is_synced = 1' : 'is_synced = 1 AND sync_blocked = 0',
    );

    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── sync create สำเร็จ >> แทน id ติดลบ ด้วยข้อมูลจริงจาก server ──
  Future<void> replaceTempWithSynced(int tempId, ProjectModel synced) async {
    final db = await database;
    await db.transaction((txn) async {
      final map = _toMap(synced)
        ..['is_synced'] = 0
        ..['is_updated_pending'] = 0
        ..addAll(_clearSyncErrorMap);
      await txn.insert(_tableName, map, conflictAlgorithm: ConflictAlgorithm.replace);
      if (tempId != synced.id) {
        await txn.delete(_tableName, where: 'id = ?', whereArgs: [tempId]);
      }
    });
  }

  /// ── เติม client_uuid ให้แถวที่ยังไม่มี ──────────
  Future<ProjectModel> ensureClientUuid(ProjectModel p) async {
    if (p.clientUuid != null) return p;
    final uuid = generateClientUuid();
    final db = await database;
    await db.update(
      _tableName,
      {'client_uuid': uuid},
      where: 'id = ?',
      whereArgs: [p.id],
    );
    return p.copyWith(clientUuid: uuid);
  }


  /* ============================================================
    ส่วนจัดการสถานะ error ตอน sync
  ============================================================ */
  static const Map<String, Object?> _clearSyncErrorMap = {
    'sync_error':    null,
    'sync_attempts': 0,
    'sync_blocked':  0,
  };

  /// ── บันทึก error ตอน sync (blocked = true >> error ถาวร หยุด auto sync) ──
  Future<void> markSyncError(int projectId, String message, {required bool blocked}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_tableName '
          'SET sync_error = ?, sync_attempts = sync_attempts + 1, sync_blocked = ? '
          'WHERE id = ?',
      [message, blocked ? 1 : 0, projectId],
    );
  }

  /// ── รายการโครงการที่ sync ไม่ผ่าน ─────────────────
  Future<List<Map<String, Object?>>> getSyncErrors() async {
    final db = await database;
    return db.query(
      _tableName,
      columns: ['id', 'project_name', 'sync_error', 'sync_attempts', 'sync_blocked'],
      where: '(is_synced = 1 OR is_updated_pending = 1) AND sync_error IS NOT NULL',
      orderBy: 'sync_blocked DESC, project_name ASC',
    );
  }

  /// ── is_synced = 0 (หลัง sync สำเร็จ) ─────────────────────────────────────
  Future<void> updateRowValue(int projectId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_synced': 0},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }


  /* ============================================================
    ส่วนจัดการ sync Projects (update)
  ============================================================ */
  /// ── ดึงโครงการที่ยังไม่ได้  sync update ──────────────────────────
  Future<List<ProjectModel>> getUpdatedPendingProjects({bool includeBlocked = false}) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: includeBlocked
          ? 'is_updated_pending = 1'
          : 'is_updated_pending = 1 AND sync_blocked = 0',
    );
    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── is_updated_pending = 1 (รอ sync) ─────────────────────────────────────
  Future<void> updateProjectPending(ProjectModel project) async {
    final db = await database;
    final map = _toMap(project);
    map['is_updated_pending'] = 1;
    map.addAll(_clearSyncErrorMap); // ผู้ใช้แก้ใหม่ >> ให้ลอง sync ใหม่
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// ── is_updated_pending = 0 (หลัง sync สำเร็จ) ─────────────────────────────────────
  Future<void> markUpdateSynced(int projectId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_updated_pending': 0, ..._clearSyncErrorMap},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }



  /* ============================================================
    Map Projects
  ============================================================ */
  /// ── แปลง ProjectModel >>  Map ────────────────
  Map<String, dynamic> _toMap(ProjectModel project) {
    return {
      'id':                   project.id,
      'name_project_id':      project.nameProjectId,
      'project_name':         project.projectName,
      'project_details':      project.projectDetails,
      'province':             project.province,
      'sensor':               project.sensor,
      'gsd_num':              project.gsdNum,
      'gsd_unit':             project.gsdUnit,
      'survey_main':          project.surveyMain,
      'survey_sub':           project.surveySub,
      'project_start_date':   project.projectStartDate,
      'project_end_date':     project.projectEndDate,
      'project_note':         project.projectNote,
      'member_ids':           jsonEncode(project.memberIds),
      'project_time_created': project.projectTimeCreated,
      'user_role':            project.userRole,
      'creator_admin_id':     project.creatorAdminId,

      'client_uuid':          project.clientUuid,
    };
  }

  /// ── แปลง Map >> เป็น ProjectModel ───────────────────────────────
  ProjectModel _fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id:                   map['id'] as int,
      nameProjectId:        map['name_project_id'] as String?,
      projectName:          map['project_name'] as String,
      projectDetails:       map['project_details'] as String?,
      province:             map['province'] as String?,
      sensor:               map['sensor'] as String?,
      gsdNum:               map['gsd_num'] as int?,
      gsdUnit:              map['gsd_unit'] as String?,
      surveyMain:           map['survey_main'] as String?,
      surveySub:            map['survey_sub'] as String?,
      projectStartDate:     map['project_start_date'] as String?,
      projectEndDate:       map['project_end_date'] as String?,
      projectNote:          map['project_note'] as String?,
      memberIds:            map['member_ids'] != null
          ? List<int>.from(jsonDecode(map['member_ids'] as String))
          : [],
      projectTimeCreated:   map['project_time_created'] as String?,
      userRole:             map['user_role'] as String?,
      creatorAdminId:       map['creator_admin_id'] as int?,

      clientUuid:           map['client_uuid'] as String?,
    );
  }



  /// ── debug: แสดงข้อมูลทั้งหมดใน SQLite ───────────────────
  Future<void> printAllProjects() async {
    final db = await database;
    final result = await db.query(_tableName);

    print("========== SQLite Projects (${result.length} rows) ==========");
    for (final row in result) {
      print("---------------------------------------------------");
      print("id:                  ${row['id']}");
      print("name_project_id:     ${row['name_project_id']}");
      print("project_name:        ${row['project_name']}");
      print("project_details:     ${row['project_details']}");
      print("province:            ${row['province']}");
      print("sensor:              ${row['sensor']}");
      print("gsd_num:             ${row['gsd_num']}");
      print("gsd_unit:            ${row['gsd_unit']}");
      print("survey_main:         ${row['survey_main']}");
      print("survey_sub:          ${row['survey_sub']}");
      print("project_start_date:  ${row['project_start_date']}");
      print("project_end_date:    ${row['project_end_date']}");
      print("member_ids:          ${row['member_ids']}");
      print("project_time_created:${row['project_time_created']}");
      print("user_role:           ${row['user_role']}");
      print("is_synced:           ${row['is_synced']}");
      print("is_updated_pending:  ${row['is_updated_pending']}");
      print("creator_admin_id:    ${row['creator_admin_id']}");
      print("client_uuid:         ${row['client_uuid']}");
      print("sync_error:          ${row['sync_error']} (attempts ${row['sync_attempts']}, blocked ${row['sync_blocked']})");
      print("---------------------------------------------------");
    }
    print("=======================================================");
  }



}