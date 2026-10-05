import 'package:http/http.dart' as http;

import 'package:offline_gnss69_new/export.dart';

class PointTaskRemoteRepository {

  final _local = PointTaskLocalRepository();
  final _pendingImages = PendingPointImageService();

  /// ── ping เช็คว่า backend (API) ตอบสนองไหม ────────────
  Future<bool> pingApi({required String token}) async {
    try {
      final res = await http.get(
        Uri.parse('${Constants.backendUri}/points/ping'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(const Duration(seconds: 5));
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// ── อ่าน bytes จากทุก field รูปของ point ────────────────
  Future<Map<String, Uint8List?>> _readAllImageBytes(PointModel p, {
    bool onlyLocal = false,
  }) async {
    Future<Uint8List?> read(String? value) async {
      if (value == null) return null;
      if (!_pendingImages.isLocalPath(value))
        return null; // ชื่อไฟล์ server เดิม >> ไม่ต้องอ่าน
      return _pendingImages.readBytes(value);
    }
    return {
      'point_zoomin_img': await read(p.pointZoominImg),
      'point_zoomout_img': await read(p.pointZoomoutImg),
      'draw_img': await read(p.drawImg),
      'details_img': await read(p.detailsImg),
      'draw_description_img': await read(p.drawDescriptionImg),
      'point_survey_img': await read(p.pointSurveyImg),
      'point_controller_img': await read(p.pointControllerImg),
      'n_survey_img': await read(p.nSurveyImg),
      's_survey_img': await read(p.sSurveyImg),
      'e_survey_img': await read(p.eSurveyImg),
      'w_survey_img': await read(p.wSurveyImg),
    };
  }


  /* ============================================================
    ส่วนจัดการ Point
  ============================================================ */
  /// ── สร้าง Point ใหม่ ──────────────────────────────────────
  Future<PointModel> createPoint({
    required String token,
    required int projectId,
    required String pointName,

    // UTM
    String? northing,
    String? easting,
    String? heightM,
    String? ellipsoidalM,
    String? antennaM,
    String? datum,
    String? utm,
    String? egm,

    // Survey
    String? surveyMain,
    String? surveySub,

    // GDOP
    String? gdopM,
    String? pdopM,
    String? hdopM,
    String? dcqM,

    // ตำบล อำเภอ จังหวัด วันที่
    String? tambon,
    String? amphoe,
    String? province,
    String? pointDate,

    // รูปแสดงบริเวณหมุดรังวัด
    Uint8List? pointZoominImg,
    Uint8List? pointZoomoutImg,

    // รูปวาดภาคสนาม / รายละเอียด
    Uint8List? drawImg,
    String? drawDataJson,
    Uint8List? detailsImg,
    String? detailsDataJson,

    Uint8List? drawDescriptionImg,

    // JOB
    String? job,
    String? gnss,
    String? rf1,
    String? distanceM1,
    String? az1,
    String? rf2,
    String? distanceM2,
    String? az2,

    // รูปถ่ายประกอบ
    Uint8List? pointSurveyImg,
    Uint8List? pointControllerImg,
    Uint8List? nSurveyImg,
    Uint8List? sSurveyImg,
    Uint8List? eSurveyImg,
    Uint8List? wSurveyImg,

    // ผู้รังวัด / ผู้ตรวจสอบ
    int? surveyTechnician,
    int? surveyQc,

    String? pointNote

  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.backendUri}/points/create_point'),
      );

      request.headers['x-auth-token'] = token;
      request.fields['project_id'] = projectId.toString();
      request.fields['point_name'] = pointName;

      if (northing != null) request.fields['northing'] = northing;
      if (easting != null) request.fields['easting'] = easting;
      if (heightM != null) request.fields['height_m'] = heightM;
      if (ellipsoidalM != null) request.fields['ellipsoidal_m'] = ellipsoidalM;
      if (antennaM != null) request.fields['antenna_m'] = antennaM;
      if (datum != null) request.fields['datum'] = datum;
      if (utm != null) request.fields['utm'] = utm;
      if (egm != null) request.fields['egm'] = egm;
      if (surveyMain != null) request.fields['survey_main'] = surveyMain;
      if (surveySub != null) request.fields['survey_sub'] = surveySub;
      if (gdopM != null) request.fields['gdop_m'] = gdopM;
      if (pdopM != null) request.fields['pdop_m'] = pdopM;
      if (hdopM != null) request.fields['hdop_m'] = hdopM;
      if (dcqM != null) request.fields['dcq_m'] = dcqM;
      if (tambon != null) request.fields['tambon'] = tambon;
      if (amphoe != null) request.fields['amphoe'] = amphoe;
      if (province != null) request.fields['province'] = province;
      if (pointDate != null) request.fields['point_date'] = pointDate;
      if (job != null) request.fields['job'] = job;
      if (gnss != null) request.fields['gnss'] = gnss;
      if (rf1 != null) request.fields['rf_1'] = rf1;
      if (distanceM1 != null) request.fields['distance_m_1'] = distanceM1;
      if (az1 != null) request.fields['az_1'] = az1;
      if (rf2 != null) request.fields['rf_2'] = rf2;
      if (distanceM2 != null) request.fields['distance_m_2'] = distanceM2;
      if (az2 != null) request.fields['az_2'] = az2;
      if (surveyTechnician != null)
        request.fields['survey_technician'] = surveyTechnician.toString();
      if (surveyQc != null) request.fields['survey_qc'] = surveyQc.toString();

      if (pointNote != null) {
        request.fields['point_note'] = pointNote;
      }

      // json >> draw / details
      if (drawDataJson != null) {
        request.fields['draw_data_json'] = drawDataJson;
      }
      if (detailsDataJson != null) {
        request.fields['details_data_json'] = detailsDataJson;
      }

      void addImage(String field, Uint8List? bytes) {
        if (bytes == null) return;
        request.files.add(http.MultipartFile.fromBytes(
          field, bytes,
          filename: '$field.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      addImage('point_zoomin_img', pointZoominImg);
      addImage('point_zoomout_img', pointZoomoutImg);
      addImage('draw_img', drawImg);
      addImage('details_img', detailsImg);
      addImage('draw_description_img', drawDescriptionImg);
      addImage('point_survey_img', pointSurveyImg);
      addImage('point_controller_img', pointControllerImg);
      addImage('n_survey_img', nSurveyImg);
      addImage('s_survey_img', sSurveyImg);
      addImage('e_survey_img', eSurveyImg);
      addImage('w_survey_img', wSurveyImg);

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'] ?? 'สร้าง Point ไม่สำเร็จ';
      }

      final point = PointModel.fromJson(jsonDecode(res.body));

      // cache ลง SQLite
      await _local.insertPoint(point);

      return point;
    } catch (e) {
      // ถ้า API fail >> บันทึกลง SQLite >> sync ทีหลัง
      try {
        final tempId = -DateTime
            .now()
            .millisecondsSinceEpoch;

        // ── บันทึกรูปทั้งหมดลงเครื่อง ──────────────────────────
        final savedPaths = await _pendingImages.saveImages(
          pointId: tempId,
          images: {
            'point_zoomin_img': pointZoominImg,
            'point_zoomout_img': pointZoomoutImg,
            'draw_img': drawImg,
            'details_img': detailsImg,
            'draw_description_img': drawDescriptionImg,
            'point_survey_img': pointSurveyImg,
            'point_controller_img': pointControllerImg,
            'n_survey_img': nSurveyImg,
            's_survey_img': sSurveyImg,
            'e_survey_img': eSurveyImg,
            'w_survey_img': wSurveyImg,
          },
        );

        final offlinePoint = PointModel(
          id: tempId,
          projectId: projectId,
          pointName: pointName,
          northing: northing,
          easting: easting,
          heightM: heightM,
          ellipsoidalM: ellipsoidalM,
          antennaM: antennaM,
          datum: datum,
          utm: utm,
          egm: egm,
          surveyMain: surveyMain,
          surveySub: surveySub,
          gdopM: gdopM,
          pdopM: pdopM,
          hdopM: hdopM,
          dcqM: dcqM,
          tambon: tambon,
          amphoe: amphoe,
          province: province,
          pointDate: pointDate,

          pointZoominImg: savedPaths['point_zoomin_img'],
          pointZoomoutImg: savedPaths['point_zoomout_img'],

          drawImg: savedPaths['draw_img'],
          drawDataJson: drawDataJson,
          detailsImg: savedPaths['details_img'],
          detailsDataJson: detailsDataJson,

          drawDescriptionImg: savedPaths['draw_description_img'],

          job: job,
          gnss: gnss,
          rf1: rf1,
          distanceM1: distanceM1,
          az1: az1,
          rf2: rf2,
          distanceM2: distanceM2,
          az2: az2,

          pointSurveyImg: savedPaths['point_survey_img'],
          pointControllerImg: savedPaths['point_controller_img'],
          nSurveyImg: savedPaths['n_survey_img'],
          sSurveyImg: savedPaths['s_survey_img'],
          eSurveyImg: savedPaths['e_survey_img'],
          wSurveyImg: savedPaths['w_survey_img'],

          surveyTechnician: surveyTechnician,
          surveyQc: surveyQc,
          pointNote: pointNote,
        );

        await _local.insertPoint(offlinePoint, isSynced: 1);
        return offlinePoint;
      } catch (e2) {
        rethrow;
      }
    }
  }


  /// ── ดึง Point ทั้งหมดของโครงการ ──────────────────────────
  Future<List<PointModel>> getPoints({
    required String token,
    required int projectId,
  }) async {
    try {
      // sync point ที่ค้างก่อน
      await syncUnsyncedPoints(token: token);
      await syncUpdatedPendingPoints(token: token);

      final res = await http.get(
        Uri.parse('${Constants.backendUri}/points/points/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'ดึงข้อมูลหมุดรังวัดไม่สำเร็จ';
      }

      final List<dynamic> data = jsonDecode(res.body);
      final points = data.map((e) => PointModel.fromJson(e)).toList();

      await _local.clearPointsByProject(projectId);
      await _local.insertPoints(points);

      return points;
    } catch (e) {
      final localPoints = await _local.getPoints(projectId: projectId);
      return localPoints;
    }
  }


  /// ── อัปเดต Point ──────────────────────────────────────────
  Future<PointModel> updatePoint({
    required String token,
    required int pointId,
    required String pointName,
    String? northing,
    String? easting,
    String? heightM,
    String? ellipsoidalM,
    String? antennaM,
    String? datum,
    String? utm,
    String? egm,
    String? surveyMain,
    String? surveySub,
    String? gdopM,
    String? pdopM,
    String? hdopM,
    String? dcqM,
    String? tambon,
    String? amphoe,
    String? province,
    String? pointDate,
    Uint8List? pointZoominImg,
    Uint8List? pointZoomoutImg,
    Uint8List? drawImg,
    String? drawDataJson,
    Uint8List? detailsImg,
    String? detailsDataJson,

    Uint8List? drawDescriptionImg,

    String? job,
    String? gnss,
    String? rf1,
    String? distanceM1,
    String? az1,
    String? rf2,
    String? distanceM2,
    String? az2,
    Uint8List? pointSurveyImg,
    Uint8List? pointControllerImg,
    Uint8List? nSurveyImg,
    Uint8List? sSurveyImg,
    Uint8List? eSurveyImg,
    Uint8List? wSurveyImg,
    int? surveyTechnician,
    int? surveyQc,
    String? pointNote,

    List<String> removeImageFields = const [],
  }) async {
    try {
      final point = await _updatePointRaw(
        token: token,
        pointId: pointId,
        pointName: pointName,
        northing: northing,
        easting: easting,
        heightM: heightM,
        ellipsoidalM: ellipsoidalM,
        antennaM: antennaM,
        datum: datum,
        utm: utm,
        egm: egm,
        surveyMain: surveyMain,
        surveySub: surveySub,
        gdopM: gdopM,
        pdopM: pdopM,
        hdopM: hdopM,
        dcqM: dcqM,
        tambon: tambon,
        amphoe: amphoe,
        province: province,
        pointDate: pointDate,
        pointZoominImg: pointZoominImg,
        pointZoomoutImg: pointZoomoutImg,

        drawImg: drawImg,
        drawDataJson: drawDataJson,
        detailsImg: detailsImg,
        detailsDataJson: detailsDataJson,

        drawDescriptionImg: drawDescriptionImg,

        job: job,
        gnss: gnss,
        rf1: rf1,
        distanceM1: distanceM1,
        az1: az1,
        rf2: rf2,
        distanceM2: distanceM2,
        az2: az2,
        pointSurveyImg: pointSurveyImg,
        pointControllerImg: pointControllerImg,
        nSurveyImg: nSurveyImg,
        sSurveyImg: sSurveyImg,
        eSurveyImg: eSurveyImg,
        wSurveyImg: wSurveyImg,
        surveyTechnician: surveyTechnician,
        surveyQc: surveyQc,
        pointNote: pointNote,

        removeImageFields: removeImageFields,
      );

      await _local.updatePoint(point);
      return point;
    } catch (e) {
      try {
        final existing = await _local.getPointById(pointId);
        if (existing == null) throw 'ไม่พบข้อมูลหมุดรังวัดสำหรับแก้ไขขณะ offline';

        final savedPaths = await _pendingImages.saveImages(
          pointId: pointId,
          images: {
            'point_zoomin_img': pointZoominImg,
            'point_zoomout_img': pointZoomoutImg,
            'draw_img': drawImg,
            'details_img': detailsImg,
            'draw_description_img': drawDescriptionImg,
            'point_survey_img': pointSurveyImg,
            'point_controller_img': pointControllerImg,
            'n_survey_img': nSurveyImg,
            's_survey_img': sSurveyImg,
            'e_survey_img': eSurveyImg,
            'w_survey_img': wSurveyImg,
          },
        );

        final offlinePoint = existing.copyWithLocal(
          pointName: pointName,
          northing: northing,
          easting: easting,
          heightM: heightM,
          ellipsoidalM: ellipsoidalM,
          antennaM: antennaM,
          datum: datum,
          utm: utm,
          egm: egm,
          surveyMain: surveyMain,
          surveySub: surveySub,
          gdopM: gdopM,
          pdopM: pdopM,
          hdopM: hdopM,
          dcqM: dcqM,
          tambon: tambon,
          amphoe: amphoe,
          province: province,
          pointDate: pointDate,
          pointZoominImg: savedPaths['point_zoomin_img'],
          pointZoomoutImg: savedPaths['point_zoomout_img'],

          drawImg: savedPaths['draw_img'],
          drawDataJson: drawDataJson,
          detailsImg: savedPaths['details_img'],
          detailsDataJson: detailsDataJson,

          drawDescriptionImg: savedPaths['draw_description_img'],

          job: job,
          gnss: gnss,
          rf1: rf1,
          distanceM1: distanceM1,
          az1: az1,
          rf2: rf2,
          distanceM2: distanceM2,
          az2: az2,
          pointSurveyImg: savedPaths['point_survey_img'],
          pointControllerImg: savedPaths['point_controller_img'],
          nSurveyImg: savedPaths['n_survey_img'],
          sSurveyImg: savedPaths['s_survey_img'],
          eSurveyImg: savedPaths['e_survey_img'],
          wSurveyImg: savedPaths['w_survey_img'],
          surveyTechnician: surveyTechnician,
          surveyQc: surveyQc,
          pointNote: pointNote,

          removedFields: removeImageFields,
        );

        if (pointId < 0) {
          await _local.insertPoint(offlinePoint, isSynced: 1);
        } else {
          await _local.updatePointPending(offlinePoint);
        }
        return offlinePoint;
      } catch (e2) {
        rethrow;
      }
    }
  }


  /// ── ลบ Point ──────────────────────────────────────────────
  Future<void> deletePoint({
    required String token,
    required int pointId,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse('${Constants.backendUri}/points/delete_point/$pointId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'] ?? 'ลบหมุดรังวัดไม่สำเร็จ';
      }

      await _local.deletePoint(pointId);
    } catch (e) {
      throw AppException(safeErrorMessage(e, fallback: 'ลบหมุดรังวัดไม่สำเร็จ'), e);
    }
  }


  /* ============================================================
    ส่วนจัดการ sync Point
  ============================================================ */
  /// ── sync point ที่สร้างขณะ offline ขึ้น server ────────────
  Future<void> syncUnsyncedPoints({required String token}) async {
    final pending = await _local.getUnsyncedPoints();
    if (pending.isEmpty) return;

    for (final p in pending) {
      // ข้าม point ที่ project ยังไม่ sync
      if (p.projectId < 0) continue;

      try {
        // อ่านทุก field รูป
        final images = await _readAllImageBytes(p);

        final synced = await _createPointRaw(
          token: token,
          projectId: p.projectId,
          pointName: p.pointName,
          northing: p.northing,
          easting: p.easting,
          heightM: p.heightM,
          ellipsoidalM: p.ellipsoidalM,
          antennaM: p.antennaM,
          datum: p.datum,
          utm: p.utm,
          egm: p.egm,
          surveyMain: p.surveyMain,
          surveySub: p.surveySub,
          gdopM: p.gdopM,
          pdopM: p.pdopM,
          hdopM: p.hdopM,
          dcqM: p.dcqM,
          tambon: p.tambon,
          amphoe: p.amphoe,
          province: p.province,
          pointDate: p.pointDate,
          pointZoominImg: images['point_zoomin_img'],
          pointZoomoutImg: images['point_zoomout_img'],

          drawImg: images['draw_img'],
          drawDataJson: p.drawDataJson,
          detailsImg: images['details_img'],
          detailsDataJson: p.detailsDataJson,

          drawDescriptionImg: images['draw_description_img'],

          job: p.job,
          gnss: p.gnss,
          rf1: p.rf1,
          distanceM1: p.distanceM1,
          az1: p.az1,
          rf2: p.rf2,
          distanceM2: p.distanceM2,
          az2: p.az2,
          pointSurveyImg: images['point_survey_img'],
          pointControllerImg: images['point_controller_img'],
          nSurveyImg: images['n_survey_img'],
          sSurveyImg: images['s_survey_img'],
          eSurveyImg: images['e_survey_img'],
          wSurveyImg: images['w_survey_img'],
          surveyTechnician: p.surveyTechnician,
          surveyQc: p.surveyQc,
          pointNote: p.pointNote,
        );

        // sync สำเร็จ >> ลบ temp row + temp files >> insert ข้อมูลจริง
        await _local.deletePoint(p.id);
        await _pendingImages.deletePointFolder(p.id);
        await _local.insertPoint(synced);

      } catch (_) {
        continue;
      }
    }
  }


  /// ── sync point ที่แก้ไขขณะ offline ขึ้น server ─────────
  Future<void> syncUpdatedPendingPoints({required String token}) async {
    final pending = await _local
        .getUpdatedPendingPoints();
    if (pending.isEmpty) return;

    for (final p in pending) {
      try {

        // ใช้ชื่อเดิมจาก sever
        final images = await _readAllImageBytes(p, onlyLocal: true);

        // เช็คว่า field ไหนเป็น null ใน SQLite ตอนนี้
        final removeFields = <String>[];
        if (p.pointZoominImg == null) removeFields.add('point_zoomin_img');
        if (p.pointZoomoutImg == null) removeFields.add('point_zoomout_img');
        if (p.pointSurveyImg == null) removeFields.add('point_survey_img');
        if (p.pointControllerImg == null) removeFields.add('point_controller_img');
        if (p.nSurveyImg == null) removeFields.add('n_survey_img');
        if (p.sSurveyImg == null) removeFields.add('s_survey_img');
        if (p.eSurveyImg == null) removeFields.add('e_survey_img');
        if (p.wSurveyImg == null) removeFields.add('w_survey_img');

        final synced = await _updatePointRaw(
          token: token,
          pointId: p.id,
          pointName: p.pointName,
          northing: p.northing,
          easting: p.easting,
          heightM: p.heightM,
          ellipsoidalM: p.ellipsoidalM,
          antennaM: p.antennaM,
          datum: p.datum,
          utm: p.utm,
          egm: p.egm,
          surveyMain: p.surveyMain,
          surveySub: p.surveySub,
          gdopM: p.gdopM,
          pdopM: p.pdopM,
          hdopM: p.hdopM,
          dcqM: p.dcqM,
          tambon: p.tambon,
          amphoe: p.amphoe,
          province: p.province,
          pointDate: p.pointDate,
          pointZoominImg: images['point_zoomin_img'],
          pointZoomoutImg: images['point_zoomout_img'],

          drawImg: images['draw_img'],
          drawDataJson: p.drawDataJson,
          detailsImg: images['details_img'],
          detailsDataJson: p.detailsDataJson,

          drawDescriptionImg: images['draw_description_img'],

          job: p.job,
          gnss: p.gnss,
          rf1: p.rf1,
          distanceM1: p.distanceM1,
          az1: p.az1,
          rf2: p.rf2,
          distanceM2: p.distanceM2,
          az2: p.az2,
          pointSurveyImg: images['point_survey_img'],
          pointControllerImg: images['point_controller_img'],
          nSurveyImg: images['n_survey_img'],
          sSurveyImg: images['s_survey_img'],
          eSurveyImg: images['e_survey_img'],
          wSurveyImg: images['w_survey_img'],
          surveyTechnician: p.surveyTechnician,
          surveyQc: p.surveyQc,
          pointNote: p.pointNote,
        );

        await _local.updatePoint(synced);
        await _local.markUpdateSynced(p.id);
        await _pendingImages.deletePointFolder(
            p.id);

      } catch (_) {
        continue;
      }
    }
  }


  /* ============================================================
    ส่วนจัดการ HTTP call Point
  ============================================================ */
  /// ── HTTP call (ใช้ทั้งจาก createPoint และ syncUnsyncedPoints) ──
  Future<PointModel> _createPointRaw({
    required String token,
    required int projectId,
    required String pointName,

    // UTM
    String? northing,
    String? easting,
    String? heightM,
    String? ellipsoidalM,
    String? antennaM,
    String? datum,
    String? utm,
    String? egm,

    // Survey
    String? surveyMain,
    String? surveySub,

    // GDOP
    String? gdopM,
    String? pdopM,
    String? hdopM,
    String? dcqM,

    // ตำบล อำเภอ จังหวัด วันที่
    String? tambon,
    String? amphoe,
    String? province,
    String? pointDate,

    // รูปแสดงบริเวณหมุดรังวัด
    Uint8List? pointZoominImg,
    Uint8List? pointZoomoutImg,

    // รูปวาดภาคสนาม / รายละเอียด
    Uint8List? drawImg,
    String? drawDataJson,
    Uint8List? detailsImg,
    String? detailsDataJson,

    Uint8List? drawDescriptionImg,

    // JOB
    String? job,
    String? gnss,
    String? rf1,
    String? distanceM1,
    String? az1,
    String? rf2,
    String? distanceM2,
    String? az2,

    // รูปถ่ายประกอบ
    Uint8List? pointSurveyImg,
    Uint8List? pointControllerImg,
    Uint8List? nSurveyImg,
    Uint8List? sSurveyImg,
    Uint8List? eSurveyImg,
    Uint8List? wSurveyImg,

    // ผู้รังวัด / ผู้ตรวจสอบ
    int? surveyTechnician,
    int? surveyQc,

    String? pointNote
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Constants.backendUri}/points/create_point'),
    );

    request.headers['x-auth-token'] = token;
    request.fields['project_id'] = projectId.toString();
    request.fields['point_name'] = pointName;

    if (northing != null) request.fields['northing'] = northing;
    if (easting != null) request.fields['easting'] = easting;
    if (heightM != null) request.fields['height_m'] = heightM;
    if (ellipsoidalM != null) request.fields['ellipsoidal_m'] = ellipsoidalM;
    if (antennaM != null) request.fields['antenna_m'] = antennaM;
    if (datum != null) request.fields['datum'] = datum;
    if (utm != null) request.fields['utm'] = utm;
    if (egm != null) request.fields['egm'] = egm;
    if (surveyMain != null) request.fields['survey_main'] = surveyMain;
    if (surveySub != null) request.fields['survey_sub'] = surveySub;
    if (gdopM != null) request.fields['gdop_m'] = gdopM;
    if (pdopM != null) request.fields['pdop_m'] = pdopM;
    if (hdopM != null) request.fields['hdop_m'] = hdopM;
    if (dcqM != null) request.fields['dcq_m'] = dcqM;
    if (tambon != null) request.fields['tambon'] = tambon;
    if (amphoe != null) request.fields['amphoe'] = amphoe;
    if (province != null) request.fields['province'] = province;
    if (pointDate != null) request.fields['point_date'] = pointDate;
    if (job != null) request.fields['job'] = job;
    if (gnss != null) request.fields['gnss'] = gnss;
    if (rf1 != null) request.fields['rf_1'] = rf1;
    if (distanceM1 != null) request.fields['distance_m_1'] = distanceM1;
    if (az1 != null) request.fields['az_1'] = az1;
    if (rf2 != null) request.fields['rf_2'] = rf2;
    if (distanceM2 != null) request.fields['distance_m_2'] = distanceM2;
    if (az2 != null) request.fields['az_2'] = az2;
    if (surveyTechnician != null)
      request.fields['survey_technician'] = surveyTechnician.toString();
    if (surveyQc != null) request.fields['survey_qc'] = surveyQc.toString();

    if (pointNote != null) {
      request.fields['point_note'] = pointNote;
    }

    // Json draw / details
    if (drawDataJson != null) {
      request.fields['draw_data_json'] = drawDataJson;
    }
    if (detailsDataJson != null) {
      request.fields['details_data_json'] = detailsDataJson;
    }

    void addImage(String field, Uint8List? bytes) {
      if (bytes == null) return;
      request.files.add(http.MultipartFile.fromBytes(
        field, bytes,
        filename: '$field.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    addImage('point_zoomin_img', pointZoominImg);
    addImage('point_zoomout_img', pointZoomoutImg);
    addImage('draw_img', drawImg);
    addImage('details_img', detailsImg);
    addImage('draw_description_img', drawDescriptionImg);
    addImage('point_survey_img', pointSurveyImg);
    addImage('point_controller_img', pointControllerImg);
    addImage('n_survey_img', nSurveyImg);
    addImage('s_survey_img', sSurveyImg);
    addImage('e_survey_img', eSurveyImg);
    addImage('w_survey_img', wSurveyImg);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 201) {
      throw jsonDecode(res.body)['error'] ?? 'สร้างหมุดรังวัดไม่สำเร็จ';
    }
    return PointModel.fromJson(jsonDecode(res.body));
  }


  /// ── HTTP call (ใช้ทั้งจาก updatePoint และ syncUpdatedPendingPoints) ──
  Future<PointModel> _updatePointRaw({
    required String token,
    required int pointId,
    required String pointName,
    String? northing,
    String? easting,
    String? heightM,
    String? ellipsoidalM,
    String? antennaM,
    String? datum,
    String? utm,
    String? egm,
    String? surveyMain,
    String? surveySub,
    String? gdopM,
    String? pdopM,
    String? hdopM,
    String? dcqM,
    String? tambon,
    String? amphoe,
    String? province,
    String? pointDate,
    Uint8List? pointZoominImg,
    Uint8List? pointZoomoutImg,
    Uint8List? drawImg,
    String? drawDataJson,
    Uint8List? detailsImg,
    String? detailsDataJson,

    Uint8List? drawDescriptionImg,

    String? job,
    String? gnss,
    String? rf1,
    String? distanceM1,
    String? az1,
    String? rf2,
    String? distanceM2,
    String? az2,
    Uint8List? pointSurveyImg,
    Uint8List? pointControllerImg,
    Uint8List? nSurveyImg,
    Uint8List? sSurveyImg,
    Uint8List? eSurveyImg,
    Uint8List? wSurveyImg,
    int? surveyTechnician,
    int? surveyQc,
    String? pointNote,

    List<String> removeImageFields = const [],
  }) async {
    var request = http.MultipartRequest(
      'PUT',
      Uri.parse('${Constants.backendUri}/points/update_point/$pointId'),
    );
    request.headers['x-auth-token'] = token;

    request.fields['point_name'] = pointName;
    request.fields['northing'] = northing ?? '';
    request.fields['easting'] = easting ?? '';
    request.fields['height_m'] = heightM ?? '';
    request.fields['ellipsoidal_m'] = ellipsoidalM ?? '';
    request.fields['antenna_m'] = antennaM ?? '';

    request.fields['datum'] = datum ?? '';
    request.fields['utm'] = utm ?? '';
    request.fields['egm'] = egm ?? '';

    request.fields['survey_main'] = surveyMain ?? '';
    request.fields['survey_sub'] = surveySub ?? '';

    request.fields['gdop_m'] = gdopM ?? '';
    request.fields['pdop_m'] = pdopM ?? '';
    request.fields['hdop_m'] = hdopM ?? '';
    request.fields['dcq_m'] = dcqM ?? '';

    request.fields['tambon'] = tambon ?? '';
    request.fields['amphoe'] = amphoe ?? '';
    request.fields['province'] = province ?? '';

    request.fields['point_date'] = pointDate ?? '';

    request.fields['job'] = job ?? '';
    request.fields['gnss'] = gnss ?? '';

    request.fields['rf_1'] = rf1 ?? '';
    request.fields['distance_m_1'] = distanceM1 ?? '';
    request.fields['az_1'] = az1 ?? '';

    request.fields['rf_2'] = rf2 ?? '';
    request.fields['distance_m_2'] = distanceM2 ?? '';
    request.fields['az_2'] = az2 ?? '';

    request.fields['survey_technician'] = surveyTechnician?.toString() ?? '';
    request.fields['survey_qc'] = surveyQc?.toString() ?? '';
    request.fields['point_note'] = pointNote ?? '';

    // ส่งเฉพาะตอนมีค่า (ไม่ได้แก้ไข = ไม่ส่ง = backend คงค่าเดิม)
    if (drawDataJson != null) {
      request.fields['draw_data_json'] = drawDataJson;
    }
    if (detailsDataJson != null) {
      request.fields['details_data_json'] = detailsDataJson;
    }

    // บอก server ว่า field ไหนต้องเคลียร์ทิ้ง
    if (removeImageFields.isNotEmpty) {
      request.fields['remove_images'] = removeImageFields.join(',');
    }

    void addImage(String field, Uint8List? bytes) {
      if (bytes == null) return;
      request.files.add(http.MultipartFile.fromBytes(
        field, bytes,
        filename: '$field.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    addImage('point_zoomin_img', pointZoominImg);
    addImage('point_zoomout_img', pointZoomoutImg);
    addImage('draw_img', drawImg);
    addImage('details_img', detailsImg);
    addImage('draw_description_img', drawDescriptionImg);
    addImage('point_survey_img', pointSurveyImg);
    addImage('point_controller_img', pointControllerImg);
    addImage('n_survey_img', nSurveyImg);
    addImage('s_survey_img', sSurveyImg);
    addImage('e_survey_img', eSurveyImg);
    addImage('w_survey_img', wSurveyImg);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw jsonDecode(res.body)['error'] ?? 'อัปเดตหมุดรังวัดไม่สำเร็จ';
    }

    return PointModel.fromJson(jsonDecode(res.body));
  }


}