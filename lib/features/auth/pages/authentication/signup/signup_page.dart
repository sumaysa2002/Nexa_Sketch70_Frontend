import 'package:offline_gnss69_new/export.dart';

class SignupPage extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const SignupPage(),
  );

  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final formKey = GlobalKey<FormState>();

  final first_nameController = TextEditingController();
  final last_nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirm_passwordController = TextEditingController();

  String? title_name;
  String? job_position;
  String? job_level;
  String? job_office;
  String? job_department;

  // เก็บรูป
  Uint8List? _profileImage;
  final ImagePicker _picker_profile = ImagePicker();


  /// ตัวเลือก Dropdown : สำนัก >> รายการฝ่าย
  final Map<String, List<String>> officeToDepartments = {
    'สำนักประยุกต์และพัฒนาภูมิสารสนเทศ':
    [
      'งานบริหารทั่วไป',
      'ฝ่ายทรัพยากรธรรมชาติและสิ่งแวดล้อม',
      'ฝ่ายจัดการภัยธรรมชาติ',
      'ฝ่ายจัดการการเกษตร',
      'ฝ่ายความมั่นคงทางสังคม',
    ],
    'สำนักนวัตกรรมเทคโนโลยีภูมิสารสนเทศ':
    [
      'งานบริหารทั่วไป',
      'ฝ่ายจัดการภูมิสารสนเทศขนาดใหญ่',
      'ฝ่ายแผนที่และสำรวจ',
      'ฝ่ายภูมิสารสนเทศเชิงกลยุทธ์',
    ],

  };


  /// ── เลือกวิธีการถ่ายรูป ──────────────────────
  void _showProfilePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const w_text_thai_notosansthai(
                  name: "ถ่ายภาพ",
                  font_Size: 16
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const w_text_thai_notosansthai(
                  name: "เลือกจากแกลอรี่",
                  font_Size: 16
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }


  /// ── เลือกรูป Profile และ CROP ────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {

    // เลือกรูปจาก Camera หรือ Gallery
    final XFile? pickedFile = await _picker_profile.pickImage(
      source: source,
    );

    if (pickedFile != null) {

      // Crop ภาพ
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 90,
        maxWidth: 450,
        maxHeight: 450,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Profile photo',
            toolbarColor: const Color(0xFF18181C),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Profile photo',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {

        // ตัดไฟล์เป็น Bytes เพื่อนำไปแสดงผลและส่ง Payload
        final bytes = await croppedFile.readAsBytes();

        setState(() {
          _profileImage = bytes;
        });

      }
    }
  }


  @override
  void dispose() {
    first_nameController.dispose();
    last_nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirm_passwordController.dispose();
    super.dispose();
  }

  /// สั่งให้ทุก field ตรวจสอบความถูกต้อง เมื่อกดปุ่ม SIGN UP
  void signUpUser() {
    if (!formKey.currentState!.validate()) return;

    // เช็ค password = confirm_password
    if (passwordController.text != confirm_passwordController.text) {
      context.showSnackBar(
        message: 'Password และ Confirm Password ไม่ตรงกัน',
        backgroundColor: Colors.grey[900]!,
      );
      return;
    }

    final payload = SignupPayload(
      first_name: first_nameController.text.trim(),
      last_name: last_nameController.text.trim(),
      phone: phoneController.text.replaceAll('-', '').trim(),
      email: emailController.text.trim().toLowerCase(),
      password: passwordController.text,

      title_name: title_name,
      job_position: job_position,
      job_level: job_level,
      job_office: job_office,
      job_department: job_department,

      profile_image: _profileImage,
    );

    // เช็ค Email ว่ามีอยู่แล้วหรือไม่
    context.read<AuthCubit>().signUpCheckEmail(
      payload: payload,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// Header
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft, // ไล่สีจากซ้าย
            end: Alignment.centerRight,  // ไปขวา
            colors: [
              Color(0xFF505050),
              Color(0xFF18181C),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 50),

              w_text_big(
                  name: 'Welcome!',
                  font_Size: 36,
                  color: Colors.white,
                  shadow_color: Colors.black
              ),
              w_text_big(
                  name: 'Create your account',
                  font_Size: 18,
                  color: Colors.white,
                  shadow_color: Colors.black,
                  offset: 1,
                  blurRadius: 3
              ),


              const SizedBox(height: 80),

              /// Body
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),

                      child: BlocConsumer<AuthCubit, AuthState>(
                          listener: (context, state) {
                            if (state is AuthError) {
                              context.showSnackBar(
                                message: state.error,
                                backgroundColor: Colors.red,
                              );
                            }

                            /// ถ้า Email ไม่ซ้าในระบบ >> OTP Signup
                            if (state is AuthSignupOtpSent) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OtpSignupPage(
                                    payload: state.payload,
                                    hash: state.hash,
                                  ),
                                ),
                              );
                            }
                          },

                        /// Loading
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(40, 70, 25, 40),
                            child: Form(
                              key: formKey,
                              child: Column(
                                children: [
                                  Row(
                                    children: [

                                      SizedBox(
                                        width: 120,
                                        height: 110,
                                        child: dropdown_field_c5(
                                          name: "คำนำหน้า :",
                                          value: title_name,
                                          items: ['นาย', 'นาง', 'นางสาว'],
                                          validator: (val) {
                                            if (val == null)
                                              return 'กรุณาเลือกคำนำหน้า';
                                            return null;
                                          },
                                          onChanged: (val) {
                                            setState(() {
                                              title_name = val;
                                            });
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 10.0),

                                      Expanded(
                                        child: text_field_column_c5(
                                          name: "ชื่อ :",
                                          controller: first_nameController,
                                          hintText: "First Name",
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'กรุณาระบุชื่อ';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 10.0),

                                      Expanded(
                                        child: text_field_column_c5(
                                          name: "สกุล :",
                                          controller: last_nameController,
                                          hintText: "Last Name",
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'กรุณาระบุสกุล';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                    ],
                                  ),

                                  text_field_column_c5(
                                    name: "เบอร์โทร :",
                                    controller: phoneController,
                                    hintText: "Phone number",
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      PhoneFormat(),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'กรุณาระบุเบอร์โทรศัพท์';
                                      }

                                      final digits = value.replaceAll('-', '');
                                      if (digits.length != 10) {
                                        return 'กรุณาตรวจสอบเบอร์โทรศัพท์';
                                      }
                                      return null;
                                    },
                                  ),

                                  text_field_column_c5(
                                    name: "Email Address :",
                                    controller: emailController,
                                    hintText: "Email address",
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

                                  Row(
                                    children: [

                                      Expanded(
                                        child: text_field_column_c5(
                                          name: "Password :",
                                          controller: passwordController,
                                          hintText: "Password",
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
                                      ),

                                      const SizedBox(width: 10.0),

                                      Expanded(
                                        child: text_field_column_c5(
                                          name: "Confirm password :",
                                          controller: confirm_passwordController,
                                          hintText: "Confirm password",
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
                                      ),

                                    ],
                                  ),

                                  Container(
                                    alignment: Alignment.topLeft,
                                    child: const Text(
                                      ' * รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร                                               * รหัสผ่านต้องมีตัวอักษรภาษาอังกฤษ (A-Z หรือ a-z)\n * รหัสผ่านต้องมีตัวเลข (0-9)                                                            * รหัสผ่านต้องมีอักขระพิเศษ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'NotoSansThai',
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 25.0),

                                  /// ตำแหน่ง & ระดับ
                                  Row(
                                    children: [

                                      Expanded(
                                        child: dropdown_field_c5(
                                            name: "ตำแหน่ง : ",
                                            value: job_position,
                                            items: [
                                              'เจ้าหน้าที่เทคโนโลยีสารสนเทศ',
                                              'เจ้าหน้าที่จัดการงานทั่วไป',
                                              'เจ้าหน้าที่ประสานงานวิชาการ',
                                              'นักพัฒนานวัตกรรม',
                                              'นักภูมิสารสนเทศ',
                                              'วิศวกร',
                                            ],
                                            prefixIcon: Icons.work_outline,
                                            onChanged: (val) {
                                              setState(() {
                                                job_position = val;
                                              });
                                            }
                                        ),
                                      ),

                                      const SizedBox(width: 10.0),

                                      Expanded(
                                        child: dropdown_field_c5(
                                            name: "ระดับ : ",
                                            value: job_level,
                                            items: [
                                              'ปฏิบัติการ',
                                              'ชำนาญการ',
                                              'ชำนาญการพิเศษ'
                                            ],
                                            prefixIcon: Icons.trending_up,
                                            onChanged: (val) {
                                              setState(() {
                                                job_level = val;
                                              });
                                            }
                                        ),
                                      ),
                                    ],
                                  ),


                                  /// สำนัก & ฝ่าย
                                  Row(
                                    children: [

                                      Expanded(
                                        child: dropdown_field_c5(
                                          name: "สำนัก : ",
                                          value: job_office,
                                          items: officeToDepartments.keys.toList(),
                                          prefixIcon: Icons.apartment,
                                          onChanged: (val) {
                                            setState(() {
                                              job_office = val;
                                              job_department = null;
                                            });
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 10.0),

                                      Expanded(
                                        child: dropdown_field_c5(
                                          name: "ฝ่าย : ",
                                          value: job_department,
                                          items: job_office != null
                                              ? officeToDepartments[job_office]!
                                              : [],
                                          prefixIcon: Icons.account_tree_outlined,
                                          onChanged: (val) {
                                            setState(() {
                                              job_department = val;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20.0),

                                  SizedBox(
                                    width: MediaQuery
                                        .of(context)
                                        .size
                                        .width / 2.5,
                                    child: button_icon(
                                        name: 'SIGN UP',
                                        name_size: 16,
                                        icon: Icons.app_registration_rounded,
                                        icon_size: 20,
                                        onPressed: signUpUser
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          LoginPage.route());
                                    },
                                    child: RichText(
                                        text: TextSpan(
                                          text: 'Already have an account? ',
                                          style: Theme
                                              .of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                            fontFamily: 'InstrumentSans',
                                            fontWeight: FontWeight.w500,
                                            color: const Color.fromARGB(255, 112, 109, 109),
                                            shadows: [
                                              Shadow(
                                                color: Colors.grey.withOpacity(0.5),
                                                offset: const Offset(1, 1),
                                                blurRadius: 3.0,
                                              ),
                                            ],
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Sign in',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontFamily: 'InstrumentSans',
                                                fontWeight: FontWeight.w700,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.grey.withOpacity(0.5),
                                                    offset: const Offset(1, 1),
                                                    blurRadius: 3.0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                    ),
                                  )

                                ],
                              ),
                            ),
                          );
                        }
                      ),
                    ),

                    /// ส่วนแสดง Profile Image
                    Positioned(
                      top: -50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [

                            // Profile Image
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFFF3F3F3),
                                backgroundImage:
                                _profileImage != null ? MemoryImage(_profileImage!) : null,
                                child: _profileImage == null
                                    ? const Icon(
                                  Icons.person_outline,
                                  size: 50,
                                  color: Colors.grey,
                                )
                                    : null,
                              ),
                            ),

                            // Camera Icon
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: GestureDetector(
                                onTap: _showProfilePicker,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF303030),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
