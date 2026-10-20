import 'package:offline_gnss69_new/export.dart';

class Point_Detail_Viewer_Page extends StatefulWidget {
  final PointModel point;

  static MaterialPageRoute route(PointModel point) => MaterialPageRoute(
    builder: (context) => Point_Detail_Viewer_Page(point: point),
  );

  const Point_Detail_Viewer_Page({super.key, required this.point});

  @override
  State<Point_Detail_Viewer_Page> createState() => _Point_Detail_Viewer_PageState();
}

class _Point_Detail_Viewer_PageState extends State<Point_Detail_Viewer_Page> {

  // ข้อมูล null >> '-'
  String _d(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

  // รูป signature
  String? _sigUrl(String? filename) {
    if (filename == null) return null;
    return SecureImage.signatureUrl(filename);
  }

  UserModel? _technician;
  UserModel? _qc;
  bool _usersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // โหลด user จาก id
  Future<void> _loadUsers() async {
    final techId = widget.point.surveyTechnician;
    final qcId   = widget.point.surveyQc;

    if (techId == null && qcId == null) {
      setState(() => _usersLoaded = true);
      return;
    }

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthLoggedIn) return;

      final repo     = AuthRemoteRepository();
      final ids      = [techId, qcId].whereType<int>().toList();
      final allUsers = await repo.getUsersByIds(token: authState.userModel.token, ids: ids);

      setState(() {
        _technician  = techId != null
            ? allUsers.where((u) => u.id == techId).firstOrNull
            : null;
        _qc          = qcId != null
            ? allUsers.where((u) => u.id == qcId).firstOrNull
            : null;
        _usersLoaded = true;
      });
    } catch (_) {
      final local    = AuthLocalRepository();
      final localUsers = await local.getApprovedUsers();

      setState(() {
        _technician  = widget.point.surveyTechnician != null
            ? localUsers
            .where((u) => u.id == widget.point.surveyTechnician)
            .firstOrNull
            : null;
        _qc          = widget.point.surveyQc != null
            ? localUsers
            .where((u) => u.id == widget.point.surveyQc)
            .firstOrNull
            : null;
        _usersLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final point = widget.point;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [

          /// Header
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0F10),
                  Color(0xFF2A2A2D),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.elliptical(2000, 120),
                bottomRight: Radius.elliptical(2000, 120),
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [

                  /// ปิด x
                  Positioned(
                    top: 10,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 26,
                        ),

                        SizedBox(height: 6),

                        Text(
                          widget.point.pointName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'InstrumentSans',
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),

                        SizedBox(height: 4),

                        w_text_thai_notosansthai(
                            name: 'หมุดรังวัด',
                            font_Size: 14,
                            color: Colors.white70
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 5),

          /// Body
          SizedBox(
            height: 930,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(50, 10, 50, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _Title(title: 'รูปแสดงบริเวณหมุดรังวัด'),

                  SizedBox(height: 15),

                  /// รูปแสดงบริเวณหมุดรังวัด
                  Row(
                    children: [
                      Expanded(
                        child: _ImgBox(
                          label: 'Zoom In',
                          rawValue: widget.point.pointZoominImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),
                      ),

                      SizedBox(width: 10),

                      Expanded(
                        child: _ImgBox(
                          label: 'Zoom Out',
                          rawValue: widget.point.pointZoomoutImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 25),

                  _Title(title: 'ข้อมูล UTM'),

                  SizedBox(height: 12),

                  /// UTM
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [

                        Row(
                          children: [
                            Expanded(
                              child: icon_Item(
                                icon: Icons.my_location_sharp,
                                color: Colors.blue,
                                label: 'Northing',
                                value: '${_d(widget.point.northing)} m.',
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: icon_Item(
                                icon: Icons.settings_input_antenna,
                                color: Colors.amber,
                                label: 'Antenna Height',
                                value: '${_d(widget.point.antennaM)} m.',
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: icon_Item(
                                icon: Icons.my_location_sharp,
                                color: Colors.blueAccent,
                                label: 'Easting',
                                value: '${_d(widget.point.easting)} m.',
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: icon_Item(
                                icon: Icons.public,
                                color: Colors.teal,
                                label: 'Datum',
                                value: _d(widget.point.datum),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: icon_Item(
                                icon: Icons.terrain,
                                color: Colors.pink,
                                label: 'Ortho Height (H)',
                                value: '${_d(widget.point.heightM)} m.',
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: icon_Item(
                                icon: Icons.grid_view,
                                color: Colors.green,
                                label: 'UTM Zone',
                                value: _d(widget.point.utm),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: icon_Item(
                                icon: Icons.change_history,
                                color: Colors.orange,
                                label: 'ความสูงเหนือทรงรี (h)',
                                value: '${_d(widget.point.ellipsoidalM)} m.',
                              ),
                            ),

                            SizedBox(width: 10),

                            Expanded(
                              child: icon_Item(
                                icon: Icons.description,
                                color: Colors.redAccent,
                                label: 'EGM',
                                value: _d(widget.point.egm),
                              ),
                            ),
                          ],
                        ),
                      ],

                    ),
                  ),

                  SizedBox(height: 20),

                  /// DOP , วิธีการรังวัด
                  Row(
                    children: [

                      /// DOP
                      Expanded(
                        child: Column(
                          children: [

                            _Title(title: 'ค่า DOP'),

                            SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [

                                  _Row(label: 'GDOP', value: '${_d(widget.point.gdopM)} m.'),
                                  _Row(label: 'PDOP', value: '${_d(widget.point.pdopM)} m.'),
                                  _Row(label: 'HDOP', value: '${_d(widget.point.hdopM)} m.'),
                                  _Row(label: '3DCQ', value: '${_d(widget.point.dcqM)} m.'),

                                ],

                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 10),

                      /// วิธีการรังวัด
                      Expanded(
                        child: Column(
                          children: [

                            _Title(title: 'วิธีการรังวัด'),

                            SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [

                                  icon_Item(
                                    icon: Icons.satellite_alt,
                                    color: Colors.indigoAccent,
                                    label: 'วิธีการรังวัดหลัก',
                                    value: '${_d(widget.point.surveyMain)}',
                                  ),

                                  const Divider(height: 20),

                                  icon_Item(
                                    icon: Icons.architecture,
                                    color: Colors.indigoAccent,
                                    label: 'วิธีการรังวัดย่อย',
                                    value: '${_d(widget.point.surveySub)}',
                                  ),

                                ],

                              ),
                            ),
                          ],
                        ),
                      ),

                    ],
                  ),

                  SizedBox(height: 20),

                  _Title(title: 'ที่ตั้ง'),

                  SizedBox(height: 12),

                  /// ที่ตั้ง
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [

                        _Row(label: 'ตำบล',    value: _d(widget.point.tambon)),
                        _Row(label: 'อำเภอ',   value: _d(widget.point.amphoe)),
                        _Row(label: 'จังหวัด', value: _d(widget.point.province)),

                      ],

                    ),
                  ),

                  SizedBox(height: 12),

                  /// วันที่สำรวจ
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                        children: [

                          icon_Item(
                            icon: Icons.calendar_month,
                            color: Colors.red,
                            label: 'วันที่สำรวจ',
                            value: '${_d(widget.point.pointDate)}',
                          ),
                        ]

                    ),
                  ),

                  SizedBox(height: 20),

                  _Title(title: 'รูปวาดภาคสนาม'),

                  SizedBox(height: 12),

                  /// รูปวาดภาคสนาม
                  _ImgBox(
                    rawValue: widget.point.drawImg,
                    projectId: widget.point.projectId,
                    pointId: widget.point.id,
                    aspectRatio: 900 / 500,
                  ),

                  SizedBox(height: 20),

                  _Title(title: 'JOB'),

                  SizedBox(height: 12),

                  /// JOB
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                        children: [

                          Row(
                            children: [
                              Expanded(
                                child: icon_Item(
                                  icon: Icons.folder_copy_sharp,
                                  color: Colors.pinkAccent,
                                  label: 'ชื่อ Job',
                                  value: '${_d(widget.point.job)}',
                                ),
                              ),

                              SizedBox(width: 12),

                              Expanded(
                                child: icon_Item(
                                  icon: Icons.settings_input_antenna,
                                  color: Colors.amber,
                                  label: 'GNSS',
                                  value: '${_d(widget.point.gnss)}',
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [

                                    _Row(width: 130, label: 'RF1', value: _d(widget.point.rf1)),
                                    _Row(width: 130, label: 'ระยะ RF1', value: _d(widget.point.distanceM1), unit: 'm.'),
                                    _Row(width: 130, label: 'AZ RF1', value: _d(widget.point.az1),        unit: '°'),

                                  ],
                                ),
                              ),

                              Container(
                                width: 1,
                                height: 100,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: Colors.grey.shade400,
                              ),

                              Expanded(
                                child: Column(
                                  children: [

                                    _Row(width: 130, label: 'RF2', value: _d(widget.point.rf2)),
                                    _Row(width: 130, label: 'ระยะ RF2', value: _d(widget.point.distanceM2), unit: 'm.'),
                                    _Row(width: 130, label: 'AZ RF2', value: _d(widget.point.az2),        unit: '°'),

                                  ],
                                ),
                              )
                            ],
                          )

                        ]

                    ),
                  ),

                  SizedBox(height: 20),

                  _Title(title: 'รูปถ่ายประกอบจุดตรวจสอบ'),

                  SizedBox(height: 12),

                  /// รูปถ่ายประกอบจุดตรวจสอบ
                  Column(
                    children: [

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.42,
                            child: _ImgBox(
                              label: 'เลขหมุดรังวัด',
                              rawValue: widget.point.pointSurveyImg,
                              projectId: widget.point.projectId,
                              pointId: widget.point.id,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _ImgBox(
                              label: 'ทิศเหนือ',
                              rawValue: widget.point.nSurveyImg,
                              projectId: widget.point.projectId,
                              pointId: widget.point.id,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ImgBox(
                              label: 'ทิศใต้',
                              rawValue: widget.point.sSurveyImg,
                              projectId: widget.point.projectId,
                              pointId: widget.point.id,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: _ImgBox(
                              label: 'ทิศตะวันออก',
                              rawValue: widget.point.eSurveyImg,
                              projectId: widget.point.projectId,
                              pointId: widget.point.id,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ImgBox(
                              label: 'ทิศตะวันตก',
                              rawValue: widget.point.wSurveyImg,
                              projectId: widget.point.projectId,
                              pointId: widget.point.id,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  SizedBox(height: 20),

                  const Divider(height: 20),

                  SizedBox(height: 20),

                  /// ผู้รังวัด , ผู้ตรวจสอบ
                  !_usersLoaded
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF18181C)))
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _UserSignatureBox(
                          role: 'ผู้รังวัด',
                          user: _technician,
                          sigUrl: _sigUrl(_technician?.signature),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _UserSignatureBox(
                          role: 'ผู้ตรวจสอบ',
                          user: _qc,
                          sigUrl: _sigUrl(_qc?.signature),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}


class _Title extends StatelessWidget {
  final String title;
  const _Title({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF18181C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
            color: Color(0xFF18181C),
          ),
        ),
      ],
    );
  }
}


class icon_Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const icon_Item({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        /// ICON
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),

        const SizedBox(width: 10),

        /// TEXT
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'NotoSansThai',
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF18181C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _Row extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final String? unit;

  const _Row({
    this.width = 160,
    required this.label,
    required this.value,
    this.unit
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: width,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              unit != null && value != '-' ? '$value $unit' : value,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181C),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

/// ── กล่องรูปภาพ ────────────────────────────────────
class _ImgBox extends StatelessWidget {
  final String? rawValue;
  final int projectId;
  final int pointId;
  final String? label;
  final double aspectRatio;

  const _ImgBox({
    this.rawValue,
    required this.projectId,
    required this.pointId,
    this.label,
    this.aspectRatio = 4 / 3,
  });

  bool get _isLocal => rawValue != null && rawValue!.startsWith('local://');

  bool get _hasImage => rawValue != null && rawValue!.trim().isNotEmpty;

  String get _localPath => rawValue!.replaceFirst('local://', '');

  String get _networkUrl =>
      SecureImage.pointUrl(projectId, pointId, rawValue!);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hasImage
          ? () => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: _isLocal
                      ? Image.file(File(_localPath), fit: BoxFit.contain)
                      : Image.network(_networkUrl, headers: SecureImage.headers(context), fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : null,

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // label
            if (label != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF18181C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansThai',
                    color: Colors.white,
                  ),
                ),
              ),
            ],

            // รูป
            AspectRatio(
              aspectRatio: aspectRatio,
              child: ClipRRect(
                borderRadius: label != null
                    ? const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
                    : BorderRadius.circular(12),
                child: !_hasImage
                    ? _placeholder()
                    : _isLocal
                    ? Image.file(
                  File(_localPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
                    : Image.network(
                  _networkUrl,
                  headers: SecureImage.headers(context),
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF18181C),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _placeholder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.photo_outlined, size: 36, color: Colors.grey),
      ),
    );
  }
}

/// ── ลายเซ็น + ข้อมูลผู้รังวัด/ผู้ตรวจสอบ ────────────────────────────
class _UserSignatureBox extends StatelessWidget {
  final String role;
  final UserModel? user;
  final String? sigUrl;

  const _UserSignatureBox({
    required this.role,
    required this.user,
    this.sigUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [

          // role label
          Text(
            role,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansThai',
              color: Color(0xFF18181C),
            ),
          ),

          const SizedBox(height: 10),

          // ลายเซ็น
          AspectRatio(
            aspectRatio: 2 / 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: user == null
                  ? const Center(
                child: Icon(Icons.photo_outlined, size: 25, color: Colors.grey),
              )
                  : sigUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  sigUrl!,
                  headers: SecureImage.headers(context),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.draw_outlined, color: Colors.grey, size: 28),
                  ),
                ),
              )
                  : const Center(
                child: Icon(Icons.draw_outlined, color: Colors.grey, size: 28),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Divider(height: 1),

          const SizedBox(height: 10),

          // ชื่อ
          Text(
            user != null
                ? '${user!.titleName} ${user!.firstName} ${user!.lastName}'
                : '-',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansThai',
              color: Color(0xFF18181C),
            ),
          ),

          const SizedBox(height: 4),

          // ตำแหน่ง
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text(
                'ตำแหน่ง ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'NotoSansThai',
                  color: Colors.grey.shade500,
                ),
              ),

              Text(
                user?.jobPosition ?? '-',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'NotoSansThai',
                  color: Colors.grey.shade500,
                ),
              ),

            ],
          ),

        ],
      ),
    );
  }
}