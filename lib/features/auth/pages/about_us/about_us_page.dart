import 'package:offline_gnss69_new/export.dart';

class About_Us_Page extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const About_Us_Page(),
  );

  const About_Us_Page({super.key});

  @override
  State<About_Us_Page> createState() => _About_Us_PageState();
}

class _About_Us_PageState extends State<About_Us_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [

          /// Background
          Column(
            children: [

              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [

                    Image.asset(
                      'assets/images/bg_about_us2.png',
                      fit: BoxFit.cover,
                    ),

                    // overlay
                    Container(
                      color: Colors.black.withOpacity(0.08),
                    ),

                  ],
                ),
              ),

              Expanded(
                flex: 5,
                child: ColoredBox(
                  color: Colors.white,
                ),
              ),

            ],
          ),

          /// Body
          SafeArea(
            child: Padding(
              padding: EdgeInsetsGeometry.directional(
                  top: 130,
                  bottom: 20,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),

                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 30, 40, 30),
                    child: Column(
                      children: [

                        Text(
                          'NEXA Sketch',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'InstrumentSans',
                            color: Color(0xFF18181C),
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          'Survey Data Annotation GNSS Point Creation Tool',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'InstrumentSans',
                            color: Color(0xFF707078),
                          ),
                        ),

                        SizedBox(height: 25),

                        Divider(
                          color: Colors.grey.shade200,
                          height: 1,
                        ),

                        SizedBox(height: 25),

                        _AboutTitle(
                          title: 'เกี่ยวกับแอปพลิเคชัน',
                        ),

                        SizedBox(height: 10),

                        Text(
                          'NEXA Sketch เป็นแอปพลิเคชันที่ใช้สนับสนุนการจัดเก็บ บันทึก และบริหารจัดการข้อมูลหมุดรังวัดในรูปแบบดิจิทัล '
                              'แทนการจดบันทึกและวาดภาพด้วยกระดาษแบบดั้งเดิม โดยแอปพลิเคชันครอบคลุมการใช้งานตั้งแต่สร้างโครงการสำรวจ '
                              'การบันทึกพิกัดและรายละเอียดข้อมูลหมุดรังวัด การวาดภาพภาคสนาม การถ่ายภาพประกอบหมุดรังวัด '
                              'ไปจนถึงจัดเก็บข้อมูลผู้ปฏิบัติงานและการส่งออกรายงานข้อมูลการสำรวจรังวัด',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            fontFamily: 'NotoSansThai',
                            color: Color(0xFF707078),
                          ),
                        ),

                        SizedBox(height: 25),

                        _AboutTitle(
                          title: 'ความสามารถหลัก',
                        ),

                        SizedBox(height: 12),

                        _FeatureItem(
                          icon: Icons.location_on_outlined,
                          color: Color(0xFF70C6E7),
                          title: 'จัดการข้อมูลหมุดรังวัด',
                          subtitle: 'บันทึกและจัดเก็บข้อมูลหมุดรังวัดอย่างเป็นระบบ',
                        ),

                        _FeatureItem(
                          icon: Icons.wifi_off,
                          color: Color(0xFF707078),
                          title: 'รองรับการทำงานระบบ Offline',
                          subtitle: 'สร้างและแก้ไขข้อมูลหมุดรังวัดได้แม้ไม่มีสัญญาณอินเทอร์เน็ต',
                        ),

                        _FeatureItem(
                          icon: Icons.edit_outlined,
                          color: Color(0xFFFCB568),
                          title: 'วาดภาพภาคสนาม',
                          subtitle: 'มีเครื่องมือวาดภาพ สำหรับบันทึกภาพประกอบข้อมูลภาคสนาม',
                        ),

                        _FeatureItem(
                          icon: Icons.camera_alt_outlined,
                          color: Color(0xFF1CD51E),
                          title: 'การถ่ายภาพหมุดรังวัด',
                          subtitle: 'รองรับการถ่ายภาพประกอบพื้นที่โดยรอบหมุดรังวัด',
                        ),

                        _FeatureItem(
                          icon: Icons.description_outlined,
                          color: Color(0xFFFE5E85),
                          title: 'ส่งออกรายงานโครงการ',
                          subtitle: 'สามารถส่งออกข้อมูลโครงการและข้อมูลหมุดรังวัดในรูปแบบไฟล์ PDF ',
                        ),

                        SizedBox(height: 20),

                        Divider(
                          color: Colors.grey.shade200,
                          height: 1,
                        ),

                        SizedBox(height: 20),


                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ติดต่อเรา',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NotoSansThai',
                                      color: Color(0xFF55565C),
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.mail_outline_rounded,
                                        color: Color(0xFFC3C3C5),
                                        size: 17,
                                      ),

                                      SizedBox(width: 6),

                                      Flexible(
                                        child: Text(
                                          'sumaysa.tonghuad@gmail.com',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'NotoSansThai',
                                            color: Color(0xFF999AA0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                ],
                              ),
                            ),

                            Container(
                              width: 1,
                              height: 60,
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              color: Colors.grey.shade200,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'พัฒนาโดย',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NotoSansThai',
                                      color: Color(0xFF55565C),
                                    ),
                                  ),

                                  SizedBox(height: 8),

                                  Text(
                                    'สำนักงานพัฒนาเทคโนโลยีอวกาศและภูมิสารสนเทศ (องค์การมหาชน)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      fontFamily: 'NotoSansThai',
                                      color: Color(0xFF999AA0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),


          /// Version
          SafeArea(
              child: Padding(
                padding: EdgeInsetsGeometry.directional(
                  top: 965,
                ),
                child: Center(
                  child: Column(
                    children: [

                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'InstrumentSans',
                          color: Color(0xFF55565C),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
          )

        ],
      ),
    );
  }
}

/// ── หัวข้อใหญ่ ──────────────────────
class _AboutTitle extends StatelessWidget {
  final String title;

  const _AboutTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Container(
          width: 4,
          height: 19,
          decoration: BoxDecoration(
            color: const Color(0xFF1976F3),
            borderRadius: BorderRadius.circular(3),
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

/// ── Item ในความสามารถหลัก ──────────────────────
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansThai',
                    color: Color(0xFF24252A),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontFamily: 'NotoSansThai',
                    color: Color(0xFF707078),
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}