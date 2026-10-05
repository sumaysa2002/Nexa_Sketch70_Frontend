import 'dart:convert';

class PointModel {
  final int id;
  final int projectId;
  final String pointName;

  // UTM
  final String? northing;
  final String? easting;
  final String? heightM;
  final String? ellipsoidalM;
  final String? antennaM;
  final String? datum;
  final String? utm;
  final String? egm;

  // Survey
  final String? surveyMain;
  final String? surveySub;

  // DOP
  final String? gdopM;
  final String? pdopM;
  final String? hdopM;
  final String? dcqM;

  // ตำบล อำเภอ จังหวัด วันที่
  final String? tambon;
  final String? amphoe;
  final String? province;
  final String? pointDate;

  // รูปแสดงบริเวณหมุดรังวัด
  final String? pointZoominImg;
  final String? pointZoomoutImg;

  // รูปวาดภาคสนาม / รายละเอียด
  final String? drawImg;
  final String? drawDataJson;
  final String? detailsImg;
  final String? detailsDataJson;

  final String? drawDescriptionImg;

  // JOB
  final String? job;
  final String? gnss;
  final String? rf1;
  final String? distanceM1;
  final String? az1;
  final String? rf2;
  final String? distanceM2;
  final String? az2;

  // รูปถ่ายประกอบ
  final String? pointSurveyImg;
  final String? pointControllerImg;
  final String? nSurveyImg;
  final String? sSurveyImg;
  final String? eSurveyImg;
  final String? wSurveyImg;

  // ผู้รังวัด / ผู้ตรวจสอบ
  final int? surveyTechnician;
  final int? surveyQc;

  final String? pointNote;

  PointModel({
    required this.id,
    required this.projectId,
    required this.pointName,
    this.northing,
    this.easting,
    this.heightM,
    this.ellipsoidalM,
    this.antennaM,
    this.datum,
    this.utm,
    this.egm,
    this.surveyMain,
    this.surveySub,
    this.gdopM,
    this.pdopM,
    this.hdopM,
    this.dcqM,
    this.tambon,
    this.amphoe,
    this.province,
    this.pointDate,
    this.pointZoominImg,
    this.pointZoomoutImg,
    this.drawImg,
    this.drawDataJson,
    this.detailsImg,
    this.detailsDataJson,

    this.drawDescriptionImg,

    this.job,
    this.gnss,
    this.rf1,
    this.distanceM1,
    this.az1,
    this.rf2,
    this.distanceM2,
    this.az2,
    this.pointSurveyImg,
    this.pointControllerImg,
    this.nSurveyImg,
    this.sSurveyImg,
    this.eSurveyImg,
    this.wSurveyImg,
    this.surveyTechnician,
    this.surveyQc,
    this.pointNote
  });


  // ── copyWith ──────────────────────────────────────────────
  PointModel copyWithLocal({
    String? pointName,
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

    String? pointZoominImg,
    String? pointZoomoutImg,

    String? drawImg,
    String? drawDataJson,
    String? detailsImg,
    String? detailsDataJson,

    String? drawDescriptionImg,

    String? job,
    String? gnss,
    String? rf1,
    String? distanceM1,
    String? az1,
    String? rf2,
    String? distanceM2,
    String? az2,

    String? pointSurveyImg,
    String? pointControllerImg,
    String? nSurveyImg,
    String? sSurveyImg,
    String? eSurveyImg,
    String? wSurveyImg,

    int? surveyTechnician,
    int? surveyQc,

    String? pointNote,

    List<String> removedFields = const [],
  }) {

    // ถ้าลบไฟล์ >> คืนค่า null
    String? resolveImage(String fieldKey, String? newValue, String? oldValue) {
      if (removedFields.contains(fieldKey)) return null;
      return newValue ?? oldValue;
    }

    return PointModel(
      id: id,
      projectId: projectId,
      pointName: pointName ?? this.pointName,
      northing: northing ?? this.northing,
      easting: easting ?? this.easting,
      heightM: heightM ?? this.heightM,
      ellipsoidalM: ellipsoidalM ?? this.ellipsoidalM,
      antennaM: antennaM ?? this.antennaM,
      datum: datum ?? this.datum,
      utm: utm ?? this.utm,
      egm: egm ?? this.egm,

      surveyMain: surveyMain ?? this.surveyMain,
      surveySub: surveySub ?? this.surveySub,

      gdopM: gdopM ?? this.gdopM,
      pdopM: pdopM ?? this.pdopM,
      hdopM: hdopM ?? this.hdopM,
      dcqM: dcqM ?? this.dcqM,

      tambon: tambon ?? this.tambon,
      amphoe: amphoe ?? this.amphoe,
      province: province ?? this.province,
      pointDate: pointDate ?? this.pointDate,

      // ประเภทไฟล์ภาพ >> สามารถลบภาพได้ (ใช้ resolveImage)
      pointZoominImg: resolveImage('point_zoomin_img', pointZoominImg, this.pointZoominImg),
      pointZoomoutImg: resolveImage('point_zoomout_img', pointZoomoutImg, this.pointZoomoutImg),
      pointSurveyImg: resolveImage('point_survey_img', pointSurveyImg, this.pointSurveyImg),
      pointControllerImg: resolveImage('point_controller_img', pointControllerImg, this.pointControllerImg),
      nSurveyImg: resolveImage('n_survey_img', nSurveyImg, this.nSurveyImg),
      sSurveyImg: resolveImage('s_survey_img', sSurveyImg, this.sSurveyImg),
      eSurveyImg: resolveImage('e_survey_img', eSurveyImg, this.eSurveyImg),
      wSurveyImg: resolveImage('w_survey_img', wSurveyImg, this.wSurveyImg),

      // draw_img / details_img (ไม่สามารถลบไฟล์ภาพได้)
      drawImg: drawImg ?? this.drawImg,
      drawDataJson: drawDataJson ?? this.drawDataJson,
      detailsImg: detailsImg ?? this.detailsImg,
      detailsDataJson: detailsDataJson ?? this.detailsDataJson,

      drawDescriptionImg: drawDescriptionImg ?? this.drawDescriptionImg,

      job: job ?? this.job,
      gnss: gnss ?? this.gnss,
      rf1: rf1 ?? this.rf1,
      distanceM1: distanceM1 ?? this.distanceM1,
      az1: az1 ?? this.az1,
      rf2: rf2 ?? this.rf2,
      distanceM2: distanceM2 ?? this.distanceM2,
      az2: az2 ?? this.az2,

      surveyTechnician: surveyTechnician ?? this.surveyTechnician,
      surveyQc: surveyQc ?? this.surveyQc,

      pointNote: pointNote ?? this.pointNote,
    );
  }

