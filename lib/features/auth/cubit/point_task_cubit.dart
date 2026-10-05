import 'package:offline_gnss69_new/export.dart';

part 'point_task_state.dart';

class PointTaskCubit extends Cubit<PointTaskState> {
  PointTaskCubit() : super(PointTaskInitial());

  final pointtaskRemoteRepository = PointTaskRemoteRepository();

  /// ── ping เช็คว่า backend (API) ตอบสนองไหม ────────────
  Future<bool> _isApiAvailable(String token) async {
    try {
      return await pointtaskRemoteRepository.pingApi(token: token);
    } catch (_) {
      return false;
    }
  }


  /// ── สร้าง Point ใหม่ ──────────────────────────────────────
  Future<void> createPoint({
    required String token,
    required int projectId,
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
  }) async {
    try {
      emit(PointTaskLoading());

      final point = await pointtaskRemoteRepository.createPoint(
          token:               token,
          projectId:           projectId,
          pointName:           pointName,
          northing:            northing,
          easting:             easting,
          heightM:             heightM,
          ellipsoidalM:        ellipsoidalM,
          antennaM:            antennaM,
          datum:               datum,
          utm:                 utm,
          egm:                 egm,
          surveyMain:          surveyMain,
          surveySub:           surveySub,
          gdopM:               gdopM,
          pdopM:               pdopM,
          hdopM:               hdopM,
          dcqM:                dcqM,
          tambon:              tambon,
          amphoe:              amphoe,
          province:            province,
          pointDate:           pointDate,
          pointZoominImg:      pointZoominImg,
          pointZoomoutImg:     pointZoomoutImg,

          drawImg: drawImg,
          drawDataJson: drawDataJson,
          detailsImg: detailsImg,
          detailsDataJson: detailsDataJson,

          drawDescriptionImg: drawDescriptionImg,

          job:                 job,
          gnss:                gnss,
          rf1:                 rf1,
          distanceM1:          distanceM1,
          az1:                 az1,
          rf2:                 rf2,
          distanceM2:          distanceM2,
          az2:                 az2,
          pointSurveyImg:      pointSurveyImg,
          pointControllerImg:  pointControllerImg,
          nSurveyImg:          nSurveyImg,
          sSurveyImg:          sSurveyImg,
          eSurveyImg:          eSurveyImg,
          wSurveyImg:          wSurveyImg,
          surveyTechnician:    surveyTechnician,
          surveyQc:            surveyQc,
          pointNote: pointNote
      );

      emit(CreatePointSuccess(point));
    } catch (e) {
      emit(PointTaskError(safeErrorMessage(e)));
    }
  }

  /// ── ดึง Point ทั้งหมดของโครงการ ──────────────────────────
  Future<void> getPoints({
    required String token,
    required int projectId,
  }) async {
    try {
      emit(PointTaskLoading());
      final points = await pointtaskRemoteRepository.getPoints(token: token, projectId: projectId);
      emit(GetPointsSuccess(points));
    } catch (e) {
      emit(PointTaskError(safeErrorMessage(e)));
    }
  }


  /// ── อัปเดต Point ──────────────────────────────────────────
  Future<void> updatePoint({
    required String token,
    required int pointId,
    required int projectId,
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
      emit(PointTaskLoading());
      final point = await pointtaskRemoteRepository.updatePoint(
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
        surveyTechnician: surveyTechnician, surveyQc: surveyQc,
        pointNote: pointNote,

        removeImageFields: removeImageFields,
      );
      emit(UpdatePointSuccess(point));
      final points = await pointtaskRemoteRepository.getPoints(
        token: token,
        projectId: projectId,
      );
      emit(GetPointsSuccess(points));

    } catch (e) {
      emit(PointTaskError(safeErrorMessage(e)));
    }
  }


  /// ── ลบ Point ──────────────────────────────────────────────
  Future<void> deletePoint({
    required String token,
    required int pointId,
  }) async {
    emit(PointTaskLoading());

    // point offline >> ลบออกจาก SQLite ได้เลยไม่ต้องเช็ค API
    if (pointId < 0) {
      try {
        final local = PointTaskLocalRepository();
        await local.deletePoint(pointId);
        await PendingPointImageService().deletePointFolder(pointId);
        emit(DeletePointSuccess(pointId));
      } catch (e) {
        emit(PointTaskError(safeErrorMessage(e)));
      }
      return;
    }

    // point จริงบน server >> ต้องเช็ค API ก่อนเสมอ
    final apiAvailable = await _isApiAvailable(token);
    if (!apiAvailable) {
      emit(DeletePointOfflineError());
      return;
    }

    try {
      await pointtaskRemoteRepository.deletePoint(token: token, pointId: pointId);
      emit(DeletePointSuccess(pointId));
    } catch (e) {
      emit(PointTaskError(safeErrorMessage(e)));
    }
  }

  Future<void> syncPendingPoints({required String token}) async {
    await pointtaskRemoteRepository.syncUnsyncedPoints(token: token);
    await pointtaskRemoteRepository.syncUpdatedPendingPoints(token: token);
  }


}