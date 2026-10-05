import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:offline_gnss69_new/export.dart';


class Export_Project {

  /// ── Entry point ──────────────────────────────────────────────────────────
  static Future<void> showExportDialog(
      BuildContext context, {
        required ProjectModel project,
        required List<PointModel> points,
        required String token,
      }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExportBottomSheet(
        project: project,
        points: points,
        token: token,
      ),
    );
  }

  /// ── โหลดรูปจาก URL ────────────────────────────────────
  static Future<pw.ImageProvider?> _loadImage(String? url, String token) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'x-auth-token': token},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(res.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  /// ── URL point ──────────────────────────────────────────
  static String _imgUrl(PointModel p, String? filename) {
    if (filename == null || filename.trim().isEmpty) return '';
    return '${Constants.backendUri}/uploads/point/${p.projectId}/${p.id}/$filename';
  }

  /// ── URL signature ────────────────────────────────────────
  static String? _sigUrl(String? filename) {
    if (filename == null || filename.trim().isEmpty) return null;
    return '${Constants.backendUri}/uploads/signatures/$filename';
  }

  /// ── โหลดข้อมูล user จาก id  ─────────────────────────────────
  static UserModel? _findUser(Map<int, UserModel> usersById, int? userId) {
    if (userId == null) return null;
    return usersById[userId];
  }

  /// ── สร้าง PDF bytes ───────────────────────────────────────────────────────
  static Future<Uint8List> generatePdf({
    required ProjectModel project,
    required List<PointModel> points,
    required String token,
    void Function(int current, int total)? onProgress,
  }) async {
    final pdf = pw.Document();

    final logoData = await rootBundle.load(
      'assets/images/gistda_logo.png',
    );

    final logoImage = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );

    final fontData     = await rootBundle.load('assets/fonts/THSarabunNew.ttf');
    final fontDataBold = await rootBundle.load('assets/fonts/THSarabunNew Bold.ttf');


    final ttf     = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(fontDataBold);

    // รวบรวม id ของผู้รังวัด/ผู้ตรวจสอบทุกหมุด แล้วโหลดครั้งเดียว (ครอบคลุมแม้ถูกถอนการอนุมัติไปแล้ว)
    final neededUserIds = <int>{
      for (final p in points) ...[
        if (p.surveyTechnician != null) p.surveyTechnician!,
        if (p.surveyQc != null) p.surveyQc!,
      ],
    };

    Map<int, UserModel> usersById = {};
    if (neededUserIds.isNotEmpty) {
      try {
        final repo = AuthRemoteRepository();
        final loadedUsers = await repo.getUsersByIds(
          token: token,
          ids: neededUserIds.toList(),
        );
        usersById = { for (final u in loadedUsers) u.id: u };
      } catch (_) {}
    }

    final baseStyle     = pw.TextStyle(font: ttf,     fontSize: 14);
    final boldStyle     = pw.TextStyle(font: ttfBold, fontSize: 14);
    final subTitleStyle = pw.TextStyle(font: ttfBold, fontSize: 16);

    // วัน/เดือน/ปี
    String format_Date(String? value) {
      if (value == null || value.isEmpty) return '-';

      try {
        return formatDate(
          DateTime.parse(value),
          [dd, '/', mm, '/', yyyy],
        );
      } catch (_) {
        return value;
      }
    }

    // ถ้าเป็นค่า null >> ให้แสดง -
    String d(String? v) => (v == null || v.trim().isEmpty) ? '-' : v;



    /// ── หน้าปก ──────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          left: 50,
          right: 50,
          top: 40,
          bottom: 40,
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // Header bar
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF18181C),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    d(project.projectName),
                    style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.white),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            pw.Text('ข้อมูลโครงการ', style: subTitleStyle),

            pw.SizedBox(height: 8),

            _buildInfoTable([
              ['พื้นที่การสำรวจรังวัด', d(project.province)],
              ['Sensor', d(project.sensor)],
              ['Ground Sample Distance (GSD)', project.gsdNum != null ? '${project.gsdNum} ${d(project.gsdUnit)}' : '-'],
              ['วิธีการรังวัดหลัก', project.surveyMain != null ? '${d(project.surveyMain)}' : '-'],
              ['วิธีการรังวัดย่อย', project.surveyMain != null ? '${d(project.surveySub)}' : '-'],
              ['วันเริ่มต้นการสำรวจรังวัด', format_Date(project.projectStartDate)],
              ['วันสิ้นสุดการสำรวจรังวัด', format_Date(project.projectEndDate)],
            ], baseStyle: baseStyle, boldStyle: boldStyle),

            pw.SizedBox(height: 24),

            // สรุปจำนวนหมุดรังวัด
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  summarize_point(
                      'จำนวนหมุดรังวัด',
                      '${points.length} หมุดรังวัด',
                      ttf,
                      ttfBold
                  ),
                ],
              ),
            ),

            pw.Spacer(),

          ],
        ),
      ),
    );


    /// ── ข้อมูล point แบ่งเป็น 2 หน้า ──────────────────────
    for (int idx = 0; idx < points.length; idx++) {
      final p = points[idx];
      onProgress?.call(idx + 1, points.length);

      // โหลดรูปทั้งหมดของ point พร้อมกัน
      final imgResults = await Future.wait([
        _loadImage(_imgUrl(p, p.pointZoominImg),      token), // 0
        _loadImage(_imgUrl(p, p.pointZoomoutImg),     token), // 1
        _loadImage(_imgUrl(p, p.pointSurveyImg),      token), // 2
        _loadImage(_imgUrl(p, p.pointControllerImg),  token), // 3
        _loadImage(_imgUrl(p, p.nSurveyImg),          token), // 4
        _loadImage(_imgUrl(p, p.sSurveyImg),          token), // 5
        _loadImage(_imgUrl(p, p.eSurveyImg),          token), // 6
        _loadImage(_imgUrl(p, p.wSurveyImg),          token), // 7
        _loadImage(_imgUrl(p, p.drawImg),             token), // 8
        _loadImage(_imgUrl(p, p.detailsImg),          token), // 9
        _loadImage(_imgUrl(p, p.drawDescriptionImg),  token), // 10
      ]);

      final imgZoomIn      = imgResults[0];
      final imgZoomOut     = imgResults[1];
      final imgSurvey      = imgResults[2];
      final imgController  = imgResults[3];
      final imgN           = imgResults[4];
      final imgS           = imgResults[5];
      final imgE           = imgResults[6];
      final imgW           = imgResults[7];
      final imgDraw        = imgResults[8];
      final imgDetails     = imgResults[9];
      final ImgDrawDescription     = imgResults[10];

      // โหลดข้อมูล ผู้รังวัด / ผู้ตรวจสอบ
      final techUser = _findUser(usersById, p.surveyTechnician);
      final qcUser   = _findUser(usersById, p.surveyQc);

      // โหลดรูป signature
      final imgTechSig = await _loadImage(_sigUrl(techUser?.signature), token);
      final imgQcSig   = await _loadImage(_sigUrl(qcUser?.signature), token);


      /// PAGE 1 — แสดงข้อมูล Point
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(
            left: 50,
            right: 50,
            top: 20,
            bottom: 10,
          ),
          header: (ctx) => Header_logo(
            logo: logoImage,
            ttf: ttf,
            ttfBold: ttfBold,
          ),
          build: (ctx) => [

            pw.Text(
              'ชื่อหมุดรังวัด ${d(p.pointName)}',
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: 20,
              ),
              textAlign: pw.TextAlign.center,
            ),

            pw.Divider(color: PdfColors.grey800),

            /// UTM
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 30,
                  child: pw.Text(
                    'UTM',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 16,
                    ),
                  ),
                ),

                pw.Text(
                  '${d(p.datum)} Zone ${d(p.utm)}',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 3),

            _infoRow(
              label: 'Northing',
              item: d(p.northing),
              unit: 'm.',
              ttf: ttf,
              ttfBold: ttfBold,
            ),

            _infoRow(
              label: 'Easting',
              item: d(p.easting),
              unit: 'm.',
              ttf: ttf,
              ttfBold: ttfBold,
            ),

            _infoRow(
              label: 'Ortho Height',
              item: d(p.heightM),
              unit: 'm.',
              ttf: ttf,
              ttfBold: ttfBold,
            ),

            /// ความสูงเหนือทรงรี (h) / GDOP / PDOP
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [

                pw.SizedBox(
                  child: _infoRow(
                    label: 'ความสูงเหนือทรงรี (h)',
                    item: d(p.ellipsoidalM),
                    unit: 'm.',
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 40),

                pw.SizedBox(
                  child: _infoRow(
                    label: 'GDOP',
                    labelWidth: 45,
                    item: d(p.gdopM),
                    itemWidth: 45,
                    unit: 'm.',
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 10),

                pw.SizedBox(
                  child: _infoRow(
                    label: 'PDOP',
                    labelWidth: 45,
                    item: d(p.pdopM),
                    itemWidth: 45,
                    unit: 'm.',
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

              ],
            ),

            /// Antenna Height / HDOP / 3DCQ
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [

                pw.SizedBox(
                  child: _infoRow(
                    label: 'Antenna Height',
                    item: d(p.antennaM),
                    unit: 'm.',
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 40),

                pw.SizedBox(
                  child: _infoRow(
                    label: 'HDOP',
                    labelWidth: 45,
                    item: d(p.hdopM),
                    itemWidth: 45,
                    unit: 'm.',
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 10),

                pw.SizedBox(
                  child: _infoRow(
                    label: '3DCQ',
                    labelWidth: 45,
                    item: d(p.dcqM),
                    itemWidth: 45,
                    unit: 'm.',
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

              ],
            ),

            pw.Divider(color: PdfColors.grey800),

            /// ชื่อโครงการ
            pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 50,
                    child: pw.Text(
                      'โครงการ :',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  pw.SizedBox(
                    width: 450,
                    child: pw.Text(
                      '${d(project.projectName)}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ]
            ),

            /// ตำบล อำเภอ
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // pw.SizedBox(
                //   child: _infoRow(
                //     label: 'อำเภอ',
                //     labelWidth: 45,
                //     item: d(p.amphoe),
                //     itemWidth: 150,
                //     unit: '',
                //     unitWidth: 0,
                //     ttf: ttf,
                //     ttfBold: ttfBold,
                //   ),
                // ),

                // ตำบล
                pw.SizedBox(
                  child: _infoRow(
                    label: 'ตำบล',
                    labelWidth: 45,
                    item: d(p.tambon),
                    itemWidth: 200,
                    unit: '',
                    unitWidth: 0,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 20),

                // อำเภอ
                pw.SizedBox(
                  child: _infoRow(
                    label: 'อำเภอ',
                    labelWidth: 40,
                    item: d(p.amphoe),
                    itemWidth: 150,
                    unit: '',
                    unitWidth: 0,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 30),

              ],
            ),

            /// จังหวัด ว/ด/ป
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // จังหวัด
                pw.SizedBox(
                  child: _infoRow(
                    label: 'จังหวัด',
                    labelWidth: 45,
                    item: d(p.province),
                    itemWidth: 200,
                    unit: '',
                    unitWidth: 0,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                pw.SizedBox(width: 20),

                // วัน/เดือน/ปี
                pw.SizedBox(
                  child: _infoRow(
                    label: 'วัน/เดือน/ปี',
                    labelWidth: 65,
                    item: format_Date(p.pointDate),
                    itemWidth: 125,
                    unit: '',
                    unitWidth: 0,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

              ],
            ),

            pw.SizedBox(height: 5),

            /// zoomin zoomout
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [

                pw.Expanded(
                  //width: 230,
                  //height: 100,
                  child: img_full(
                    imgZoomIn,
                    ttf,
                    ttfBold,
                  ),
                ),

                pw.SizedBox(width: 10),

                pw.Expanded(
                  //width: 230,
                  //height: 100,
                  child: img_full(
                    imgZoomOut,
                    ttf,
                    ttfBold,
                  ),
                ),

              ],
            ),

            pw.SizedBox(height: 15),

            /// รูปวาดภาคสนาม Job
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // รูปวาดภาคสนาม
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    height: 160,
                    child: pw.Column(
                      children: [

                        pw.Expanded(
                            child: pw.Container(
                              height: 160,
                              alignment: pw.Alignment.center,
                              child: imgDraw != null
                                  ? pw.Image(
                                imgDraw,
                                fit: pw.BoxFit.cover,
                              )
                                  : pw.SizedBox(),
                            )
                        ),

                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 10),

                // ข้อมูล RF
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.black,
                        width: 1,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [

                        // Job + GNSS
                        pw.Row(
                          children: [

                            _infoRow(
                              label: 'ชื่อ Job',
                              labelWidth:45,
                              item: d(p.job),
                              itemWidth: 60,
                              unit: '',
                              unitWidth: 0,
                              ttf: ttf,
                              ttfBold: ttfBold,
                            ),

                            pw.SizedBox(width: 10),

                            _infoRow(
                              label: 'GNSS',
                              labelWidth: 35,
                              item: d(p.gnss),
                              itemWidth: 80,
                              unit: '',
                              unitWidth: 0,
                              ttf: ttf,
                              ttfBold: ttfBold,
                            ),

                          ],
                        ),


                        pw.Divider(color: PdfColors.black),

                        // RF1
                        _infoRow(
                          label: 'RF1',
                          labelWidth: 35,
                          item: d(p.rf1),
                          itemWidth: 195,
                          unit: '',
                          unitWidth: 0,
                          ttf: ttf,
                          ttfBold: ttfBold,
                        ),

                        pw.SizedBox(height: 8),

                        pw.Row(
                          children: [

                            _infoRow(
                              label: 'ระยะ',
                              labelWidth: 35,
                              item: d(p.distanceM1),
                              itemWidth: 50,
                              unit: 'เมตร',
                              //unitWidth: 0,
                              ttf: ttf,
                              ttfBold: ttfBold,
                            ),

                            pw.SizedBox(width: 25),

                            _infoRow(
                              label: 'AZ',
                              labelWidth: 30,
                              item: d(p.az1),
                              itemWidth: 20,
                              unit: '°',
                              //unitWidth: 0,
                              ttf: ttf,
                              ttfBold: ttfBold,
                            ),

                          ],
                        ),

                        pw.SizedBox(height: 8),

                        // RF2
                        _infoRow(
                          label: 'RF2',
                          labelWidth: 35,
                          item: d(p.rf2),
                          itemWidth: 195,
                          unit: '',
                          unitWidth: 0,
                          ttf: ttf,
                          ttfBold: ttfBold,
                        ),

                        pw.SizedBox(height: 8),

                        pw.Row(
                          children: [

                            _infoRow(
                              label: 'ระยะ',
                              labelWidth: 35,
                              item: d(p.distanceM2),
                              itemWidth: 50,
                              unit: 'เมตร',
                              //unitWidth: 0,
                              ttf: ttf,
                              ttfBold: ttfBold,
                            ),

                            pw.SizedBox(width: 25),

                            _infoRow(
                              label: 'AZ',
                              labelWidth: 30,
                              item: d(p.az2),
                              itemWidth: 20,
                              unit: '°',
                              //unitWidth: 0,
                              ttf: ttf,
                              ttfBold: ttfBold,
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 5),

            pw.Divider(color: PdfColors.black),

            pw.SizedBox(height: 5),

            /// ผู้รังวัด / ผู้ตรวจสอบ
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ผู้รังวัด
                pw.Expanded(
                  child: _buildSignatureBox(
                    role: 'ผู้รังวัด',
                    user: techUser,
                    sigImage: imgTechSig,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

                // เส้นกลางแนวตั้ง
                pw.Container(
                  width: 1,
                  height: 105,
                  color: PdfColors.black,
                ),

                // ผู้ตรวจสอบ
                pw.Expanded(
                  child: _buildSignatureBox(
                    role: 'ตรวจสอบโดย',
                    user: qcUser,
                    sigImage: imgQcSig,
                    ttf: ttf,
                    ttfBold: ttfBold,
                  ),
                ),

              ],
            ),

          ],
        ),
      );


      /// PAGE 2 — แสดงรูป Point
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.only(
            left: 50,
            right: 50,
            top: 40,
            bottom: 40,
          ),
          build: (ctx) => [
            pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [

                    pw.Text(
                      'รูปถ่ายประกอบจุดตรวจสอบ ${d(p.pointName)}',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 18,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),

                    pw.SizedBox(height: 20),

                    pw.Center(
                      child: pw.SizedBox(
                        width: 250,
                        child: img_Card(
                          'เลขหมุดรังวัด',
                          imgSurvey,
                          ttf,
                          ttfBold,
                        ),
                      ),
                    ),

                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Expanded(
                          child: img_Card('N', imgN, ttf, ttfBold),
                        ),

                        pw.Expanded(
                          child: img_Card('S', imgS, ttf, ttfBold),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 0),

                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Expanded(
                          child: img_Card('E', imgE, ttf, ttfBold),
                        ),

                        pw.Expanded(
                          child: img_Card('W', imgW, ttf, ttfBold),
                        ),
                      ],
                    ),
                  ],
                )
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }


  /// ── ปกโครงการ ──────────────────────
  static pw.Widget _buildInfoTable(
      List<List<String>> rows, {
        required pw.TextStyle baseStyle,
        required pw.TextStyle boldStyle,
      }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(4),
      },
      children: rows.map((row) {
        return pw.TableRow(
            children: [
              pw.Container(
                color: const PdfColor.fromInt(0xFFF0F0F0),
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(row[0], style: boldStyle),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(row[1], style: baseStyle),
              ),
            ]
        );
      }).toList(),
    );
  }

  /// สรุป point
  static pw.Widget summarize_point(String label, String value, pw.Font ttf, pw.Font ttfBold) {
    return pw.Column(children: [
      pw.Text(
          label,
          style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
              color: PdfColors.grey600
          )
      ),
      pw.SizedBox(height: 2),
      pw.Text(
          value,
          style: pw.TextStyle(
              font: ttfBold,
              fontSize: 20
          )
      ),
    ]);
  }


  /// ── Page 1 ──────────────────────
  /// Header logo
  static pw.Widget Header_logo({
    required pw.ImageProvider logo,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [

        // Logo ด้านบน
        pw.Center(
          child: pw.Image(
            logo,
            height: 40,
          ),
        ),

        pw.Text(
          'รายละเอียดการรังวัดค่าพิกัด GPS',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: ttfBold,
            fontSize: 16,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }


  /// แสดงข้อมูล
  static pw.Widget _infoRow({
    required String label,
    double labelWidth = 120,
    required String item,
    double itemWidth = 80,
    String unit = '',
    double unitWidth = 25,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: labelWidth,
          child: pw.Text(
            '$label :',
            style: pw.TextStyle(
              font: ttfBold,
              fontSize: 16,
            ),
          ),
        ),

        pw.SizedBox(
          width: itemWidth,
          child: pw.Text(
            item,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
            ),
          ),
        ),

        if (unit.isNotEmpty)
          pw.SizedBox(
            width: unitWidth,
            child: pw.Text(
              unit,
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  /// แสดงรูป
  static pw.Widget img_full(
      pw.ImageProvider? img,
      pw.Font ttf,
      pw.Font ttfBold) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: double.infinity,
          alignment: pw.Alignment.center,
          child: img != null
              ? pw.Image(img, fit: pw.BoxFit.contain)
              : pw.SizedBox(),
        ),
      ],
    );
  }

  /// แสดงลายเซ็น ผู้รังวัด / ผู้ตรวจสอบ
  static pw.Widget _buildSignatureBox({
    required String role,
    required UserModel? user,
    required pw.ImageProvider? sigImage,
    required pw.Font ttf,
    required pw.Font ttfBold,
  }) {
    final String fullName = user != null
        ? '${user.titleName}${user.firstName} ${user.lastName}'
        : '-';
    final String position = user?.jobPosition ?? '-';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [

          // signature
          pw.Container(
            width: double.infinity,
            height: 50,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(
                  color: PdfColors.white,
                  width: 0.5
              ),
            ),
            child: sigImage != null
                ? pw.Image(sigImage, fit: pw.BoxFit.contain)
                : pw.Center(
              child: pw.Text(
                '',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),

          pw.SizedBox(height: 4),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [

              // หัวข้อบทบาท
              pw.Text(
                role,
                style: pw.TextStyle(font: ttfBold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(width: 7),

              // ชื่อ
              pw.Text(
                fullName,
                style: pw.TextStyle(font: ttfBold, fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),

            ]
          ),

          pw.SizedBox(height: 2),

          // ตำแหน่ง
          pw.Text(
            'ตำแหน่ง $position',
            style: pw.TextStyle(font: ttf, fontSize: 12, ),
            textAlign: pw.TextAlign.center,
          ),

        ],
      ),
    );
  }


  /// ── Page 2 ──────────────────────
  /// แสดงรูป
  static pw.Widget img_Card(
      String label,
      pw.ImageProvider? img,
      pw.Font ttf,
      pw.Font ttfBold,
      ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [

        // รูปภาพ
        pw.Container(
          width: double.infinity,
          height: 200,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(
              color: PdfColors.black,
              width: 1,
            ),
          ),
          child: pw.Center(
            child: img != null
                ? pw.Image(
              img,
              fit: pw.BoxFit.contain,
            )
                : pw.SizedBox(),
          ),
        ),

        // Label
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 4,
          ),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(
              color: PdfColors.black,
              width: 1,
            ),
          ),
          child: pw.Text(
            label,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}


/// ── Popup วิธีส่งออกข้อมูล ──────────────────────
class _ExportBottomSheet extends StatefulWidget {
  final ProjectModel project;
  final List<PointModel> points;
  final String token;

  const _ExportBottomSheet({
    required this.project,
    required this.points,
    required this.token,
  });

  @override
  State<_ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<_ExportBottomSheet> {
  bool _isLoadingPdf = false;

  String _progressText = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'ส่งออกข้อมูล',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'NotoSansThai'
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'เลือกรูปแบบที่ต้องการส่งออก',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'NotoSansThai',
              ),
            ),

            const SizedBox(height: 20),

            /// PDF card
            Export_Card(
              icon: Icons.picture_as_pdf_outlined,
              iconColor: const Color(0xFFE53935),
              title: 'PDF Document',
              subtitle: 'Download Document',
              isLoading: _isLoadingPdf,
              progressText: _isLoadingPdf ? _progressText : '',
              onTap: widget.points.isEmpty ? null : _exportPdf,
            ),

            const SizedBox(height: 12),

            /// แจ้งเตือน กรณีไม่มีหมุดรังวัดในโครงการ
            if (widget.points.isEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ยังไม่มีหมุดรังวัดในโครงการนี้',
                        style: TextStyle(
                          fontSize: 13, fontFamily: 'NotoSansThai',
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }


  /// ── Export PDF ──────────────────────────────────
  Future<void> _exportPdf() async {

    setState(() {
      _isLoadingPdf = true;
      _progressText = 'กำลังเตรียมข้อมูล...';
    });

    // PDF bytes >> ได้ไฟล์ PDF ทั้งก้อน
    try {
      final bytes = await Export_Project.generatePdf(
        project: widget.project,
        points: widget.points,
        token: widget.token,
        onProgress: (current, total) {
          if (mounted) {
            setState(() => _progressText = 'กำลังจัดเตรียมเอกสาร $current / $total');
          }
        },
      );

      // เช็คว่า widget ยังอยู่ในหน้าจอไหม
      if (!mounted) return;
      Navigator.of(context).pop();

      // เปิดหน้า Print / Save PDF
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${widget.project.projectName}_points.pdf',  // ตั้งชื่อไฟล์
      );

    } catch (e) {
      if (!mounted) return;
      _showError('ไม่สามารถสร้าง PDF ได้: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoadingPdf = false;
          _progressText = '';
        });
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'NotoSansThai')),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

/// ── Popup วิธีส่งออกข้อมูล >> Card ──────────────────────
class Export_Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final String progressText;
  final VoidCallback? onTap;

  const Export_Card({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.progressText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled ? Colors.grey.shade200 : const Color(0xFF18181C),
            width: 1.2,
          ),
          boxShadow: disabled ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [

            // Icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: disabled
                    ? Colors.grey.shade100
                    : iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: disabled ? Colors.grey.shade400 : iconColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'NotoSansThai',
                      color: disabled ? Colors.grey.shade400 : const Color(0xFF18181C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading && progressText.isNotEmpty ? progressText : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'NotoSansThai',
                      color: isLoading
                          ? const Color(0xFF18181C)
                          : disabled
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow / Loading
            if (isLoading)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF18181C),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: disabled ? Colors.grey.shade300 : Colors.grey.shade500,
                size: 22,
              ),

          ],
        ),
      ),
    );
  }
}