import 'package:offline_gnss69_new/export.dart';


class Profile_Reset_Password_Page extends StatefulWidget {
  final String email;

  static MaterialPageRoute route({required String email}) => MaterialPageRoute(
    builder: (context) => Profile_Reset_Password_Page(email: email),
  );

  const Profile_Reset_Password_Page({super.key, required this.email});

  @override
  State<Profile_Reset_Password_Page> createState() => _Profile_Reset_Password_PageState();
}

class _Profile_Reset_Password_PageState extends State<Profile_Reset_Password_Page> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // ── เก็บ error จาก server (รหัสผ่านปัจจุบันไม่ถูกต้อง) ────────────
  String? _currentPasswordServerError;

  @override
  void initState() {
    super.initState();
    // ล้าง error จาก server ทันทีที่ผู้ใช้แก้ไขช่องรหัสผ่านปัจจุบัน
    currentPasswordController.addListener(() {
      if (_currentPasswordServerError != null) {
        setState(() => _currentPasswordServerError = null);
        formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void checkChangePassword() {
    if (!formKey.currentState!.validate()) return;

    // เช็ค new password = confirm password
    if (newPasswordController.text != confirmPasswordController.text) {
      context.showSnackBar(
        message: 'Password และ Confirm Password ไม่ตรงกัน',
        backgroundColor: Colors.grey[900]!,
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;

    context.read<AuthCubit>().resetPasswordWithCurrentPassword(
      token:           authState.userModel.token,
      currentPassword: currentPasswordController.text,
      newPassword:     newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            // ✅ แสดง error ที่ errorBorder ของช่องรหัสผ่านปัจจุบันแทน dialog
            setState(() => _currentPasswordServerError = state.error);
            formKey.currentState?.validate();
          }

          if (state is ResetPasswordSuccess) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => alert_image_one_button(
                text: "เปลี่ยนรหัสผ่านสำเร็จ",
                assets_image: "assets/images/checkmark.png",
                text_button: "ตกลง",
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด dialog
                  Navigator.of(context).pop(); // ปิดหน้า reset password
                  Navigator.of(context).pop(); // ปิดหน้า edit profile >> กลับไป profile_page
                },
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(40.0),
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),

                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        w_text_big(
                          name: 'Reset Password!',
                          font_Size: 40,
                          color: Colors.black,
                        ),

                        SizedBox(height: 3),

                        Stack(
                          children: [
                            // ข้อความที่เป็น stroke
                            Text(
                              'Change Password with Current Password',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontFamily: 'InstrumentSans',
                                fontWeight: FontWeight.w400,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1
                                  ..color = Colors.grey,
                              ),
                            ),

                            // ข้อความหลัก
                            Text(
                              'Change Password with Current Password',
                              style: TextStyle(
                                fontSize: 20.0,
                                color: Color.fromARGB(255, 112, 109, 109),
                                fontFamily: 'InstrumentSans',
                                fontWeight: FontWeight.w400,
                                shadows: [
                                  Shadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    offset: Offset(2, 2),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),

                          ],
                        ),

                        SizedBox(height: 60),

                        text_field_login(
                          controller: currentPasswordController,
                          hintText: 'Current Password',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาระบุรหัสผ่านปัจจุบัน';
                            }
                            // ✅ แสดง error จาก server ตรงนี้ (ขึ้นที่ errorBorder ของช่องนี้)
                            if (_currentPasswordServerError != null) {
                              return _currentPasswordServerError;
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 15),

                        // w_text_field_login(
                        //   controller: newPasswordController,
                        //   hintText: 'New Password',
                        //   isPassword: true,
                        //   validator: (value) {
                        //     if (value == null || value.isEmpty) {
                        //       return 'กรุณาระบุรหัสผ่านใหม่';
                        //     }
                        //     if (value.length < 6) {
                        //       return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว';
                        //     }
                        //     return null;
                        //   },
                        // ),

                        text_field_login(
                          controller: newPasswordController,
                          hintText: 'New Password',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณาระบุรหัสผ่าน';
                            }

                            if (value.length < 6) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            }

                            // ต้องมีตัวอักษรภาษาอังกฤษ
                            if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                              return 'รหัสผ่านต้องมีตัวอักษรภาษาอังกฤษ (A-Z หรือ a-z)';
                            }

                            // ต้องมีตัวเลข
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'รหัสผ่านต้องมีตัวเลข (0-9)';
                            }

                            // ต้องมีอักขระพิเศษ
                            if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\\/\[\]~`]').hasMatch(value)) {
                              return 'รหัสผ่านต้องมีอักขระพิเศษ';
                            }

                            return null;
                          },
                        ),

                        SizedBox(height: 10.0),

                        Container(
                          alignment: Alignment.topLeft,
                          child: Text(
                            ' * รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร                    * รหัสผ่านต้องมีตัวอักษรภาษาอังกฤษ (A-Z หรือ a-z)\n * รหัสผ่านต้องมีตัวเลข (0-9)                                 * รหัสผ่านต้องมีอักขระพิเศษ',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'NotoSansThai',
                              color: Colors.grey,
                            ),
                          ),
                        ),

                        SizedBox(height: 15),

                        text_field_login(
                          controller: confirmPasswordController,
                          hintText: 'Confirm Password',
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณายืนยันรหัสผ่านใหม่';
                            }
                            if (value != newPasswordController.text) {
                              return 'กรุณาตรวจสอบรหัสผ่านใหม่';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(Reset_Password_Page.route());
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot current password?',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'NotoSansThai',
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 50.0),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5,
                              child: button_icon(
                                name: 'Cancel',
                                name_size: 16,
                                icon: Icons.close,
                                icon_size: 20,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),

                            SizedBox(width: 10.0),

                            SizedBox(
                              width: MediaQuery.of(context).size.width / 2.5,
                              child: button_icon(
                                name: 'Save',
                                name_size: 16,
                                icon: Icons.save_alt_outlined,
                                icon_size: 20,
                                onPressed: checkChangePassword,
                              ),
                            ),

                          ],
                        ),

                      ],
                    ),
                  ),

                ),
              ),

              // Loading Overlay
              if (state is AuthLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}