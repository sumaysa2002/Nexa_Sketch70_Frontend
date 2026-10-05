import 'package:offline_gnss69_new/export.dart';
import 'package:offline_gnss69_new/features/auth/pages/point/create_point/note_create_new_point.dart';
import 'package:offline_gnss69_new/features/widgets/field/point_text_field_column_c5_edit.dart';

class CreateNewPoint_Page extends StatefulWidget {

  final ProjectModel project;

  static MaterialPageRoute route(ProjectModel project) => MaterialPageRoute(
    builder: (context) => CreateNewPoint_Page(project: project),
  );

  const CreateNewPoint_Page({super.key, required this.project});

  @override
  State<CreateNewPoint_Page> createState() => _CreateNewPoint_PageState();
}

class _CreateNewPoint_PageState extends State<CreateNewPoint_Page> {

  final formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _pointNameSectionKey = GlobalKey();
  final GlobalKey _utmSectionKey = GlobalKey();
  final GlobalKey _gdopSectionKey = GlobalKey();
  final GlobalKey _jobSectionKey = GlobalKey();

  final point_name_Controller = TextEditingController();

  // UTM
  final northing_Controller = TextEditingController();
  final easting_Controller = TextEditingController();
  final height_m_Controller = TextEditingController();
  final ellipsoidal_m_Controller = TextEditingController();
  final antenna_m_Controller = TextEditingController();
  String? datum;
  String? utm;
  String? egm;

  // survey
  String? survey_main;
  String? survey_sub;

  // DOP
  final gdop_m_Controller = TextEditingController();
  final pdop_m_Controller = TextEditingController();
  final hdop_m_Controller = TextEditingController();
  final dcq_m_Controller = TextEditingController();

  // ตำบล อำเภอ จังหวัด วันที่สำรวจ
  final tambon_Controller = TextEditingController();
  final amphoe_Controller = TextEditingController();
  String? province;
  List<String> _provinceList = [];
  // dropdown ตำบล อำเภอ
  List<String> _amphureList = [];
  List<String> _tambonList  = [];
  String? _selectedAmphoe;
  String? _selectedTambon;

  // วันที่สำรวจ
  final point_date_Controller = TextEditingController();
  DateTime point_date = DateTime.now();
  void point_date_Selected(DateTime day, DateTime focusedDay) {
    setState(() {
      point_date = day;
      point_date_Controller.text = day.toString().split(" ")[0];
    });
  }

  // รูปแสดงบริเวณหมุดรังวัด
  Uint8List? point_zoomin_img;
  Uint8List? point_zoomout_img;

  // JOB
  final job_Controller = TextEditingController();
  final gnss_Controller = TextEditingController();
  final rf_1_Controller = TextEditingController();
  final distance_m_1_Controller = TextEditingController();
  final az_1_Controller = TextEditingController();
  final rf_2_Controller = TextEditingController();
  final distance_m_2_Controller = TextEditingController();
  final az_2_Controller = TextEditingController();

  // รูปถ่ายประกอบ
  Uint8List? draw_description_img;
  Uint8List? point_survey_img;
  Uint8List? point_controller_img;
  Uint8List? n_survey_img;
  Uint8List? s_survey_img;
  Uint8List? e_survey_img;
  Uint8List? w_survey_img;

  // ผู้รังวัด ผู้ตรวจสอบ
  UserModel? survey_technician;
  UserModel? survey_qc;

  // รายละเอียดเพิ่มเติม
  final point_note_Controller = TextEditingController();

  // เก็บรูป
  final ImagePicker _picker = ImagePicker();


