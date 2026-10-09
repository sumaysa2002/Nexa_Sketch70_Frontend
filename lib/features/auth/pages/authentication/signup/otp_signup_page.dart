import 'package:offline_gnss69_new/export.dart';

class OtpSignupPage extends StatefulWidget {
  final SignupPayload payload;
  final String hash;

  static MaterialPageRoute route({
    required SignupPayload payload,
    required String hash,
  }) =>
      MaterialPageRoute(
        builder: (_) => OtpSignupPage(payload: payload, hash: hash),
      );

  const OtpSignupPage({
    super.key,
    required this.payload,
    required this.hash
  });

  @override
  State<OtpSignupPage> createState() => _OtpSignupPageState();
}

class _OtpSignupPageState extends State<OtpSignupPage> {

  final TextEditingController _otpController = TextEditingController();

  // ตัวแปรสำหรับนับเวลาถอยหลัง
  late String _currentHash;

  // จำนวนครั้งที่กรอก OTP ไปแล้ว (ค่าจาก backend)
  int _attempts = 0;
  int _maxAttempts = 5;
  bool get _isLocked => _attempts >= _maxAttempts;
  Timer? _timer;
  int _start = 60; // 60 วินาที
  bool _canResend = false;


  /// ── นับถอยหลัง OTP ──────────────────────
  /// seconds = เวลาที่ต้องรอก่อนกด Resend ได้ (ปกติ 60 วิ / ถ้าครบโควตาใช้ค่าจาก backend)
  void startTimer([int seconds = 60]) {
    _canResend = false;
    _start = seconds;
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
      // ปุ่มถูกปิดระหว่าง AuthLoading อยู่แล้ว → รอผลจาก backend:
      // สำเร็จ → นับ 60 วิ / ครบโควตา → นับตามเวลาที่ต้องรอ (ดูใน listener)

      context.read<AuthCubit>().resendOtp(widget.payload.email);
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
          /// ยืนยัน OTP ไม่ผ่าน → อัปเดตจำนวนครั้งที่กรอก
          if (state is AuthOtpInvalid) {
            setState(() {
              _attempts = state.attempts;
              _maxAttempts = state.maxAttempts;
            });
          }

          if (state is AuthError) {
            context.showSnackBar(
              message: state.error,
              backgroundColor: Colors.grey.shade900,
            );
            _otpController.clear(); // เคลียร์รหัสถ้ากรอกผิด
          }

          /// Resend OTP
          /// ขอ OTP ครบโควตา → ล็อกปุ่ม Resend จนกว่าจะพ้นเวลาที่ backend กำหนด
          if (state is AuthOtpRateLimited) {
            startTimer(state.retryAfterSeconds);
          }

          if (state is AuthResendOtpSuccess) {
            setState(() {
              _currentHash = state.hash;
              _attempts = 0; // รหัสรอบใหม่ เริ่มนับใหม่
            });
            context.showSnackBar(
              message: 'ส่งรหัส OTP ใหม่สำเร็จ',
              backgroundColor: Colors.grey.shade900,
            );
            startTimer(); // ขอรหัสใหม่ได้อีกครั้งหลัง 60 วิ
          }

          /// เมื่อสมัครสำเร็จ ให้แจ้งเตือนและส่งกลับหน้า Login
          if (state is AuthSignupSuccess) {
            context.showSnackBar(
              message: 'สมัครสมาชิกสำเร็จ กรุณาเข้าสู่ระบบ',
              backgroundColor: Colors.grey.shade900,
            );
            Navigator.of(context).pushAndRemoveUntil(
              LoginPage.route(),
                  (route) => false,
            );
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
                          name: 'We sent OTP to  "${widget.payload.email}"',
                          font_Size: 20,
                          color: Colors.black,
                          shadowwithOpacity: 0,
                          offset: 0,
                          blurRadius: 0,
                        ),

                        const SizedBox(height: 10),

                        /// แสดงเวลานับถอยหลัง
                        Text(
                          "Resend available in: $timerText",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 30),

                        /// ช่องกรอก OTP (6 ช่อง)
                        /// Ref ของ OTP รอบนี้ + จำนวนครั้งที่กรอก
                        OtpStatusPanel(
                          hash: _currentHash,
                          attempts: _attempts,
                          maxAttempts: _maxAttempts,
                        ),

                        const SizedBox(height: 20),

                        Pinput(
                          enabled: !_isLocked, // กรอกผิดครบแล้ว ล็อกช่องจนกว่าจะขอรหัสใหม่
                          controller: _otpController,
                          length: 6,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          defaultPinTheme: defaultPinTheme,
                          onCompleted: (pin) {
                            context.read<AuthCubit>().verifyOtp(
                              otp: pin,
                              hash: _currentHash,
                              payload: widget.payload,
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
                                      : 'Wait $timerText',
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
