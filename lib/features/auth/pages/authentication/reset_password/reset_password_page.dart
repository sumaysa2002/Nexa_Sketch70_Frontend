import 'package:offline_gnss69_new/export.dart';

class Reset_Password_Page extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const Reset_Password_Page(),
  );

  const Reset_Password_Page({super.key});

  @override
  State<Reset_Password_Page> createState() => _Reset_Password_PageState();
}

class _Reset_Password_PageState extends State<Reset_Password_Page> {

  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirm_passwordController = TextEditingController();


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirm_passwordController.dispose();
    super.dispose();
  }

  /// สั่งให้ทุก field ตรวจสอบความถูกต้อง เมื่อกดปุ่ม Continue
  void checkResetPassword() {
    if (!formKey.currentState!.validate()) return;

    // เช็ค password = confirm_password
    if (passwordController.text != confirm_passwordController.text) {
      context.showSnackBar(
        message: 'Password และ Confirm Password ไม่ตรงกัน',
        backgroundColor: Colors.grey[900]!,
      );
      return;
    }

    // เช็ค Email ในระบบ >> ถ้ามี → ส่ง OTP แล้วไปหน้า OTP
    context.read<AuthCubit>().resetPasswordWithEmail(
      email: emailController.text.trim().toLowerCase(),
      newPassword: passwordController.text,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            context.showSnackBar(
              message: state.error,
              backgroundColor: Colors.grey[900]!,
            );
          }

          if (state is AuthResetPasswordOtpSent) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Otp_Reset_Password_Page(
                  email: state.email,
                  newPassword: state.newPassword,
                  hash: state.hash,
                ),
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

                          const SizedBox(height: 3),

                          Stack(
                            children: [

                              // ข้อความที่เป็น stroke
                              Text(
                                'Change Password with Email',
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
                                'Change Password with Email',
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

                          const SizedBox(height: 60),

                          text_field_login(
                            controller: emailController,
                            hintText: 'Email Address',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "กรุณาระบุ Email";
                              }

                              final email = value.trim();

                              final emailRegex = RegExp(
                                r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                              );

                              if (!emailRegex.hasMatch(email)) {
                                return "กรุณาตรวจสอบ Email";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          text_field_login(
                            controller: passwordController,
                            hintText: 'New password',
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

                          const SizedBox(height: 10.0),

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

                          const SizedBox(height: 15),

                          text_field_login(
                            controller: confirm_passwordController,
                            hintText: 'Confirm password',
                            isPassword: true,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return 'กรุณายืนยันรหัสผ่าน';
                              }
                              if (value !=
                                  passwordController.text) {
                                return 'กรุณาตรวจสอบรหัสผ่าน';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 50.0),

                          SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width / 2.5,
                            child: button_icon(
                                name: 'Continue',
                                name_size: 16,
                                icon: Icons.arrow_forward_sharp,
                                icon_size: 20,
                                onPressed: checkResetPassword
                            ),
                          ),

                        ],
                      )
                  ),
                ),
              ),

              /// Loading
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