  /// ── เลือกวิธีการถ่ายรูป ──────────────────────
  void _showSourcePicker({
    required String title,
    required void Function(Uint8List bytes) onPicked,
    required double ratioX,
    required double ratioY,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSansThai',
              ),
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const w_text_thai_notosansthai(
                  name: "ถ่ายภาพ",
                  font_Size: 16
              ),
              onTap: () async {
                Navigator.pop(context);
                final XFile? file = await _picker.pickImage(
                  source: ImageSource.camera,
                  preferredCameraDevice: CameraDevice.rear, // ตั้งค่าให้เปิดกล้องหลังก่อน
                );
                if (file == null) return;
                final CroppedFile? cropped = await ImageCropper().cropImage(
                  sourcePath: file.path,
                  aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
                  compressQuality: 85,
                  uiSettings: [
                    AndroidUiSettings(
                      toolbarTitle: title,
                      toolbarColor: const Color(0xFF18181C),
                      toolbarWidgetColor: Colors.white,
                      lockAspectRatio: true,
                    ),
                    IOSUiSettings(
                      title: title,
                      aspectRatioLockEnabled: true,
                    ),
                  ],
                );
                if (cropped == null) return;
                final bytes = await cropped.readAsBytes();
                onPicked(bytes);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const w_text_thai_notosansthai(
                  name: "เลือกจากแกลอรี่",
                  font_Size: 16
              ),
              onTap: () async {
                Navigator.pop(context);
                final bytes = await _pickAndCropPhoto(
                  title: title,
                  ratioX: ratioX,
                  ratioY: ratioY,
                );
                if (bytes == null) return;
                onPicked(bytes);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }


  /// ── เลือกรูป Profile และ CROP (4:3) ────────────────────────────────
  Future<Uint8List?> _pickAndCropPhoto({
    required String title,
    double ratioX = 4,
    double ratioY = 3,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: const Color(0xFF18181C),
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return croppedFile.readAsBytes();
  }


  /// ── จังหวัด >> เรียกข้อมูลอำเภอ ──────────────────────────
  void _onProvinceChanged(String? val) {
    setState(() {
      province        = val;
      _selectedAmphoe = null;
      _selectedTambon = null;
      _amphureList    = [];
      _tambonList     = [];
      tambon_Controller.clear();
    });

    amphoe_Controller.clear();
    tambon_Controller.clear();

    if (val == null) return;
    final pid = ThaiAddressService.getProvinceId(val);
    if (pid == null) return;

    setState(() {
      _amphureList = ThaiAddressService.getAmphures(pid);
    });
  }

  /// ── อำเภอ >> เรียกข้อมูลตำบล ──────────────────────────
  void _onAmphoeChanged(String? val) {
    setState(() {
      _selectedAmphoe = val;
      _selectedTambon = null;
      _tambonList     = [];
      tambon_Controller.clear();
    });

    if (val == null || province == null) return;
    final pid = ThaiAddressService.getProvinceId(province!);
    if (pid == null) return;
    final aid = ThaiAddressService.getAmphureId(val, pid);
    if (aid == null) return;

    setState(() {
      _tambonList = ThaiAddressService.getTambons(aid);
    });
  }


  /// ── จัดการข้อมูลวาดรูป ──────────────────────────
  late Box<SavedDrawing> drawBox;
  late Box<SavedDrawing> noteBox;


  @override
  void initState() {
    super.initState();
    drawBox = Hive.box<SavedDrawing>('drawings_field');
    noteBox = Hive.box<SavedDrawing>('drawings_note');

    final pj = widget.project;

    if (pj.province != null && pj.province!.isNotEmpty) {
      _provinceList = pj.province!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // default survey จาก project
    survey_main = pj.surveyMain;
    survey_sub  = (pj.surveyMain != null) ? pj.surveySub : null;

    ThaiAddressService.load().then((_) {
      if (_provinceList.length == 1) {
        _onProvinceChanged(_provinceList.first);
      }
    });
  }


  @override
  void dispose() {
    point_name_Controller.dispose();
    northing_Controller.dispose();
    easting_Controller.dispose();
    height_m_Controller.dispose();
    ellipsoidal_m_Controller.dispose();
    antenna_m_Controller.dispose();
    gdop_m_Controller.dispose();
    pdop_m_Controller.dispose();
    hdop_m_Controller.dispose();
    dcq_m_Controller.dispose();
    tambon_Controller.dispose();
    amphoe_Controller.dispose();
    point_date_Controller.dispose();
    _scrollController.dispose();
    point_note_Controller.dispose();
    super.dispose();
  }

  bool _hasNumberFormatError(
      String rawText,
      RegExp pattern, {
        int maxDecimals = 3,
      }) {
    final text = rawText.trim();
    if (text.isEmpty) return false;
    if (text.contains(',')) return true;
    if (!pattern.hasMatch(text)) return true;
    if (text.contains('.')) {
      final decimalPart = text.split('.').last;
      if (decimalPart.length > maxDecimals) return true;
    }
    return false;
  }

  bool get _pointNameSectionHasError => point_name_Controller.text.trim().isEmpty;

  bool get _utmSectionHasError {
    final antennaText = antenna_m_Controller.text.trim();
    final antennaError = antennaText.isNotEmpty &&
        (antennaText == '-' ||
            antennaText == '.' ||
            antennaText.contains(',') ||
            !RegExp(r'^-?\d+(\.\d{1,3})?$').hasMatch(antennaText));

    return _hasNumberFormatError(northing_Controller.text, RegExp(r'^\d{7}(\.\d+)?$')) ||
        _hasNumberFormatError(easting_Controller.text, RegExp(r'^\d{6}(\.\d+)?$')) ||
        _hasNumberFormatError(height_m_Controller.text, RegExp(r'^\d+(\.\d+)?$')) ||
        _hasNumberFormatError(ellipsoidal_m_Controller.text, RegExp(r'^\d+(\.\d+)?$')) ||
        antennaError;
  }

  bool get _gdopSectionHasError {
    return _hasNumberFormatError(gdop_m_Controller.text, RegExp(r'^\d+(\.\d+)?$'), maxDecimals: 1) ||
        _hasNumberFormatError(pdop_m_Controller.text, RegExp(r'^\d+(\.\d+)?$'), maxDecimals: 1) ||
        _hasNumberFormatError(hdop_m_Controller.text, RegExp(r'^\d+(\.\d+)?$'), maxDecimals: 3) ||
        _hasNumberFormatError(dcq_m_Controller.text, RegExp(r'^\d+(\.\d+)?$'), maxDecimals: 3);
  }

  bool _hasAzError(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(text)) return true;
    final az = int.tryParse(text);
    if (az == null || az < 0 || az > 360) return true;
    return false;
  }

  bool get _jobSectionHasError {
    return _hasNumberFormatError(distance_m_1_Controller.text, RegExp(r'^\d+(\.\d+)?$'), maxDecimals: 2) ||
        _hasAzError(az_1_Controller.text) ||
        _hasNumberFormatError(distance_m_2_Controller.text, RegExp(r'^\d+(\.\d+)?$'), maxDecimals: 2) ||
        _hasAzError(az_2_Controller.text);
  }

  void _scrollToFirstInvalidSection() {
    final sections = <GlobalKey>[
      if (_pointNameSectionHasError) _pointNameSectionKey,
      if (_utmSectionHasError) _utmSectionKey,
      if (_gdopSectionHasError) _gdopSectionKey,
      if (_jobSectionHasError) _jobSectionKey,
    ];

    if (sections.isEmpty) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
      return;
    }

    final ctx = sections.first.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        alignment: 0.1,
      );
    }
  }


  void check_Create_New_Point() {
    FocusScope.of(context).unfocus();

    // project ยังไม่ sync (ยังเป็น id ติดลบ) >> จะยังไม่สามารุถสร้าง point ได้
    if (widget.project.id < 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => alert_image_one_button(
          text: "ไม่สามารถสร้างหมุดรังวัดได้\nเนื่องจากอยู่ในโหมด offline",
          assets_image: "assets/images/no_wifi.png",
          onPressed: () => Navigator.of(context).pop(),
          text_button: "ตกลง",
        ),
      );
      return;
    }

    final formValid = formKey.currentState!.validate();

    // ตรวจสอบ dropdown
    final List<String> missingFields = [];

