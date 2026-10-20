import 'package:offline_gnss69_new/export.dart';

class Profile_Page extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const Profile_Page(),
  );

  const Profile_Page({super.key});

  @override
  State<Profile_Page> createState() => _Profile_PageState();
}

class _Profile_PageState extends State<Profile_Page> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),

      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {

          if (state is AuthLoggedIn) {
            final user = state.userModel;

            return SafeArea(
              bottom: false,
              child: Stack(
                children: [

                  /// Background
                  Container(
                    color: const Color(0xFFF7F7F8),
                  ),

                  /// Header
                  Container(
                    height: 270,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF101012),
                          Color(0xFF2C2C30),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.elliptical(700, 150),
                        bottomRight: Radius.elliptical(700, 150),
                      ),
                    ),

                    child: const SafeArea(
                      child: Padding(
                        padding: EdgeInsets.only(top: 70),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: w_text_big(
                            name: "My profile!",
                            font_Size: 36,
                            color: Colors.white,
                            shadow_color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// body
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: 205,
                      left: 35,
                      right: 35,
                      bottom: 40,
                    ),

                    child: Column(
                      children: [

                        /// รูปโปรไฟล์
                        Stack(
                          clipBehavior: Clip.none,
                          children: [

                            Container(
                              width: 145,
                              height: 145,

                              padding: const EdgeInsets.all(5),

                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.15),
                                    blurRadius: 25,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),

                              child: ClipOval(
                                child: Container(
                                  color: const Color(0xFFF3F3F3),
                                  child: user.profileImg != null
                                      ? Image.network(SecureImage.profileUrl(user.profileImg), headers: SecureImage.authHeaders,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 65,
                                      color: Colors.grey.shade400,
                                    ),
                                  )
                                      : Icon(
                                    Icons.person,
                                    size: 65,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),

                            /// Edit button
                            Positioned(
                              right: 0,
                              bottom: 5,

                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {
                                  // เช็ค internet ก่อนไปหน้า Edit
                                  final result = await Connectivity().checkConnectivity();
                                  final isOnline = result.contains(ConnectivityResult.wifi) ||
                                      result.contains(ConnectivityResult.mobile);

                                  // offline
                                  if (!isOnline) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => alert_image_one_button(
                                        text: "ไม่สามารถแก้ไขข้อมูลของคุณได้\nเนื่องจากอยู่ในโหมด offline",
                                        assets_image: "assets/images/no_wifi.png",
                                        onPressed: () => Navigator.of(context).pop(),
                                        text_button: "ตกลง",
                                      ),
                                    );
                                    return;
                                  }

                                  // online
                                  Navigator.push(context, Profile_Edit_Page.route());
                                },

                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF18181C),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.15),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        /// ชื่อ
                        Text(
                          user.fullName,
                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansThai',
                            color: Color(0xFF18181C),
                          ),
                        ),

                        const SizedBox(height: 5),

                        /// email
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'InstrumentSans',
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// ข้อมูลผู้ใช้งาน
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ProfileItem(
                                icon: Icons.phone_outlined,
                                iconColor: Colors.blue,
                                title: 'เบอร์โทร',
                                value: user.formattedPhone,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _ProfileItem(
                                icon: Icons.edit_note,
                                iconColor: Colors.brown,
                                title: 'ลายเซ็น',
                                value: user.signature != null ? "เพิ่มลายเซ็นแล้ว" : "ยังไม่ได้เพิ่มลายเซ็น",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Expanded(
                              child: _ProfileItem(
                                icon: Icons.work_outline,
                                iconColor: Colors.pinkAccent,
                                title: 'ตำแหน่ง',
                                value: user.jobPosition ?? "-",
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: _ProfileItem(
                                icon: Icons.trending_up,
                                iconColor: Colors.orange,
                                title: 'ระดับ',
                                value: user.jobLevel ?? "-",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _ProfileItem(
                          icon: Icons.apartment,
                          iconColor: Colors.teal,
                          title: 'สำนัก',
                          value: user.jobOffice ?? "-",
                        ),

                        const SizedBox(height: 12),

                        _ProfileItem(
                          icon: Icons.account_tree_outlined,
                          iconColor: Colors.green,
                          title: 'ฝ่าย',
                          value: user.jobDepartment ?? "-",
                        ),

                        const SizedBox(height: 50),

                        /// SIGN OUT
                        SizedBox(
                          width: 350,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () => _showLogoutDialog(context),
                            icon: const Icon(
                              Icons.logout,
                              size: 20,
                            ),
                            label: const Text(
                              'SIGN OUT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'InstrumentSans',
                                letterSpacing: .5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF18181C),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// pop up ออกจากระบบ
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => alert_image_two_button(
        text: "ยืนยันการออกจากระบบ",
        assets_image: "assets/images/sign_out.png",
        one_text_button: "ยกเลิก",
        one_onPressed: () => Navigator.pop(dialogContext),
        two_text_button: "ตกลง",
        two_onPressed: () {
          Navigator.pop(dialogContext);
          context.read<AuthCubit>().logout();
        },
      ),
    );
  }
}


/// ── เลือกรูป Profile และ CROP ────────────────────────────────
class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.055),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: iconColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    fontFamily: 'NotoSansThai',
                    color: Color(0xFF707078),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansThai',
                    color: Color(0xFF24252A),
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