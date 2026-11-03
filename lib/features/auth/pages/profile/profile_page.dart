import 'package:nexa_sketch/export.dart';

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
                            name: "My Profile!",
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
                                        text: "แก้ไขข้อมูลไม่สำเร็จ\nกรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง",
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
                              'ออกจากระบบ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'NotoSansThai',
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

  /// pop up ยืนยันออกจากระบบ (กรณีมีข้อมูลค้าง)
  Future<void> _showLogoutDialog(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final pending = await authCubit.countPendingSyncData();
    if (!context.mounted) return;

    if (pending == 0) {
      _showConfirmLogoutDialog(context);
      return;
    }

    final action = await showDialog<_LogoutAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PendingSyncDialog(pending: pending),
    );
    if (!context.mounted || action == null || action == _LogoutAction.cancel) return;

    if (action == _LogoutAction.discard) {
      authCubit.logout();
      return;
    }

    // ── ลองส่งข้อมูลทั้งหมด แล้วนับใหม่ ──
    final remaining = await _syncAllPending(context);
    if (!context.mounted) return;

    if (remaining == 0) {
      _showConfirmLogoutDialog(context);
    } else {
      // มีรายการที่ server ปฏิเสธ >> แสดงสาเหตุ (สูงสุด 3 รายการ) แทนการบอกแค่ให้เช็คเน็ต
      final issues = await SyncService.instance.describeSyncIssues();
      if (!context.mounted) return;

      final detail = issues.isEmpty
          ? 'กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง'
          : [
        ...issues.take(3),
        if (issues.length > 3) 'และอีก ${issues.length - 3} รายการ',
      ].join('\n');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => alert_image_one_button(
          text: 'ส่งข้อมูลไม่สำเร็จ\n$detail',
          assets_image: "assets/images/no_wifi.png",
          text_button: "ตกลง",
          onPressed: () => Navigator.pop(dialogContext),
        ),
      );
    }
  }

  /// ซิงค์ข้อมูลที่ค้างทั้งหมด (โครงการ >> หมุดรังวัด >> โปรไฟล์)
  Future<int> _syncAllPending(BuildContext context) async {
    final authCubit  = context.read<AuthCubit>();

    final state = authCubit.state;
    if (state is! AuthLoggedIn) return authCubit.countPendingSyncData();
    final token = state.userModel.token;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ผู้ใช้กด sync เอง >> ลองรายการที่เคยเจอ error ถาวรด้วย
      await SyncService.instance.syncAll(token, retryBlocked: true);
      await authCubit.syncPendingUser(token: token);
    } catch (e) {
      if (kDebugMode) debugPrint('_syncAllPending error: $e');
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    return authCubit.countPendingSyncData();
  }

  /// pop up ยืนยันออกจากระบบ (กรณีไม่มีข้อมูลค้าง)
  void _showConfirmLogoutDialog(BuildContext context) {
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

/// เตือนข้อมูลค้างก่อน logout
enum _LogoutAction { cancel, discard, sync }


/// ── pop up ข้อมูลค้าง ──
class _PendingSyncDialog extends StatelessWidget {
  final int pending;
  const _PendingSyncDialog({required this.pending});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F7F8),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_outlined,
            size: 44,
            color: Color(0xFF18181C),
          ),
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 20),

            const Text(
              'มีข้อมูลที่ยังไม่ได้ส่งขึ้นเซิร์ฟเวอร์',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'NotoSansThai',
                color: Color(0xFF18181C),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'มีข้อมูล $pending รายการที่บันทึกไว้ขณะไม่มีอินเทอร์เน็ต\nข้อมูลเหล่านี้จะถูกลบหากออกจากระบบ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'NotoSansThai',
                color: Color(0xFF707078),
              ),
            ),

            const SizedBox(height: 22),

            /// ปุ่มส่งข้อมูล
            _DialogButton(
              text: 'ส่งข้อมูลขึ้นเซิร์ฟเวอร์',
              background: const Color(0xFF18181C),
              foreground: Colors.white,
              onPressed: () => Navigator.pop(context, _LogoutAction.sync),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    text: 'ยกเลิก',
                    background: const Color(0xFFF3F3F5),
                    foreground: const Color(0xFF18181C),
                    onPressed: () => Navigator.pop(context, _LogoutAction.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    text: 'ทิ้งข้อมูลและออก',
                    background: const Color(0xFFFDECEC),
                    foreground: Colors.red,
                    onPressed: () => Navigator.pop(context, _LogoutAction.discard),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.text,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),
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