    if (!formValid || missingFields.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFirstInvalidSection();
      });
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;
    final token = authState.userModel.token;

    String? _nullIfEmpty(String text) {
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // ดึงรูป draw/note จาก Hive
    final Uint8List? drawImgBytes = drawBox.isNotEmpty
        ? drawBox.getAt(drawBox.length - 1)?.imageBytes
        : null;

    final Uint8List? noteImgBytes = noteBox.isNotEmpty
        ? noteBox.getAt(noteBox.length - 1)?.imageBytes
        : null;

    // Json draw / note
    final String? drawDataJson = drawBox.isNotEmpty
        ? drawBox.getAt(drawBox.length - 1)!.toDrawDataJson()
        : null;
    final String? detailsDataJson = noteBox.isNotEmpty
        ? noteBox.getAt(noteBox.length - 1)!.toDrawDataJson()
        : null;

    // วันที่สำรวจ
    final selectedDate = point_date_Controller.text.isNotEmpty
        ? point_date_Controller.text
        : point_date.toString().split(' ')[0];

    // ส่งข้อมูล
    context.read<PointTaskCubit>().createPoint(
      token:              token,
      projectId:          widget.project.id,
      pointName:          point_name_Controller.text.trim(),

      northing:           _nullIfEmpty(northing_Controller.text),
      easting:            _nullIfEmpty(easting_Controller.text),
      heightM:            _nullIfEmpty(height_m_Controller.text),
      ellipsoidalM:       _nullIfEmpty(ellipsoidal_m_Controller.text),
      antennaM:           _nullIfEmpty(antenna_m_Controller.text),
      datum:              datum,
      utm:                utm,
      egm:                egm,

      surveyMain:         survey_main,
      surveySub:          survey_sub,

      gdopM:              _nullIfEmpty(gdop_m_Controller.text),
      pdopM:              _nullIfEmpty(pdop_m_Controller.text),
      hdopM:              _nullIfEmpty(hdop_m_Controller.text),
      dcqM:               _nullIfEmpty(dcq_m_Controller.text),

      tambon:             _selectedTambon ?? _nullIfEmpty(tambon_Controller.text),
      amphoe:             _selectedAmphoe ?? _nullIfEmpty(amphoe_Controller.text),
      province:           province,
      pointDate:          selectedDate,

      pointZoominImg:     point_zoomin_img,
      pointZoomoutImg:    point_zoomout_img,

      drawImg:            drawImgBytes,
      drawDataJson:       drawDataJson,
      detailsImg:         noteImgBytes,
      detailsDataJson:    detailsDataJson,

      drawDescriptionImg: draw_description_img,

      job:                _nullIfEmpty(job_Controller.text),
      gnss:               _nullIfEmpty(gnss_Controller.text),
      rf1:                _nullIfEmpty(rf_1_Controller.text),
      distanceM1:         _nullIfEmpty(distance_m_1_Controller.text),
      az1:                _nullIfEmpty(az_1_Controller.text),
      rf2:                _nullIfEmpty(rf_2_Controller.text),
      distanceM2:         _nullIfEmpty(distance_m_2_Controller.text),
      az2:                _nullIfEmpty(az_2_Controller.text),

      pointSurveyImg:     point_survey_img,
      pointControllerImg: point_controller_img,
      nSurveyImg:         n_survey_img,
      sSurveyImg:         s_survey_img,
      eSurveyImg:         e_survey_img,
      wSurveyImg:         w_survey_img,

      surveyTechnician:   survey_technician?.id,
      surveyQc:           survey_qc?.id,

      pointNote:          point_note_Controller.text,
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<PointTaskCubit, PointTaskState>(
      listener: (context, state) async {
        if (state is CreatePointSuccess) {

          drawBox.clear();
          noteBox.clear();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text: "บันทึกหมุดรังวัดสำเร็จ",
              assets_image: "assets/images/checkmark.png",
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              text_button: "ตกลง",
            ),
          );
        } else if (state is CreatePointOfflineError) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text: "ไม่สามารถสร้างหมุดรังวัดได้\nเนื่องจากอยู่ในโหมด offline",
              assets_image: "assets/images/no_wifi.png",
              onPressed: () => Navigator.of(context).pop(),
              text_button: "ตกลง",
            ),
          );
        } else if (state is PointTaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },

      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [

            /// Header
            Container(
              height: 130,
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

                    Center(
                      child: Text(
                        "New Point",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'InstrumentSans',
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFAFAFA),
                  ),

                  child: Column(
                    children: [

                      // แถบสีขาวด้านบน
                      Container(
                        width: double.infinity,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(50, 0, 50, 20),
                            child: Column(
                              children: [

                                point_text_field_column_c5_edit(
                                  key: _pointNameSectionKey,
                                  name: 'ชื่อหมุดรังวัด',
                                  controller: point_name_Controller,
                                  hintText: '-',
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty) {
                                      return 'กรุณาระบุชื่อหมุดรังวัด';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 5),

                                Point_Title(title: 'รูปแสดงบริเวณหมุดรังวัด'),

                                SizedBox(height: 10),

                                /// รูปแสดงบริเวณหมุดรังวัด
                                Row(
                                  children: [

                                    Expanded(
                                      child: _PhotoBoxInteractive(
                                        label: 'Zoom In',
                                        imageBytes: point_zoomin_img,
                                        onTap: () => _showSourcePicker(
                                          title: 'รูปแสดงบริเวณหมุดรังวัด zoom in',
                                          ratioX: 16,
                                          ratioY: 9,
                                          onPicked: (bytes) => setState(() => point_zoomin_img = bytes),
                                        ),
                                        onDelete: () => setState(() => point_zoomin_img = null),
                                      ),
                                    ),

                                    SizedBox(width: 10),

                                    Expanded(
                                      child: _PhotoBoxInteractive(
                                        label: 'Zoom Out',
                                        imageBytes: point_zoomout_img,
                                        onTap: () => _showSourcePicker(
                                          title: 'รูปแสดงบริเวณหมุดรังวัด zoom out',
                                          ratioX: 16,
                                          ratioY: 9,
                                          onPicked: (bytes) => setState(() => point_zoomout_img = bytes),
                                        ),
                                        onDelete: () => setState(() => point_zoomout_img = null),
                                      ),
                                    ),

                                  ],
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'ข้อมูล UTM'),

                                SizedBox(height: 10),

                                /// UTM
                                Row(
                                  key: _utmSectionKey,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 15, 10, 15),
                                          child: Column(
                                            children: [

                                              w_text_thai_notosansthai(
                                                  name: 'UTM',
                                                  font_Size: 16,
                                                  fontWeight : FontWeight.w700
                                              ),

                                              SizedBox(height: 10),

                                              point_text_field_row_c30(
                                                  name: 'Northing',
                                                  controller: northing_Controller,
                                                  hintText: '0000000.000',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d{7}(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 160.0
                                              ),

                                              point_text_field_row_c30(
                                                  name: 'Easting',
                                                  controller: easting_Controller,
                                                  hintText: '000000.000',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d{6}(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 160.0
                                              ),

                                              point_text_field_row_c30(
                                                  name: 'Ortho Height',
                                                  controller: height_m_Controller,
                                                  hintText: '0.000',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 160.0
                                              ),

                                              point_text_field_row_c30(
                                                  name: 'ความสูงเหนือทรงรี (h)',
                                                  controller: ellipsoidal_m_Controller,
                                                  hintText: '0.000',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 160.0
                                              ),

                                              point_text_field_row_c30(
                                                  name: 'Antenna Height',
                                                  controller: antenna_m_Controller,
                                                  hintText: '0.000',
                                                  //keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  keyboardType: const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                    signed: true,
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    if (text == '-' || text == '.') {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^-?\d+(\.\d{1,3})?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 160.0
                                              ),

                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 10),

                                    /// Datum
                                    SizedBox(
                                      width: 200,
                                      height: 345,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 15, 10, 15),
                                          child: Column(
                                            children: [

                                              point_dropdown_field_column_c30(
                                                  name: 'Datum',
                                                  value: datum,
                                                  items: ['Indian 1975', 'WGS84'],
                                                  onChanged: (val) {
                                                    setState(() {
                                                      datum = val;
                                                    });
                                                  },
                                                  unitWidth: 0
                                              ),

                                              point_dropdown_field_column_c30(
                                                  name: 'UTM Zone',
                                                  value: utm,
                                                  items: ['47N', '48N'],
                                                  onChanged: (val) {
                                                    setState(() {
                                                      utm = val;
                                                    });
                                                  },
                                                  unitWidth: 0
                                              ),

                                              point_dropdown_field_column_c30(
                                                  name: 'Earth Gravitational Model (EGM)',
                                                  value: egm,
                                                  items: ['EGM96', 'EGM2008', 'TGM2017', 'EGM2020', 'GOCO2025s'],
                                                  onChanged: (val) {
                                                    setState(() {
                                                      egm = val;
                                                    });
                                                  },
                                                  unitWidth: 0
                                              ),

                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),

                                SizedBox(height: 10),

                                /// DOP
                                Container(
                                  key: _gdopSectionKey,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
                                    child: Column(
                                      children: [

                                        Row(
                                          children: [
                                            Expanded(
                                              child: point_text_field_row_c30(
                                                  name: 'GDOP',
                                                  controller: gdop_m_Controller,
                                                  hintText: '0.0',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 1) {
                                                        return 'กรุณาระบุเลขทศนิยม 1 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 50.0
                                              ),
                                            ),

                                            SizedBox(width: 10),

                                            Expanded(
                                              child: point_text_field_row_c30(
                                                  name: 'PDOP',
                                                  controller: pdop_m_Controller,
                                                  hintText: '0.0',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 1) {
                                                        return 'กรุณาระบุเลขทศนิยม 1 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 50.0
                                              ),
                                            ),
                                          ],
                                        ),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: point_text_field_row_c30(
                                                  name: 'HDOP',
                                                  controller: hdop_m_Controller,
                                                  hintText: '0.000',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 50.0
                                              ),
                                            ),

                                            SizedBox(width: 10),

                                            Expanded(
                                              child: point_text_field_row_c30(
                                                  name: '3DCQ',
                                                  controller: dcq_m_Controller,
                                                  hintText: '0.000',
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) return null;

                                                    final text = value.trim();

                                                    if (text.contains(',')) {
                                                      return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                    }

                                                    // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                    final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                    if (!validNumber.hasMatch(text)) {
                                                      return 'กรุณาตรวจสอบข้อมูล';
                                                    }

                                                    // เช็คทศนิยมเกิน 3 ตำแหน่ง
                                                    if (text.contains('.')) {
                                                      final decimalPart = text.split('.').last;
                                                      if (decimalPart.length > 3) {
                                                        return 'กรุณาระบุเลขทศนิยม 3 ตำแหน่ง';
                                                      }
                                                    }

                                                    return null;
                                                  },
                                                  nameWidth: 50.0
                                              ),
                                            ),
                                          ],
                                        ),

                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'วิธีการรังวัด'),

                                SizedBox(height: 10),

                                /// วิธีการรังวัด
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 15, 10, 5),
                                    child: Row(
                                      children: [

                                        Expanded(
                                          child: point_dropdown_field_row_c30(
                                            name: 'วิธีการรังวัดหลัก',
                                            value: survey_main,
                                            items: ['Static', 'Kinematic'],
                                            onChanged: (val) {
                                              setState(() {
                                                survey_main = val;
                                                survey_sub = null;
                                              });
                                            },
                                            nameWidth: 120,
                                          ),
                                        ),

                                        SizedBox(width: 10),

                                        Expanded(
                                          child: point_dropdown_field_row_c30(
                                              name: 'วิธีการรังวัดย่อย',
                                              value: survey_sub,
                                              items: survey_main == 'Static'
                                                  ? ['Static', 'Fast Static']
                                                  : survey_main == 'Kinematic'
                                                  ? ['RTK', 'NRTK']
                                                  : [], // survey_main ไม่เลือก = []
                                              onChanged: (val) {
                                                setState(() {
                                                  survey_sub = val;
                                                });
                                              },
                                              nameWidth: 120
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'ที่ตั้ง'),

                                SizedBox(height: 10),

                                /// ตำบล, อำเภอ, จังหวัด
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
                                    child: Column(
                                      children: [

                                        // จังหวัด + อำเภอ
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AbsorbPointer(
                                                absorbing: _provinceList.isEmpty,
                                                child: point_dropdown_field_row_c30(
                                                  name: 'จังหวัด',
                                                  value: province,
                                                  items: _provinceList.isEmpty ? ['ไม่มีข้อมูลในระบบ'] : _provinceList,
                                                  onChanged: _provinceList.isEmpty ? (_) {} : _onProvinceChanged,
                                                  hintText: _provinceList.isEmpty ? 'ไม่มีข้อมูลในระบบ' : '-',
                                                  nameWidth: 60,
                                                  unitWidth: 0,
                                                ),
                                              ),
                                            ),

                                            SizedBox(width: 10),

                                            Expanded(
                                              child: AbsorbPointer(
                                                absorbing: province == null || _amphureList.isEmpty,
                                                child: point_dropdown_field_row_c30(
                                                  name: 'อำเภอ',
                                                  value: _selectedAmphoe,
                                                  items: _amphureList.isEmpty ? ['-'] : _amphureList,
                                                  onChanged: (province == null || _amphureList.isEmpty)
                                                      ? (_) {}
                                                      : _onAmphoeChanged,
                                                  hintText: province == null
                                                      ? '-'
                                                      : _amphureList.isEmpty
                                                      ? 'ไม่มีข้อมูล'
                                                      : 'เลือกอำเภอ',
                                                  nameWidth: 60,
                                                  unitWidth: 0,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ตำบล + วันที่
                                        Row(
                                          children: [
                                            Expanded(
                                              child: AbsorbPointer(
                                                absorbing: _selectedAmphoe == null || _tambonList.isEmpty,
                                                child: point_dropdown_field_row_c30(
                                                  name: 'ตำบล',
                                                  value: _selectedTambon,
                                                  items: _tambonList.isEmpty ? ['-'] : _tambonList,
                                                  onChanged: (_selectedAmphoe == null || _tambonList.isEmpty)
                                                      ? (_) {}
                                                      : (val) => setState(() => _selectedTambon = val),
                                                  hintText: _selectedAmphoe == null
                                                      ? '-'
                                                      : _tambonList.isEmpty
                                                      ? 'ไม่มีข้อมูล'
                                                      : 'เลือกตำบล',
                                                  nameWidth: 60,
                                                  unitWidth: 0,
                                                ),
                                              ),
                                            ),

                                            SizedBox(width: 10),

                                            Expanded(
                                              child: text_field_date_row(
                                                name: "วันที่สำรวจ",
                                                hint_Text: point_date.toString().split(" ")[0],
                                                controller: point_date_Controller,
                                              ),
                                            ),

                                          ],
                                        ),

                                        // ปฏิทิน
                                        SizedBox(
                                          width: 340,
                                          child: Calendar(
                                            Date_name: point_date,
                                            Date_Selected: point_date_Selected,
                                          ),
                                        ),

                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'รูปวาดภาคสนาม'),

                                SizedBox(height: 10),

                                /// รูปวาดภาคสนาม
                                ValueListenableBuilder<Box<SavedDrawing>>(
                                  valueListenable: drawBox.listenable(),
                                  builder: (context, b, _) {
                                    if (b.isEmpty) return buildEmptyDrawBox();
                                    return buildSavedDrawPreview(b);
                                  },
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'JOB'),

                                SizedBox(height: 10),

                                /// Job
                                Container(
                                  key: _jobSectionKey,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 15, 15, 15),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [

                                            Expanded(
                                              child: point_text_field_row_c30(
                                                  name: 'ชื่อ JOB',
                                                  controller: job_Controller,
                                                  hintText: 'Text',
                                                  validator: (value) {

                                                  },
                                                  nameWidth: 60.0,
                                                  unit: "",
                                                  unitWidth: 0
                                              ),
                                            ),

                                            SizedBox(width: 10),

                                            SizedBox(
                                              width: 300.0,
                                              child: point_text_field_row_c30(
                                                  name: 'GNSS',
                                                  controller: gnss_Controller,
                                                  hintText: 'Text',
                                                  validator: (value) {

                                                  },
                                                  nameWidth: 50.0,
                                                  unit: "",
                                                  unitWidth: 0
                                              ),
                                            ),

                                          ],
                                        ),

                                        SizedBox(height: 10),

                                        /// RF1
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
                                                  child: Column(
                                                    children: [

                                                      SizedBox(
                                                        child: point_text_field_row_c30(
                                                            name: 'RF1',
                                                            controller: rf_1_Controller,
                                                            hintText: 'Text',
                                                            validator: (value) {

                                                            },
                                                            nameWidth: 40.0
                                                        ),
                                                      ),

                                                      SizedBox(
                                                        child: point_text_field_row_c30(
                                                            name: 'ระยะ',
                                                            controller: distance_m_1_Controller,
                                                            hintText: 'metre',
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            validator: (value) {
                                                              if (value == null || value.isEmpty) return null;

                                                              final text = value.trim();

                                                              if (text.contains(',')) {
                                                                return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                              }

                                                              // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                              final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                              if (!validNumber.hasMatch(text)) {
                                                                return 'กรุณาตรวจสอบข้อมูล';
                                                              }

                                                              // เช็คทศนิยมเกิน 2 ตำแหน่ง
                                                              if (text.contains('.')) {
                                                                final decimalPart = text.split('.').last;
                                                                if (decimalPart.length > 2) {
                                                                  return 'กรุณาระบุเลขทศนิยม 2 ตำแหน่ง';
                                                                }
                                                              }

                                                              return null;
                                                            },
                                                            nameWidth: 40.0
                                                        ),
                                                      ),

                                                      SizedBox(
                                                        child: point_text_field_row_c30(
                                                            name: 'AZ',
                                                            controller: az_1_Controller,
                                                            hintText: 'degree',
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            validator: (value) {
                                                              if (value == null || value.isEmpty) return null;

                                                              final text = value.trim();

                                                              if (!RegExp(r'^\d+$').hasMatch(text)) {
                                                                return 'กรุณาระบุเป็นจำนวนเต็ม';
                                                              }

                                                              final az = int.parse(text);

                                                              if (az < 0 || az > 360) {
                                                                return 'กรุณาระบุค่า 0 - 360';
                                                              }

                                                              return null;
                                                            },
                                                            nameWidth: 40.0,
                                                            unit: "°"
                                                        ),
                                                      ),


                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                            SizedBox(width: 10),

                                            /// RF2
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.black,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
                                                  child: Column(
                                                    children: [

                                                      SizedBox(
                                                        child: point_text_field_row_c30(
                                                            name: 'RF2',
                                                            controller: rf_2_Controller,
                                                            hintText: 'Text',
                                                            validator: (value) {

                                                            },
                                                            nameWidth: 40.0
                                                        ),
                                                      ),

                                                      SizedBox(
                                                        child: point_text_field_row_c30(
                                                            name: 'ระยะ',
                                                            controller: distance_m_2_Controller,
                                                            hintText: 'metre',
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            validator: (value) {
                                                              if (value == null || value.isEmpty) return null;

                                                              final text = value.trim();

                                                              if (text.contains(',')) {
                                                                return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                                                              }

                                                              // เช็คว่าเป็นตัวเลข + จุด เท่านั้น
                                                              final validNumber = RegExp(r'^\d+(\.\d+)?$');
                                                              if (!validNumber.hasMatch(text)) {
                                                                return 'กรุณาตรวจสอบข้อมูล';
                                                              }

                                                              // เช็คทศนิยมเกิน 2 ตำแหน่ง
                                                              if (text.contains('.')) {
                                                                final decimalPart = text.split('.').last;
                                                                if (decimalPart.length > 2) {
                                                                  return 'กรุณาระบุเลขทศนิยม 2 ตำแหน่ง';
                                                                }
                                                              }

                                                              return null;
                                                            },
                                                            nameWidth: 40.0
                                                        ),
                                                      ),

                                                      SizedBox(
                                                        child: point_text_field_row_c30(
                                                            name: 'AZ',
                                                            controller: az_2_Controller,
                                                            hintText: 'degree',
                                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                            validator: (value) {
                                                              if (value == null || value.isEmpty) return null;

                                                              final text = value.trim();

                                                              if (!RegExp(r'^\d+$').hasMatch(text)) {
                                                                return 'กรุณาระบุเป็นจำนวนเต็ม';
                                                              }

                                                              final az = int.parse(text);

                                                              if (az < 0 || az > 360) {
                                                                return 'กรุณาระบุค่า 0 - 360';
                                                              }

                                                              return null;
                                                            },
                                                            nameWidth: 40.0,
                                                            unit: "°"
                                                        ),
                                                      ),


                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'รูปถ่ายประกอบจุดตรวจสอบ'),

                                SizedBox(height: 10),

                                /// รูปถ่ายประกอบจุดตรวจสอบ
                                GridView.count(
                                  padding: EdgeInsets.zero,
                                  crossAxisCount: 2, // 2 ช่องต่อแถว
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 10, // ระยะห่าง แนวนอน
                                  mainAxisSpacing: 10, // ระยะห่าง แนวตั้ง
                                  childAspectRatio: 1.1, // อัตราส่วน กว้าง : สูง ของแต่ละช่อง
                                  children: [

                                    _PhotoBoxInteractive(
                                      label: 'เลขหมุดรังวัด',
                                      imageBytes: point_survey_img,
                                      onTap: () => _showSourcePicker(
                                        title: 'เลขหมุดรังวัด',
                                        ratioX: 4,
                                        ratioY: 3,
                                        onPicked: (bytes) => setState(() => point_survey_img = bytes),
                                      ),
                                      onDelete: () => setState(() => point_survey_img = null),
                                    ),

                                    _PhotoBoxInteractive(
                                      label: 'หน้าเครื่อง Controller',
                                      imageBytes: point_controller_img,
                                      onTap: () => _showSourcePicker(
                                        title: 'หน้าเครื่อง Controller',
                                        ratioX: 4,
                                        ratioY: 3,
                                        onPicked: (bytes) => setState(() => point_controller_img = bytes),
                                      ),
                                      onDelete: () => setState(() => point_controller_img = null),
                                    ),

                                    _PhotoBoxInteractive(
                                      label: 'ทิศเหนือ',
                                      imageBytes: n_survey_img,
                                      onTap: () => _showSourcePicker(
                                        title: 'ทิศเหนือ',
                                        ratioX: 4,
                                        ratioY: 3,
                                        onPicked: (bytes) => setState(() => n_survey_img = bytes),
                                      ),
                                      onDelete: () => setState(() => n_survey_img = null),
                                    ),

                                    _PhotoBoxInteractive(
                                      label: 'ทิศใต้',
                                      imageBytes: s_survey_img,
                                      onTap: () => _showSourcePicker(
                                        title: 'ทิศใต้',
                                        ratioX: 4,
                                        ratioY: 3,
                                        onPicked: (bytes) => setState(() => s_survey_img = bytes),
                                      ),
                                      onDelete: () => setState(() => s_survey_img = null),
                                    ),

                                    _PhotoBoxInteractive(
                                      label: 'ทิศตะวันออก',
                                      imageBytes: e_survey_img,
                                      onTap: () => _showSourcePicker(
                                        title: 'ทิศตะวันออก',
                                        ratioX: 4,
                                        ratioY: 3,
                                        onPicked: (bytes) => setState(() => e_survey_img = bytes),
                                      ),
                                      onDelete: () => setState(() => e_survey_img = null),
                                    ),

                                    _PhotoBoxInteractive(
                                      label: 'ทิศตะวันตก',
                                      imageBytes: w_survey_img,
                                      onTap: () => _showSourcePicker(
                                        title: 'ทิศตะวันตก',
                                        ratioX: 4,
                                        ratioY: 3,
                                        onPicked: (bytes) => setState(() => w_survey_img = bytes),
                                      ),
                                      onDelete: () => setState(() => w_survey_img = null),
                                    ),

                                  ],
                                ),

                                SizedBox(height: 20),

                                Point_Title(title: 'รายละเอียดเพิ่มเติม'),

                                SizedBox(height: 10),

                                /// Box รายละเอียดเพิ่มเติม
                                ValueListenableBuilder <Box<SavedDrawing>>(
                                  valueListenable: noteBox.listenable(),
                                  builder: (context, b, _) {
                                    if (b.isEmpty) return buildEmptyNoteBox();
                                    return buildSavedNotePreview(b);
                                  },
                                ),

                                SizedBox(height: 20),

                                point_text_field_column_c5_edit(
                                  name: 'รายละเอียดเพิ่มเติม',
                                  controller: point_note_Controller,
                                  hintText: '-',
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  minLines: 5,
                                  validator: (value) {

                                  },
                                ),

                                SizedBox(height: 10),

                                /// ผู้รังวัด / ผู้ตรวจสอบ
                                Row(
                                  children: [
                                    Expanded(
                                      child: _UserPickerField(
                                        label: 'ผู้รังวัด',
                                        selectedUser: survey_technician,
                                        onTap: () => _showUserPicker(
                                          title: 'ยืนยันการเป็นผู้รังวัด',
                                          current: survey_technician,
                                          onConfirm: (user) =>
                                              setState(() => survey_technician = user),
                                        ),
                                        onClear: () =>
                                            setState(() => survey_technician = null),
                                      ),
                                    ),

                                    SizedBox(width: 10),

                                    Expanded(
                                      child: _UserPickerField(
                                        label: 'ผู้ตรวจสอบ',
                                        selectedUser: survey_qc,
                                        onTap: () => _showUserPicker(
                                          title: 'ยืนยันการเป็นผู้ตรวจสอบ',
                                          current: survey_qc,
                                          onConfirm: (user) =>
                                              setState(() => survey_qc = user),
                                        ),
                                        onClear: () =>
                                            setState(() => survey_qc = null),
                                      ),
                                    ),

                                  ],
                                ),

                                SizedBox(height: 20),

                              ],
                          )
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
                                  name: 'Cancel',
                                  name_size: 16,
                                  icon: Icons.close,
                                  icon_size: 20,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => alert_image_two_button(
                                        text: "ยกเลิกการสร้างหมุดรังวัด",
                                        assets_image: "assets/images/question.png",
                                        one_text_button: "ยกเลิก",
                                        one_onPressed: () => Navigator.of(context).pop(),
                                        two_text_button: "ตกลง",
                                        two_onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(width: 10.0),

                              BlocBuilder<PointTaskCubit, PointTaskState>(
                                builder: (context, state) {
                                  final isLoading = state is PointTaskLoading;
                                  return SizedBox(
                                    width: MediaQuery.of(context).size.width / 2.5,
                                    child: isLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : button_icon(
                                      name: 'Create New Point',
                                      name_size: 16,
                                      icon: Icons.add,
                                      icon_size: 20,
                                      onPressed: check_Create_New_Point,
                                    ),
                                  );
                                },
                              ),

                            ],

                          ),
                        ),
                      ),
                    ],
                  ),

                ),
              ),
            ),

          ],
        ),
      ),
    );
  }


  /// ── ผู้รังวัด และ ผู้ตรวจสอบ >> เรียก user ที่กำลัง login อยู่เท่านั้น ──────────────
  void _showUserPicker({
    required String title,
    required UserModel? current,
    required void Function(UserModel?) onConfirm,
  }) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;
    final token = authState.userModel.token;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => _SingleUserPickerDialog(
        title: title,
        token: token,
        current: current,
        onlyUserId: authState.userModel.id,
        onConfirm: onConfirm,
      ),
    );
  }


  /// ── หน้า Draw ────────────────────────────────────────────────
  Widget buildEmptyDrawBox() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text(
              "ยังไม่มีรูปวาดภาคสนาม",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: circleEditButton_draw(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSavedDrawPreview(Box<SavedDrawing> b) {
    final lastIndex = b.length - 1;
    final drawing = b.getAt(lastIndex);

    return Container(
      height: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.memory(
                drawing!.imageBytes,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: circleEditButton_draw(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget circleEditButton_draw() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: IconButton(
        onPressed: () {
          final savedDrawing = drawBox.isNotEmpty
              ? drawBox.getAt(drawBox.length - 1)
              : null;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Draw_CreateNewPoint(
                project: widget.project,
              ),
              settings: RouteSettings(arguments: savedDrawing),
            ),
          );
        },
        icon: const Icon(Icons.edit, color: Colors.black, size: 20),
      ),
    );
  }


  /// ── หน้า Note ────────────────────────────────────────────────
  Widget buildEmptyNoteBox() {
    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Stack(
        children: [
          const Center(
              child: Text("ยังไม่มีบันทึกรายละเอียด",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'NotoSansThai',
                    fontWeight: FontWeight.w500,
                  )
              )
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: circleEditButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSavedNotePreview(Box b) {
    final lastIndex = b.length - 1;
    final drawing = b.getAt(lastIndex);

    return Container(
      height: 700,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.memory(
                drawing.imageBytes,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: circleEditButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget circleEditButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: IconButton(
        onPressed: () {
          final savedNote = noteBox.isNotEmpty
              ? noteBox.getAt(noteBox.length - 1)
              : null;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Note_CreateNewPoint(
                project: widget.project,
              ),
              settings: RouteSettings(arguments: savedNote),
            ),
          );
        },
        icon: const Icon(Icons.edit, color: Colors.black, size: 20),
      ),
    );
  }
}



/// ── แสดงวันที่ ────────────────────────────────────────────────
class text_field_date_row extends StatelessWidget {
  final String name;
  final String hint_Text;
  final TextEditingController? controller;

  const text_field_date_row({
    required this.name,
    required this.hint_Text,
    required this.controller,

    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),

            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 11,
                horizontal: 12,
              ),
              hintText: hint_Text,
              helperText: ' ',
              errorStyle: const TextStyle(
                fontFamily: 'NotoSansThai',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red,
                height: 1.2, // ระยะบรรทัด
              ),
              // เมื่อไม่ถูกเลือก
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 34, 34, 34),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(30)
              ),
              // เมื่อถูกเลือก
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.6),
                    width: 3.0,
                  ),
                  borderRadius: BorderRadius.circular(30)
              ),
            ),
          ),
        ),

        Container(
          width: 10.0,
          height: 48,
          alignment: Alignment.centerLeft,
          child: Text(
            "",
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansThai',
            ),
          ),
        ),
      ],
    );
  }
}


