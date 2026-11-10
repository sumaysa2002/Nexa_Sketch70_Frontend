import 'package:nexa_sketch/export.dart';

class AuthLocalRepository {
  String tableName = "users"; // ตาราง Users
  Database? _database;

  /// ── เชื่อมต่อฐานข้อมูล (Database Singleton Pattern) ──────────────────────────────────────
  Future<Database> get database async {
    // ถ้าเคยเปิดแล้ว ให้ส่งตัวเดิมกลับไป
    if (_database != null) {
      return _database!;
    }
    // ถ้ายังไม่เคยเปิด ให้สร้างการเชื่อมต่อใหม่
    _database = await _initDb();
    return _database!;
  }

  /// ── สร้างตารางใหม่ใน SQLite ──────────────────────────────────────
  Future<Database> _initDb() async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "auth.db");

    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        // ตาราง user เก็บข้อมูลผู้ใช้งาน
        await db.execute('''
          CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY,
            title_name TEXT,
            first_name TEXT,
            last_name TEXT,
            phone TEXT,
            email TEXT,
            profile_img TEXT,
            signature TEXT,
            job_position TEXT,
            job_level TEXT,
            job_office TEXT,
            job_department TEXT,
            admin TEXT,
            status TEXT,
            token TEXT,
            is_updated_pending INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // ตาราง all_approved_users สำหรับเก็บ list สมาชิกที่ผ่านการอนุมัติ
        await db.execute('''
          CREATE TABLE all_approved_users(
            id INTEGER PRIMARY KEY,
            title_name TEXT,
            first_name TEXT,
            last_name TEXT,
            phone TEXT,
            email TEXT,
            profile_img TEXT,
            signature TEXT,
            job_position TEXT,
            job_level TEXT,
            job_office TEXT,
            job_department TEXT,
            admin TEXT,
            status TEXT,
            token TEXT
          )
        ''');

        await _createProjectMemberUsersTable(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE $tableName ADD COLUMN signature TEXT");

          // สร้างตาราง all_approved_users สำหรับผู้ใช้เดิม
          await db.execute('''
            CREATE TABLE IF NOT EXISTS all_approved_users(
              id INTEGER PRIMARY KEY,
              title_name TEXT,
              first_name TEXT,
              last_name TEXT,
              phone TEXT,
              email TEXT,
              profile_img TEXT,
              signature TEXT,
              job_position TEXT,
              job_level TEXT,
              job_office TEXT,
              job_department TEXT,
              admin TEXT,
              status TEXT,
              token TEXT
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute("ALTER TABLE $tableName ADD COLUMN is_updated_pending INTEGER NOT NULL DEFAULT 0");
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
                "ALTER TABLE $tableName ADD COLUMN is_updated_pending INTEGER NOT NULL DEFAULT 0"
            );
          } catch (_) {
            // column มีอยู่แล้ว → ข้าม
          }
        }

        if (oldVersion < 5) {
          // เปลี่ยนชื่อตาราง known_users >> project_member_users (ย้ายข้อมูลเดิมมาด้วย)
          await _createProjectMemberUsersTable(db);
          try {
            await db.execute(
                "INSERT OR IGNORE INTO project_member_users SELECT * FROM known_users"
            );
          } catch (_) {
            // ไม่มีตาราง known_users (ข้าม version 4) → ข้าม
          }
          await db.execute("DROP TABLE IF EXISTS known_users");
        }
      },
    );

  }

  /// ── สร้างตาราง project_member_users ข้อมูลสมาชิกโครงการล่าสุดจาก users_by_ids (รวมอดีตสมาชิกที่ถูกถอนการอนุมัติ) >> ใช้แสดงชื่อ/สถานะตอน offline ──────────────────────────────────────
  Future<void> _createProjectMemberUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS project_member_users(
            id INTEGER PRIMARY KEY,
            title_name TEXT,
            first_name TEXT,
            last_name TEXT,
            phone TEXT,
            email TEXT,
            profile_img TEXT,
            signature TEXT,
            job_position TEXT,
            job_level TEXT,
            job_office TEXT,
            job_department TEXT,
            admin TEXT,
            status TEXT,
            token TEXT
      )
    ''');
  }

  /// ── การบันทึกข้อมูล User ผู้เข้าใช้งาน ─────────────────────────────
  Future<void> insertUser(UserModel userModel) async {
    final db = await database;
    await db.insert(
      tableName,
      userModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ── การดึงข้อมูล User ผู้เข้าใช้งาน ──────────────────────────────────────
  Future<UserModel?> getUser() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(tableName, limit: 1);

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }

    return null;
  }

  /// ── อัปเดทข้อมูล user ผู้ใช้งานใน SQLite (online เท่านั้น) ────────────────────────────────────
  Future<void> updateUser(UserModel user) async {
    final db = await database;
    await db.update(
      tableName,
      {...user.toMap(), 'is_updated_pending': 0},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// ── บันทึก User ที่ผ่านการอนุมัติลง SQLite ──────────────────────────────────────
  Future<void> insertApprovedUsers(List<UserModel> users) async {
    final db = await database;
    final batch = db.batch();

    await db.delete('all_approved_users');

    for (final user in users) {
      batch.insert(
        'all_approved_users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// ── เรียกข้อมูล User ที่ผ่านการอนุมัติจาก SQLite ──────────────────────────────────────
  Future<List<UserModel>> getApprovedUsers() async {
    final db = await database;
    final result = await db.query(
      'all_approved_users',
      orderBy: 'email ASC', // เรียง a-z ตาม email เหมือน Backend
    );

    return result.map((e) => UserModel.fromMap(e)).toList();
  }

  /// ── ล้าง all_approved_users และ project_member_users ตอน logout ──────────────────────────────────────
  Future<void> deleteApprovedUsers() async {
    final db = await database;
    await db.delete('all_approved_users');
    await db.delete('project_member_users');
  }

  /// ── บันทึก/อัปเดตข้อมูลสมาชิกที่ได้จาก users_by_ids ไปยังตาราง project_member_users ──────────────────────────────────────
  Future<void> upsertProjectMemberUsers(List<UserModel> users) async {
    if (users.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final user in users) {
      batch.insert(
        'project_member_users',
        user.toMap()..['token'] = '',
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// ── เรียกข้อมูลสมาชิกตาม id จาก project_member_users ──────────────────────────────────────
  Future<List<UserModel>> getProjectMemberUsersByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final unique = ids.toSet().toList();
    final result = await db.query(
      'project_member_users',
      where: 'id IN (${List.filled(unique.length, '?').join(',')})',
      whereArgs: unique,
    );
    return result.map((e) => UserModel.fromMap(e)).toList();
  }

  /// ── หลัง admin ถอนจากรายชื่อที่อนุมัติ >> project_member_users เป็น "ถูกถอนการอนุมัติ" (status/admin = null) ──────────────────────────────────────
  Future<void> markUserRevoked(int userId) async {
    final db = await database;
    await db.delete('all_approved_users', where: 'id = ?', whereArgs: [userId]);
    await db.update(
      'project_member_users',
      {'status': null, 'admin': null},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// ── ฟังก์ชันสำหรับลบข้อมูล tableName เมื่อ logout ──────────────────────────────────────
  Future<void> deleteUser() async {
    final db = await database;
    await db.delete(tableName);
    await db.delete('all_approved_users');
  }

  /// ── mark รอ sync (offline) ──────────────────────────────────────
  Future<void> updateUserPending(UserModel user) async {
    final db = await database;
    await db.update(
      tableName,
      {...user.toMap(), 'is_updated_pending': 1},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// ── ดึง user ที่รอ sync ──────────────────────────────────────
  Future<UserModel?> getPendingUser() async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: 'is_updated_pending = ?',
      whereArgs: [1],
      limit: 1,
    );
    return result.isNotEmpty ? UserModel.fromMap(result.first) : null;
  }


}