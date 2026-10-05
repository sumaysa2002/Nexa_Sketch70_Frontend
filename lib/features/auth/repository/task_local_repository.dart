import 'package:offline_gnss69_new/export.dart';

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
      version: 5,
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
            creator_admin_id     INTEGER  -- id ของ admin ที่สร้างโครงการ
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
      }
    );
  }

  /// ── Insert โครงการเดียว ───────────────────────────────────
  Future<void> insertProject(ProjectModel project, {int isSynced = 0}) async {
    final db = await database;
    final map = _toMap(project);
    map['is_synced'] = isSynced;
    await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ── Insert หลายโครงการพร้อมกัน (cache จาก API) ────────────
  Future<void> insertProjects(List<ProjectModel> projects) async {
    final db = await database;
    final batch = db.batch();
    for (final project in projects) {
      batch.insert(
        _tableName,
        _toMap(project),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// ── upsert project ทีละตัว ─────────────────────────────
  Future<void> upsertProjects(List<ProjectModel> projects) async {
    final db = await database;

    final batch = db.batch();

    for (final project in projects) {
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
  Future<void> updateProject(ProjectModel project) async {
    final db = await database;
    await db.update(
      _tableName,
      _toMap(project),
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

  /// ── ล้างข้อมูลโครงการทั้งหมด ─────────────────────────────────────
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }


  /* ============================================================
    ส่วนจัดการ sync Projects (create)
  ============================================================ */
  /// ── ดึงโครงการที่ยังไม่ได้ sync create ──────────────────────────
  Future<List<ProjectModel>> getUnsyncedProjects() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'is_synced = ?',
      whereArgs: [1],
    );

    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── is_synced = 0 หลัง sync สำเร็จ ─────────────────────────────────────
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
  Future<List<ProjectModel>> getUpdatedPendingProjects() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'is_updated_pending = ?',
      whereArgs: [1],
    );
    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── is_updated_pending = 1 รอ sync ─────────────────────────────────────
  Future<void> updateProjectPending(ProjectModel project) async {
    final db = await database;
    final map = _toMap(project);
    map['is_updated_pending'] = 1;
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  /// ── is_updated_pending = 0 หลัง sync สำเร็จ ─────────────────────────────────────
  Future<void> markUpdateSynced(int projectId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_updated_pending': 0},
      where: 'id = ?',
      whereArgs: [projectId],
    );
  }



  /* ============================================================
    Map Projects
  ============================================================ */
  /// ── แปลง ProjectModel >> เป็น Map สำหรับ SQLite ────────────────
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
      'is_synced':            0,
      'creator_admin_id':     project.creatorAdminId,
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
      print("---------------------------------------------------");
    }
    print("=======================================================");
  }



}