/// ── Photo Box ────────────────────────────────────────────────
class _PhotoBoxInteractive extends StatelessWidget {
  final String? label;
  final Uint8List? imageBytes;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PhotoBoxInteractive({
    this.label,
    required this.imageBytes,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageBytes != null;
    final bool hasLabel = label != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 290,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Column(
          children: [

            // Label
            if (hasLabel)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 6.5,
                  horizontal: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansThai',
                    color: Colors.white,
                  ),
                ),
              ),

            // รูป
            Expanded(
              child: Stack(
                children: [

                  Align(
                    alignment: hasLabel
                        ? Alignment.topCenter
                        : Alignment.center,

                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: hasImage
                          ? Image.memory(
                        imageBytes!,
                        fit: BoxFit.contain,
                      )
                          : Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ปุ่มลบ
                  if (hasImage)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

/// ── ผู้รังวัด และ ผู้ตรวจสอบ ────────────────────────────────
/// แสดง user ที่เลือกแล้ว
class _UserPickerField extends StatelessWidget {
  final String label;
  final UserModel? selectedUser;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _UserPickerField({
    required this.label,
    required this.selectedUser,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),

        const SizedBox(height: 8),

        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: double.infinity,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: const Color.fromARGB(255, 34, 34, 34),
                width: 1.2,
              ),
            ),
            child: selectedUser == null

            // ยังไม่เลือก
                ? const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'กดเพื่อเลือก',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'NotoSansThai',
                  color: Colors.black38,
                ),
              ),
            )

            //เลือกแล้ว >> แสดงข้อมูล user
                : Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: selectedUser!.profileImg != null
                        ? NetworkImage(
                        '${Constants.backendUri}/uploads/profiles/${selectedUser!.profileImg}')
                        : null,
                    child: selectedUser!.profileImg == null
                        ? const Icon(Icons.person, size: 18, color: Colors.grey)
                        : null,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    '${selectedUser!.titleName} ${selectedUser!.firstName} ${selectedUser!.lastName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF18181C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // ปุ่ม X
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ),

              ],
            ),
          ),
        ),
      ],
    );
  }
}


