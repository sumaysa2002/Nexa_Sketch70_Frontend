import 'dart:convert';

class ProjectModel {
  final int id;

  final String? nameProjectId;
  final String projectName;
  final String? projectDetails;
  final String? province;

  final String? sensor;
  final int? gsdNum;
  final String? gsdUnit;

  final String? surveyMain;
  final String? surveySub;

  final String? projectStartDate;
  final String? projectEndDate;

  final String? projectNote;

  final List<int> memberIds;
  final String? projectTimeCreated;
  final String? userRole;     // เก็บสถานะ 'Editor' | 'Viewer'
  final int? creatorAdminId;  // เก็บ admin id ของผู้สร้างโครงการ

  ProjectModel({
    required this.id,
    this.nameProjectId,
    required this.projectName,
    this.projectDetails,
    this.province,
    this.sensor,
    this.gsdNum,
    this.gsdUnit,
    this.surveyMain,
    this.surveySub,
    this.projectStartDate,
    this.projectEndDate,
    this.projectNote,
    this.memberIds = const [],
    this.projectTimeCreated,
    this.userRole,
    this.creatorAdminId,
  });

  // ── copyWith ──────────────────────────────────────────────
  ProjectModel copyWith({
    int? id,
    String? nameProjectId,
    String? projectName,
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
    List<int>? memberIds,
    String? projectTimeCreated,
    int? creatorAdminId
  }) {
    return ProjectModel(
      id:                   id ?? this.id,
      nameProjectId:        nameProjectId ?? this.nameProjectId,
      projectName:          projectName ?? this.projectName,
      projectDetails:       projectDetails ?? this.projectDetails,
      province:             province ?? this.province,
      sensor:               sensor ?? this.sensor,
      gsdNum:               gsdNum ?? this.gsdNum,
      gsdUnit:              gsdUnit ?? this.gsdUnit,
      surveyMain:           surveyMain ?? this.surveyMain,
      surveySub:            surveySub ?? this.surveySub,
      projectStartDate:     projectStartDate ?? this.projectStartDate,
      projectEndDate:       projectEndDate ?? this.projectEndDate,
      projectNote:          projectNote ?? this.projectNote,
      userRole:             userRole ?? this.userRole,
      memberIds:            memberIds ?? this.memberIds,
      projectTimeCreated:   projectTimeCreated ?? this.projectTimeCreated,
      creatorAdminId:       creatorAdminId ?? this.creatorAdminId,
    );
  }

  // ── fromJson ────────────────────────────────────
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id:                   json['id'] as int,
      nameProjectId:        json['name_project_id'] as String?,
      projectName:          json['project_name'] as String,
      projectDetails:       json['project_details'] as String?,
      province:             json['province'] as String?,
      sensor:               json['sensor'] as String?,
      gsdNum:               json['gsd_num'] as int?,
      gsdUnit:              json['gsd_unit'] as String?,
      surveyMain:           json['survey_main'] as String?,
      surveySub:            json['survey_sub'] as String?,
      projectStartDate:     json['project_start_date'] as String?,
      projectEndDate:       json['project_end_date'] as String?,
      projectNote:          json['project_note'] as String?,
      memberIds:            (json['member_ids'] as List<dynamic>?)
                              ?.map((e) => e as int)
                              .toList() ?? [],
      projectTimeCreated:   json['project_time_created'] as String?,

      userRole:             json['user_role'] as String?,

      creatorAdminId:       json['project_user_creator'] as int?,
    );
  }

  // ── toJson ──────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id':                   id,
    'name_project_id':      nameProjectId,
    'project_name':         projectName,
    'project_details':      projectDetails,
    'province':             province,
    'sensor':               sensor,
    'gsd_num':              gsdNum,
    'gsd_unit':             gsdUnit,
    'survey_main':          surveyMain,
    'survey_sub':           surveySub,
    'project_start_date':   projectStartDate,
    'project_end_date':     projectEndDate,
    'project_note':         projectNote,
    'member_ids':           memberIds,
    'project_time_created': projectTimeCreated,
    'user_role': userRole,
    'creator_admin_id':     creatorAdminId,
  };

  // ── == ────────────────────────────────────────────────────
  @override
  bool operator ==(covariant ProjectModel other) {
    if (identical(this, other)) return true;
    return other.id == id &&
        other.nameProjectId == nameProjectId &&
        other.projectName == projectName &&
        other.projectDetails == projectDetails &&
        other.province == province &&
        other.sensor == sensor &&
        other.gsdNum == gsdNum &&
        other.gsdUnit == gsdUnit &&
        other.surveyMain == surveyMain &&
        other.surveySub == surveySub &&
        other.projectStartDate == projectStartDate &&
        other.projectEndDate == projectEndDate &&
        other.projectNote == projectNote &&
        other.memberIds.toString() == memberIds.toString() &&
        other.projectTimeCreated == projectTimeCreated &&
        other.creatorAdminId == creatorAdminId;
  }

  // ── hashCode ──────────────────────────────────────────────
  @override
  int get hashCode =>
      id.hashCode ^
      nameProjectId.hashCode ^
      projectName.hashCode ^
      projectDetails.hashCode ^
      province.hashCode ^
      sensor.hashCode ^
      gsdNum.hashCode ^
      gsdUnit.hashCode ^
      surveyMain.hashCode ^
      surveySub.hashCode ^
      projectStartDate.hashCode ^
      projectEndDate.hashCode ^
      projectNote.hashCode ^
      memberIds.hashCode ^
      projectTimeCreated.hashCode^
      creatorAdminId.hashCode;

  // ── toString ──────────────────────────────────────────────
  @override
  String toString() {
    return 'ProjectModel(id: $id, projectName: $projectName, province: $province, '
        'startDate: $projectStartDate, endDate: $projectEndDate, '
        'members: $memberIds, createdAt: $projectTimeCreated)';
  }
}