import 'package:offline_gnss69_new/export.dart';

class OtpLoginPage extends StatefulWidget {
  final UserModel tempUser;
  final String hash;

  static MaterialPageRoute route({
    required UserModel tempUser,
    required String hash,
  }) =>
      MaterialPageRoute(
        builder: (_) => OtpLoginPage(tempUser: tempUser, hash: hash)
      );

  const OtpLoginPage({
    super.key,
    required this.tempUser,
    required this.hash,
  });

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {

  final TextEditingController _otpController = TextEditingController();

  // ตัวแปรสำหรับนับเวลาถอยหลัง
  late String _currentHash;
  Timer? _timer;
  int _start = 60; // 60 วินาที
  bool _canResend = false;


  /// ── นับถอยหลัง OTP ──────────────────────
  void startTimer() {
    _canResend = false;
    _start = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  /// ── ข้อความนับถอยหลัง ──────────────────────
  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// ── Resend OTP ──────────────────────
  void _handleResend() {
    if (_canResend) {

      context.read<AuthCubit>().resendOtp(widget.tempUser.email);

      context.showSnackBar(
        message: 'ส่งรหัส OTP ใหม่สำเร็จ',
        backgroundColor: Colors.grey[900]!,
      );
      startTimer(); // เริ่มนับถอยหลังใหม่
    }
  }

  /// ── ช่องกรอก OTP ──────────────────────
  final defaultPinTheme = PinTheme(
    width: 70,
    height: 70,
    textStyle: const TextStyle(     // ตัวอักษรในช่อง OTP
      fontSize: 28,
      fontWeight: FontWeight.w700,
      fontFamily: 'InstrumentSans',
      color: Colors.black,
    ),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade400,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(2, 2),
        ),
      ],
    ),
  );


  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _currentHash = widget.hash;
    startTimer();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              context.showSnackBar(
                message: state.error,
                backgroundColor: Colors.red,
              );
              _otpController.clear();  // เคลียร์รหัสถ้ากรอกผิด
            }

            /// Resend OTP
            if (state is AuthResendOtpSuccess) {
              setState(() {
                _currentHash = state.hash;
              });
            }

            /// ไปหน้า home แยกตาม status user
            if (state is AuthLoggedIn) {

              final userStatus = state.userModel.status;

              if (userStatus == 'admin') {
                Navigator.of(context).pushAndRemoveUntil(
                  AdminMainWrapper.route(), (route) => false,
                );
              } else if (userStatus == 'user') {
                Navigator.of(context).pushAndRemoveUntil(
                  UserMainWrapper.route(), (route) => false,
                );
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  NullUserMainWrapper.route(), (route) => false,
                );
              }
            }
          },

        builder: (context, state) {
          return Stack(
            children: [
              Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 70, 25, 40),
                    child: Column(
                      children: [

                        w_text_big(
                          name: "Enter Verification Code!",
                          font_Size: 35,
                          color: Colors.black,
                          shadowwithOpacity: 0.5,
                          offset: 2,
                          blurRadius: 3,
                        ),

                        const SizedBox(height: 20),

                        Image.asset(
                          "assets/images/otp.png",
                          height: 300,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 20),

                        w_text_big(
                          name: 'We sent OTP to  "${widget.tempUser.email}"',
                          font_Size: 20,
                          color: Colors.black,
                          shadowwithOpacity: 0,
                          offset: 0,
                          blurRadius: 0,
                        ),

                        const SizedBox(height: 10),

                        // แสดงเวลานับถอยหลัง
                        Text(
                          "Code expires in: $timerText",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 30),

                        /// ช่องกรอก OTP (6 ช่อง)
                        Pinput(
                          controller: _otpController,
                          length: 6,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          defaultPinTheme: defaultPinTheme,
                          onCompleted: (pin) {
                            context.read<AuthCubit>().verifyLoginOtp(
                              otp: pin,
                              hash: _currentHash,
                              tempUser: widget.tempUser,
                            );
                          },
                        ),

                        const SizedBox(height: 30),

                        /// Resend OTP
                        GestureDetector(
                          onTap: (state is AuthLoading || !_canResend) ? null : _handleResend,
                          child: RichText(
                            text: TextSpan(
                              text: 'Didn’t receive a OTP?  ',
                              style: const TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 18.0,
                                color: Color.fromARGB(255, 112, 109, 109),
                              ),
                              children: [
                                TextSpan(
                                  text: _canResend
                                      ? 'Resend OTP'
                                      : 'Wait ${_start}s',
                                  style: TextStyle(
                                    color: (state is AuthLoading)
                                        ? Colors.grey
                                        : Colors.red,
                                    fontFamily: 'InstrumentSans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18.0,
                                  ),
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