/// popup ผู้รังวัด และ ผู้ตรวจสอบ
class _SingleUserPickerDialog extends StatefulWidget {
  final String title;
  final String token;
  final UserModel? current;
  final int onlyUserId;
  final void Function(UserModel?) onConfirm;

  const _SingleUserPickerDialog({
    required this.title,
    required this.token,
    required this.current,
    required this.onlyUserId,
    required this.onConfirm,
  });

  @override
  State<_SingleUserPickerDialog> createState() =>
      _SingleUserPickerDialogState();
}

class _SingleUserPickerDialogState extends State<_SingleUserPickerDialog> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];
  UserModel? _selected;
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ผู้รังวัด และ ผู้ตรวจสอบ >> user ที่กำลัง login อยู่เท่านั้น
  Future<void> _fetchUsers() async {
    try {
      final repo = AuthRemoteRepository();
      final users = await repo.getAllUsers(token: widget.token);
      final onlySelf = users.where((u) => u.id == widget.onlyUserId).toList();
      if (mounted) {
        setState(() {
          _allUsers = onlySelf;
          _filtered = onlySelf;
          _isLoading = false;
        });
      }
    } catch (_) {
      try {
        final localRepo = AuthLocalRepository();
        final localUsers = await localRepo.getApprovedUsers();
        final onlySelf = localUsers.where((u) => u.id == widget.onlyUserId).toList();
        if (mounted) {
          setState(() {
            _allUsers = onlySelf;
            _filtered = onlySelf;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      title: Center(
        child: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // รายชื่อ
            SizedBox(
              height: 300,
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF18181C)))
                  : _error != null
                  ? Center(
                child: Text(
                  'เกิดข้อผิดพลาด: $_error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              )
                  : _filtered.isEmpty
                  ? const Center(
                child: Text(
                  'ไม่พบผู้ใช้งาน',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final user = _filtered[index];
                  final isSelected =
                      _selected?.id == user.id;
                  return _UserTile(
                    user: user,
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _selected =
                      isSelected ? null : user;
                    }),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ปุ่มตกลง
            SizedBox(
              width: double.infinity,
              height: 45,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(_selected);
                },
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.hovered) ||
                        states.contains(MaterialState.pressed)) {
                      return Colors.grey;
                    }
                    return const Color(0xFF18181C);
                  }),
                  shape: MaterialStateProperty.all(
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                child: const Text(
                  'ตกลง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansThai',
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


/// แถวรายชื่อใน popup
class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF18181C).withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181C)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user.profileImg != null
                  ? NetworkImage(
                  '${Constants.backendUri}/uploads/profiles/${user.profileImg}')
                  : null,
              child: user.profileImg == null
                  ? const Icon(Icons.person,
                  size: 26, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),

            // ชื่อ + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.titleName} ${user.firstName} ${user.lastName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NotoSansThai',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'NotoSansThai',
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // icon เลือก / ไม่เลือก
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(
                Icons.check_circle_rounded,
                key: ValueKey(true),
                color: Color(0xFF18181C),
                size: 24,
              )
                  : Icon(
                Icons.circle_outlined,
                key: const ValueKey(false),
                color: Colors.grey.shade400,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}