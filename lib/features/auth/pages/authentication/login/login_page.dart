import 'package:offline_gnss69_new/export.dart';

class LoginPage extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const LoginPage(),
  );

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// สั่งให้ทุก field ตรวจสอบความถูกต้อง เมื่อกดปุ่ม login
  void loginUser() {
    if (formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                context.showSnackBar(message: state.error);
              } else if (state is AuthLoginOtpSent) {

                /// ส่ง OTP >> ไปหน้า OTP Login
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OtpLoginPage(
                      tempUser: state.tempUser,
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
                    padding: const EdgeInsets.all(50.0),
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          
                          w_text_big(
                              name: 'Welcome  back!',
                              font_Size: 40,
                              color: Colors.black,
                          ),

                          const SizedBox(height: 3),
                          
                          Stack(
                            children: [

                              // ข้อความที่เป็น stroke
                              Text(
                                'Login to your account',
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
                                'Login to your account',
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

                          /// Email
                          text_field_login(
                            controller: emailController,
                            hintText: 'Email Address',
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.trim().contains("@")) {
                                return "กรุณาตรวจสอบ Email";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          /// Password
                          text_field_login(
                            controller: passwordController,
                            hintText: 'Password',
                            isPassword: true,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  value.trim().length < 6) {
                                return "กรุณาตรวจสอบ Password";
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
                                'Forgot password?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'NotoSansThai',
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 50),
                          
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 2.5,
                            child: button_icon(
                                name: 'Log in',
                                name_size: 16,
                                icon: Icons.arrow_forward_sharp,
                                icon_size: 20,
                                onPressed: loginUser
                            ),

                          ),
                          
                          SizedBox(height: 15),
                          
                          GestureDetector(
                            onTap: (){
                              Navigator.of(context).push(SignupPage.route());
                            },
                            child: RichText(
                                text: TextSpan(
                                  text: 'Don\'t have an account? ',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFamily: 'InstrumentSans',
                                    fontWeight: FontWeight.w500,
                                    color: const Color.fromARGB(255, 112, 109, 109),
                                    shadows: [
                                      Shadow(
                                        color: Colors.grey.withOpacity(0.4),
                                        offset: const Offset(1, 1),
                                        blurRadius: 3.0,
                                      ),
                                    ],
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign up here',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontFamily: 'InstrumentSans',
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.grey.withOpacity(0.4),
                                            offset: const Offset(1, 1),
                                            blurRadius: 3.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),

                /// Loading
                if (state is AuthLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

              ],
            );
        
          }
        ),
      ),
    );
  }
}