  // ── fromJson ────────────────────────────────────
  factory PointModel.fromJson(Map<String, dynamic> json) {
    return PointModel(
      id:                   json['id'] as int,
      projectId:            json['project_id'] as int,
      pointName:            json['point_name'] as String,
      northing:             json['northing'] as String?,
      easting:              json['easting'] as String?,
      heightM:              json['height_m'] as String?,
      ellipsoidalM:         json['ellipsoidal_m'] as String?,
      antennaM:             json['antenna_m'] as String?,
      datum:                json['datum'] as String?,
      utm:                  json['utm'] as String?,
      egm:                  json['egm'] as String?,

      surveyMain:           json['survey_main'] as String?,
      surveySub:            json['survey_sub'] as String?,

      gdopM:                json['gdop_m'] as String?,
      pdopM:                json['pdop_m'] as String?,
      hdopM:                json['hdop_m'] as String?,
      dcqM:                 json['dcq_m'] as String?,

      tambon:               json['tambon'] as String?,
      amphoe:               json['amphoe'] as String?,
      province:             json['province'] as String?,
      pointDate:            json['point_date'] as String?,

      pointZoominImg:       json['point_zoomin_img'] as String?,
      pointZoomoutImg:      json['point_zoomout_img'] as String?,

      drawImg:              json['draw_img'] as String?,
      drawDataJson:         json['draw_data_json'] as String?,
      detailsImg:           json['details_img'] as String?,
      detailsDataJson:      json['details_data_json'] as String?,

      drawDescriptionImg:   json['draw_description_img'] as String?,

      job:                  json['job'] as String?,
      gnss:                 json['gnss'] as String?,
      rf1:                  json['rf_1'] as String?,
      distanceM1:           json['distance_m_1'] as String?,
      az1:                  json['az_1'] != null ? json['az_1'].toString() : null,
      rf2:                  json['rf_2'] as String?,
      distanceM2:           json['distance_m_2'] as String?,
      az2:                  json['az_2'] != null ? json['az_2'].toString() : null,

      pointSurveyImg:       json['point_survey_img'] as String?,
      pointControllerImg:   json['point_controller_img'] as String?,
      nSurveyImg:           json['n_survey_img'] as String?,
      sSurveyImg:           json['s_survey_img'] as String?,
      eSurveyImg:           json['e_survey_img'] as String?,
      wSurveyImg:           json['w_survey_img'] as String?,

      surveyTechnician:     json['survey_technician'] as int?,
      surveyQc:             json['survey_qc'] as int?,

      pointNote:            json['point_note'] as String?,
    );
  }

  // ── toJson ──────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':                   id,
    'project_id':           projectId,
    'point_name':           pointName,
    'northing':             northing,
    'easting':              easting,
    'height_m':             heightM,
    'ellipsoidal_m':        ellipsoidalM,
    'antenna_m':            antennaM,
    'datum':                datum,
    'utm':                  utm,
    'egm':                  egm,

    'survey_main':          surveyMain,
    'survey_sub':           surveySub,

    'gdop_m':               gdopM,
    'pdop_m':               pdopM,
    'hdop_m':               hdopM,
    'dcq_m':                dcqM,

    'tambon':               tambon,
    'amphoe':               amphoe,
    'province':             province,
    'point_date':           pointDate,

    'point_zoomin_img':     pointZoominImg,
    'point_zoomout_img':    pointZoomoutImg,

    'draw_img':             drawImg,
    'draw_data_json':       drawDataJson,
    'details_img':          detailsImg,
    'details_data_json':    detailsDataJson,

    'draw_description_img': drawDescriptionImg,

    'job':                  job,
    'gnss':                 gnss,
    'rf_1':                 rf1,
    'distance_m_1':         distanceM1,
    'az_1':                 az1,
    'rf_2':                 rf2,
    'distance_m_2':         distanceM2,
    'az_2':                 az2,

    'point_survey_img':     pointSurveyImg,
    'point_controller_img': pointControllerImg,
    'n_survey_img':         nSurveyImg,
    's_survey_img':         sSurveyImg,
    'e_survey_img':         eSurveyImg,
    'w_survey_img':         wSurveyImg,

    'survey_technician':    surveyTechnician,
    'survey_qc':            surveyQc,

    'point_note':            pointNote
  };
}