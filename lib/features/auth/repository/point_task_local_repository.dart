import 'package:nexa_sketch/export.dart';

class PointTaskLocalRepository {
  static const String _tableName = "points";

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// ── สร้างตารางใหม่ใน SQLite ──────────────────────────────────────
  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, "gnss_points.db");

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id                    INTEGER PRIMARY KEY,
            project_id            INTEGER NOT NULL,
            point_name            TEXT NOT NULL,
            northing              TEXT,
            easting               TEXT,
            height_m              TEXT,
            ellipsoidal_m         TEXT,
            antenna_m             TEXT,
            datum                 TEXT,
            utm                   TEXT,
            egm                   TEXT,
            survey_main           TEXT,
            survey_sub            TEXT,
            gdop_m                TEXT,
            pdop_m                TEXT,
            hdop_m                TEXT,
            dcq_m                 TEXT,
            tambon                TEXT,
            amphoe                TEXT,
            province              TEXT,
            point_date            TEXT,
            point_zoomin_img      TEXT,
            point_zoomout_img     TEXT,
            draw_img              TEXT,
            draw_data_json        TEXT,
            details_img           TEXT,
            details_data_json     TEXT,
            
            draw_description_img  TEXT,
            
            job                   TEXT,
            gnss                  TEXT,
            rf_1                  TEXT,
            distance_m_1          TEXT,
            az_1                  TEXT,
            rf_2                  TEXT,
            distance_m_2          TEXT,
            az_2                  TEXT,
            point_survey_img      TEXT,
            point_controller_img  TEXT,
            n_survey_img          TEXT,
            s_survey_img          TEXT,
            e_survey_img          TEXT,
            w_survey_img          TEXT,
            survey_technician     INTEGER,
            survey_qc             INTEGER,
            point_note            TEXT,
            
            is_synced             INTEGER NOT NULL DEFAULT 0,  -- sync create
            is_updated_pending    INTEGER NOT NULL DEFAULT 0,  -- sync update

            client_uuid           TEXT,                        -- idempotency key (กันหมุดซ้ำตอน sync)
            sync_error            TEXT,                        -- ข้อความ error ล่าสุดตอน sync
            sync_attempts         INTEGER NOT NULL DEFAULT 0,  -- จำนวนครั้งที่ sync ไม่ผ่าน
            sync_blocked          INTEGER NOT NULL DEFAULT 0   -- 1 = error ถาวร (4xx) หยุด auto sync รอผู้ใช้
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              "ALTER TABLE $_tableName ADD COLUMN draw_description_img TEXT"
          );
        }

        if (oldVersion < 3) {
          try {
            await db.execute(
                "ALTER TABLE $_tableName ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0"
            );
          } catch (_) {}
          try {
            await db.execute(
                "ALTER TABLE $_tableName ADD COLUMN is_updated_pending INTEGER NOT NULL DEFAULT 0"
            );
          } catch (_) {}
        }

        if (oldVersion < 4) {
          try {
            await db.execute("ALTER TABLE $_tableName ADD COLUMN draw_data_json TEXT");
          } catch (_) {}
          try {
            await db.execute("ALTER TABLE $_tableName ADD COLUMN details_data_json TEXT");
          } catch (_) {}
        }

        if (oldVersion < 5) {
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

      },
    );
  }

  /// ── Insert point เดียว พร้อมกำหนด is_synced ──────
  Future<void> insertPoint(PointModel point, {int isSynced = 0}) async {
    final db = await database;
    final map = _toMap(point);
    map['is_synced'] = isSynced;
    // บันทึกใหม่ = ผู้ใช้อาจแก้ข้อมูลที่เคย sync ไม่ผ่านแล้ว >> ล้างสถานะ error ให้ลองใหม่
    map.addAll(_clearSyncErrorMap);
    await db.insert(
      _tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ── Insert หลาย point พร้อมกัน (ข้าม point ที่ยังมีการแก้ไข offline รอ sync) ──────────────────
  Future<List<int>> insertPoints(List<PointModel> points) async {
    final db    = await database;
    final pendingRows = await db.query(
      _tableName,
      columns: ['id'],
      where: 'is_updated_pending = 1',
    );
    final pendingIds = pendingRows.map((r) => r['id'] as int).toSet();

    final batch = db.batch();
    for (final point in points) {
      if (pendingIds.contains(point.id)) continue;
      batch.insert(
        _tableName,
        _toMap(point),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    // หมุด offline ที่ถูกสร้างบน server แล้ว (response หายระหว่างทาง)
    final serverUuids = points
        .map((p) => p.clientUuid)
        .whereType<String>()
        .toSet();
    if (serverUuids.isEmpty) return const [];

    final tempRows = await db.query(
      _tableName,
      columns: ['id', 'client_uuid'],
      where: 'id < 0 AND client_uuid IS NOT NULL',
    );
    final removed = <int>[];
    for (final row in tempRows) {
      if (serverUuids.contains(row['client_uuid'])) {
        final id = row['id'] as int;
        await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
        removed.add(id);
      }
    }
    return removed;
  }

  /// ── ดึง point ทั้งหมดของโครงการจาก SQLite ──────────────────────
  Future<List<PointModel>> getPoints({required int projectId}) async {
    final db     = await database;
    final result = await db.query(
      _tableName,
      where:   'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'point_name ASC',
    );
    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── ดึงข้อมูล Point ด้วย ID ───────────────────────────────
  Future<PointModel?> getPointById(int pointId) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [pointId],
      limit: 1,
    );
    return result.isNotEmpty ? _fromMap(result.first) : null;
  }

  /// ── อัปเดต point ใน SQLite ──────────────────────────────────────
  Future<void> updatePoint(PointModel point) async {
    final db = await database;
    await db.update(
      _tableName,
      _toMap(point),
      where:     'id = ?',
      whereArgs: [point.id],
    );
  }

  /// ── ลบ point ออกจาก SQLite ──────────────────────────────────────
  Future<void> deletePoint(int pointId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where:     'id = ?',
      whereArgs: [pointId],
    );
  }

  /// ── ล้าง point ของโครงการที่ sync แล้ว (ไม่ลบ point ที่ยังรอ sync) ──
  Future<void> clearPointsByProject(int projectId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where:     'project_id = ? AND is_synced = 0 AND is_updated_pending = 0',
      whereArgs: [projectId],
    );
  }

  /// ── จำนวน point ที่ยังไม่ได้ส่งขึ้น server ──
  Future<int> countPending() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $_tableName WHERE is_synced = 1 OR is_updated_pending = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// ── ล้าง point ทั้งหมด (ใช้ตอน logout) ─────────────────────────
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }


  /* ============================================================
    ส่วนจัดการ sync Point (create)
  ============================================================ */
  /// ── ดึง Point ที่ยังไม่ได้ sync >> ข้ามหมุดที่เคยเจอ error ถาวร (รอผู้ใช้กด sync เองหรือแก้ข้อมูล) ──────────────────────────
  Future<List<PointModel>> getUnsyncedPoints({bool includeBlocked = false}) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: includeBlocked ? 'is_synced = 1' : 'is_synced = 1 AND sync_blocked = 0',
    );
    return result.map((e) => _fromMap(e)).toList();
  }

  /// ── sync create สำเร็จ >> แทน id ติดลบ ด้วยข้อมูลจริงจาก server ──────────────────────────
  Future<void> replaceTempWithSynced(int tempId, PointModel synced) async {
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
  Future<String> ensureClientUuid(PointModel p) async {
    if (p.clientUuid != null) return p.clientUuid!;
    final uuid = generateClientUuid();
    final db = await database;
    await db.update(
      _tableName,
      {'client_uuid': uuid},
      where: 'id = ?',
      whereArgs: [p.id],
    );
    return uuid;
  }


  /* ============================================================
    ส่วนจัดการสถานะ error ตอน sync
  ============================================================ */
  static const Map<String, Object?> _clearSyncErrorMap = {
    'sync_error':    null,
    'sync_attempts': 0,
    'sync_blocked':  0,
  };

  /// ── บันทึก error ตอน sync (blocked = true >> error ถาวร >> หยุด auto sync) ──
  Future<void> markSyncError(int pointId, String message, {required bool blocked}) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $_tableName '
          'SET sync_error = ?, sync_attempts = sync_attempts + 1, sync_blocked = ? '
          'WHERE id = ?',
      [message, blocked ? 1 : 0, pointId],
    );
  }

  /// ── รายการหมุดที่ sync ไม่ผ่าน ─────────────────
  Future<List<Map<String, Object?>>> getSyncErrors() async {
    final db = await database;
    return db.query(
      _tableName,
      columns: ['id', 'project_id', 'point_name', 'sync_error', 'sync_attempts', 'sync_blocked'],
      where: '(is_synced = 1 OR is_updated_pending = 1) AND sync_error IS NOT NULL',
      orderBy: 'sync_blocked DESC, point_name ASC',
    );
  }


  /* ============================================================
    ส่วนจัดการ sync Point (update)
  ============================================================ */
  /// ── ดึง Point ที่ยังไม่ได้  sync update ──────────────────────────
  Future<List<PointModel>> getUpdatedPendingPoints({bool includeBlocked = false}) async {
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
  Future<void> updatePointPending(PointModel point) async {
    final db = await database;
    final map = _toMap(point);
    map['is_updated_pending'] = 1;
    map.addAll(_clearSyncErrorMap);
    await db.update(
      _tableName,
      map,
      where: 'id = ?',
      whereArgs: [point.id],
    );
  }

  /// ── is_updated_pending = 0 (หลัง sync สำเร็จ) ───────────────────────────────
  Future<void> markUpdateSynced(int pointId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'is_updated_pending': 0, ..._clearSyncErrorMap},
      where: 'id = ?',
      whereArgs: [pointId],
    );
  }



  /* ============================================================
    Map Point
  ============================================================ */
  /// ── แปลง PointModel >> Map ───────────────────────────────────────
  Map<String, dynamic> _toMap(PointModel p) {
    return {
      'id':                   p.id,
      'project_id':           p.projectId,
      'point_name':           p.pointName,
      'northing':             p.northing,
      'easting':              p.easting,
      'height_m':             p.heightM,
      'ellipsoidal_m':        p.ellipsoidalM,
      'antenna_m':            p.antennaM,
      'datum':                p.datum,
      'utm':                  p.utm,
      'egm':                  p.egm,
      'survey_main':          p.surveyMain,
      'survey_sub':           p.surveySub,
      'gdop_m':               p.gdopM,
      'pdop_m':               p.pdopM,
      'hdop_m':               p.hdopM,
      'dcq_m':                p.dcqM,
      'tambon':               p.tambon,
      'amphoe':               p.amphoe,
      'province':             p.province,
      'point_date':           p.pointDate,
      'point_zoomin_img':     p.pointZoominImg,
      'point_zoomout_img':    p.pointZoomoutImg,
      'draw_img':             p.drawImg,
      'draw_data_json':       p.drawDataJson,
      'details_img':          p.detailsImg,
      'details_data_json':    p.detailsDataJson,

      'draw_description_img': p.drawDescriptionImg,

      'job':                  p.job,
      'gnss':                 p.gnss,
      'rf_1':                 p.rf1,
      'distance_m_1':         p.distanceM1,
      'az_1':                 p.az1,
      'rf_2':                 p.rf2,
      'distance_m_2':         p.distanceM2,
      'az_2':                 p.az2,
      'point_survey_img':     p.pointSurveyImg,
      'point_controller_img': p.pointControllerImg,
      'n_survey_img':         p.nSurveyImg,
      's_survey_img':         p.sSurveyImg,
      'e_survey_img':         p.eSurveyImg,
      'w_survey_img':         p.wSurveyImg,
      'survey_technician':    p.surveyTechnician,
      'survey_qc':            p.surveyQc,
      'point_note':           p.pointNote,

      'client_uuid':          p.clientUuid,
    };
  }

  /// ── แปลง Map >> PointModel ───────────────────────────────────────
  PointModel _fromMap(Map<String, dynamic> map) {
    return PointModel(
      id:                   map['id'] as int,
      projectId:            map['project_id'] as int,
      pointName:            map['point_name'] as String,
      northing:             map['northing'] as String?,
      easting:              map['easting'] as String?,
      heightM:              map['height_m'] as String?,
      ellipsoidalM:         map['ellipsoidal_m'] as String?,
      antennaM:             map['antenna_m'] as String?,
      datum:                map['datum'] as String?,
      utm:                  map['utm'] as String?,
      egm:                  map['egm'] as String?,
      surveyMain:           map['survey_main'] as String?,
      surveySub:            map['survey_sub'] as String?,
      gdopM:                map['gdop_m'] as String?,
      pdopM:                map['pdop_m'] as String?,
      hdopM:                map['hdop_m'] as String?,
      dcqM:                 map['dcq_m'] as String?,
      tambon:               map['tambon'] as String?,
      amphoe:               map['amphoe'] as String?,
      province:             map['province'] as String?,
      pointDate:            map['point_date'] as String?,
      pointZoominImg:       map['point_zoomin_img'] as String?,
      pointZoomoutImg:      map['point_zoomout_img'] as String?,
      drawImg:              map['draw_img'] as String?,
      drawDataJson:         map['draw_data_json'] as String?,
      detailsImg:           map['details_img'] as String?,
      detailsDataJson:      map['details_data_json'] as String?,

      drawDescriptionImg:   map['draw_description_img'] as String?,

      job:                  map['job'] as String?,
      gnss:                 map['gnss'] as String?,
      rf1:                  map['rf_1'] as String?,
      distanceM1:           map['distance_m_1'] as String?,
      az1: map['az_1'] != null ? map['az_1'].toString() : null,
      rf2:                  map['rf_2'] as String?,
      distanceM2:           map['distance_m_2'] as String?,
      az2: map['az_2'] != null ? map['az_2'].toString() : null,
      pointSurveyImg:       map['point_survey_img'] as String?,
      pointControllerImg:   map['point_controller_img'] as String?,
      nSurveyImg:           map['n_survey_img'] as String?,
      sSurveyImg:           map['s_survey_img'] as String?,
      eSurveyImg:           map['e_survey_img'] as String?,
      wSurveyImg:           map['w_survey_img'] as String?,
      surveyTechnician:     map['survey_technician'] as int?,
      surveyQc:             map['survey_qc'] as int?,

      pointNote:            map['point_note'] as String?,
      clientUuid:           map['client_uuid'] as String?,

      syncStatus:           _syncStatusFrom(map),
      syncError:            map['sync_error'] as String?,
    );
  }

  /// ── แปลงคอลัมน์สถานะใน SQLite เป็น PointSyncStatus ──────────────
  PointSyncStatus _syncStatusFrom(Map<String, dynamic> map) {
    final pendingCreate = (map['is_synced'] as int? ?? 0) == 1;
    final pendingUpdate = (map['is_updated_pending'] as int? ?? 0) == 1;
    if (!pendingCreate && !pendingUpdate) return PointSyncStatus.synced;
    if ((map['sync_blocked'] as int? ?? 0) == 1) return PointSyncStatus.failed;
    return pendingCreate ? PointSyncStatus.pendingCreate : PointSyncStatus.pendingUpdate;
  }




  /// ── debug: แสดงข้อมูล Point ทั้งหมดใน SQLite ───────────────────
  Future<void> printAllPoints() async {
    final db = await database;
    final result = await db.query(_tableName);

    print("========== SQLite Points (${result.length} rows) ==========");

    for (final row in result) {
      print("---------------------------------------------------");
      print("id:                    ${row['id']}");
      print("project_id:            ${row['project_id']}");
      print("point_name:            ${row['point_name']}");
      print("northing:              ${row['northing']}");
      print("easting:               ${row['easting']}");
      print("height_m:              ${row['height_m']}");
      print("ellipsoidal_m:         ${row['ellipsoidal_m']}");
      print("antenna_m:             ${row['antenna_m']}");
      print("datum:                 ${row['datum']}");
      print("utm:                   ${row['utm']}");
      print("egm:                   ${row['egm']}");
      print("survey_main:           ${row['survey_main']}");
      print("survey_sub:            ${row['survey_sub']}");
      print("gdop_m:                ${row['gdop_m']}");
      print("pdop_m:                ${row['pdop_m']}");
      print("hdop_m:                ${row['hdop_m']}");
      print("dcq_m:                 ${row['dcq_m']}");
      print("tambon:                ${row['tambon']}");
      print("amphoe:                ${row['amphoe']}");
      print("province:              ${row['province']}");
      print("point_date:            ${row['point_date']}");
      print("point_zoomin_img:      ${row['point_zoomin_img']}");
      print("point_zoomout_img:     ${row['point_zoomout_img']}");
      print("draw_img:              ${row['draw_img']}");
      print("details_img:           ${row['details_img']}");
      print("draw_description_img:  ${row['draw_description_img']}");
      print("job:                   ${row['job']}");
      print("gnss:                  ${row['gnss']}");
      print("rf_1:                  ${row['rf_1']}");
      print("distance_m_1:          ${row['distance_m_1']}");
      print("az_1:                  ${row['az_1']}");
      print("rf_2:                  ${row['rf_2']}");
      print("distance_m_2:          ${row['distance_m_2']}");
      print("az_2:                  ${row['az_2']}");
      print("point_survey_img:      ${row['point_survey_img']}");
      print("point_controller_img:  ${row['point_controller_img']}");
      print("n_survey_img:          ${row['n_survey_img']}");
      print("s_survey_img:          ${row['s_survey_img']}");
      print("e_survey_img:          ${row['e_survey_img']}");
      print("w_survey_img:          ${row['w_survey_img']}");
      print("survey_technician:     ${row['survey_technician']}");
      print("survey_qc:             ${row['survey_qc']}");
      print("point_note:            ${row['point_note']}");
      print("is_synced:             ${row['is_synced']}");
      print("is_updated_pending:    ${row['is_updated_pending']}");
      print("client_uuid:           ${row['client_uuid']}");
      print("sync_error:            ${row['sync_error']} (attempts ${row['sync_attempts']}, blocked ${row['sync_blocked']})");
      print("---------------------------------------------------");
    }

    print("=======================================================");
  }


}