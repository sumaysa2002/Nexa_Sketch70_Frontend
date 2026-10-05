import 'package:offline_gnss69_new/export.dart';

import 'edit_point_page.dart';

class Point_Detail_Editor_Page extends StatefulWidget {
  final PointModel point;
  final ProjectModel project;

  static MaterialPageRoute<bool> route(PointModel point, ProjectModel project) =>
      MaterialPageRoute<bool>(
        builder: (context) => Point_Detail_Editor_Page(
          point: point,
          project: project,
        ),
      );

  const Point_Detail_Editor_Page({
    super.key,
    required this.point,
    required this.project
  });

  @override
  State<Point_Detail_Editor_Page> createState() => _Point_Detail_Editor_PageState();
}

class _Point_Detail_Editor_PageState extends State<Point_Detail_Editor_Page> {

  // ข้อมูล null >> '-'
  String _d(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;

  // รูป signature
  String? _sigUrl(String? filename) {
    if (filename == null) return null;
    return '${Constants.backendUri}/uploads/signatures/$filename';
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

    return BlocListener<PointTaskCubit, PointTaskState>(
      listener: (context, state) {
        if (state is DeletePointSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text: "ลบหมุดรังวัดสำเร็จ",
              assets_image: "assets/images/checkmark.png",
              text_button: "ตกลง",
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
            ),
          );
        }
        if (state is DeletePointOfflineError) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text: "ไม่สามารถลบหมุดรังวัดได้\nเนื่องจากอยู่ในโหมด offline",
              assets_image: "assets/images/no_wifi.png",
              onPressed: () => Navigator.of(context).pop(),
              text_button: "ตกลง",
            ),
          );
        }
        if (state is PointTaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },

      child: Scaffold(
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(50, 10, 50, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
      
                    Point_Title(title: 'รูปแสดงบริเวณหมุดรังวัด'),
      
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
      
                    Point_Title(title: 'ข้อมูล UTM'),
      
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
      
                              Point_Title(title: 'ค่า DOP'),
      
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
      
                              Point_Title(title: 'วิธีการรังวัด'),
      
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
      
                    Point_Title(title: 'ที่ตั้ง'),
      
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
      
                    Point_Title(title: 'รูปวาดภาคสนาม'),
      
                    SizedBox(height: 12),
      
                    /// รูปวาดภาคสนาม
                    _ImgBox(
                      rawValue: widget.point.drawImg,
                      projectId: widget.point.projectId,
                      pointId: widget.point.id,
                      aspectRatio: 900 / 500,
                    ),

                    SizedBox(height: 20),

                    Point_Title(title: 'JOB'),

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
      
                    Point_Title(title: 'รูปถ่ายประกอบจุดตรวจสอบ'),
      
                    SizedBox(height: 12),
      
                    /// รูปถ่ายประกอบจุดตรวจสอบ
                    GridView.count(
                      padding: EdgeInsets.zero,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: [

                        _ImgBox(
                          label: 'เลขหมุดรังวัด',
                          rawValue: widget.point.pointSurveyImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),

                        _ImgBox(
                          label: 'หน้าเครื่อง Controller',
                          rawValue: widget.point.pointControllerImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),

                        _ImgBox(
                          label: 'ทิศเหนือ',
                          rawValue: widget.point.nSurveyImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),

                        _ImgBox(
                          label: 'ทิศใต้',
                          rawValue: widget.point.sSurveyImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),

                        _ImgBox(
                          label: 'ทิศตะวันออก',
                          rawValue: widget.point.eSurveyImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),

                        _ImgBox(
                          label: 'ทิศตะวันตก',
                          rawValue: widget.point.wSurveyImg,
                          projectId: widget.point.projectId,
                          pointId: widget.point.id,
                        ),

                      ],
                    ),
      
                    SizedBox(height: 10),
      
                    Point_Title(title: 'รายละเอียดเพิ่มเติม'),
      
                    SizedBox(height: 12),
      
                    /// รายละเอียดเพิ่มเติม
                    _ImgBox(
                      rawValue: widget.point.detailsImg,
                      projectId: widget.point.projectId,
                      pointId: widget.point.id,
                      aspectRatio: 650 /650,
                    ),
      
                    SizedBox(height: 20),

                    /// รายละเอียดเพิ่มเติม
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Colors.blue,
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Text(
                                'รายละเอียดเพิ่มเติม',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'NotoSansThai',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Text(
                            _d(widget.point.pointNote),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              fontFamily: 'NotoSansThai',
                              color: Color(0xFF18181C),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                        
                        SizedBox(width: 16),
                        
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
      
      
            /// Button
            SizedBox(
              height: 130,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF18181C),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
      
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2.5,
                      child: button_icon(
                        name: 'Edit Point',
                        name_size: 16,
                        icon: Icons.edit,
                        icon_size: 20,
                        onPressed: () async {
                          await Navigator.of(context).push(
                            Edit_Point_Page.route(widget.point, widget.project),
                          );
                          if (mounted) Navigator.of(context).pop(true);
                        },
                      ),
                    ),
      
                    SizedBox(width: 10.0),
      
                    /// ปุ่ม Delete
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2.5,
                      child: button_icon(
                        name: 'Delete',
                        name_size: 16,
                        icon: Icons.delete,
                        icon_size: 20,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => alert_image_two_button(
                              text: "ยืนยันลบหมุดรังวัด",
                              one_fontWeight: FontWeight.w700,
                              assets_image: "assets/images/icon_bin.png",
                              one_text_button: "ยกเลิก",
                              one_onPressed: () => Navigator.of(context).pop(),
                              two_text_button: "ตกลง",
                              two_onPressed: () {
                                Navigator.of(context).pop();
                                final authState = context.read<AuthCubit>().state;
                                if (authState is! AuthLoggedIn) return;
                                context.read<PointTaskCubit>().deletePoint(
                                  token:   authState.userModel.token,
                                  pointId: widget.point.id,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
      
                  ],
      
                ),
              ),
            ),
      
          ],
        ),
      ),
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

/// ── แสดงรูปภาพ ────────────────────────────────
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
      '${Constants.backendUri}/uploads/point/$projectId/$pointId/$rawValue';

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
                      : Image.network(_networkUrl, fit: BoxFit.contain),
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
                child: Icon(Icons.photo_outlined, size: 36, color: Colors.grey),
              )
                  : sigUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  sigUrl!,
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