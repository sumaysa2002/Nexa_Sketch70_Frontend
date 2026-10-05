import 'package:offline_gnss69_new/export.dart';

class Profile_Edit_Page extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const Profile_Edit_Page(),
  );
  const Profile_Edit_Page({super.key});

  @override
  State<Profile_Edit_Page> createState() => _Profile_Edit_PageState();
}

class _Profile_Edit_PageState extends State<Profile_Edit_Page> {

  final formKey = GlobalKey<FormState>();

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;

  String? titleName;
  String? jobPosition;
  String? jobLevel;
  String? jobOffice;
  String? jobDepartment;

  // เก็บรูป
  Uint8List? _newProfileImage;
  Uint8List? _newSignatureImage;
  final ImagePicker _picker = ImagePicker();


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


  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    if (state is AuthLoggedIn) {
      final user = state.userModel;
      firstNameController = TextEditingController(text: user.firstName);
      lastNameController = TextEditingController(text: user.lastName);
      phoneController = TextEditingController(text: formatPhoneNumber(user.phone));

      titleName = user.titleName;
      jobPosition = user.jobPosition;
      jobLevel = user.jobLevel;
      jobOffice = user.jobOffice;

      final validDepartments = officeToDepartments[user.jobOffice] ?? [];
      jobDepartment = validDepartments.contains(user.jobDepartment)
          ? user.jobDepartment
          : null;

    }
  }


  /// ── เลือกวิธีการถ่ายรูป ──────────────────────
  void _showPicker() {
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
              }
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
              }
            ),

          ],
        ),
      ),
    );
  }


  /// ── เลือกรูป Profile และ CROP ────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {

    // เลือกรูปจาก Camera หรือ Gallery
    final XFile? pickedFile = await _picker.pickImage(source: source);

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
          _newProfileImage = bytes;
        });
      }
    }
  }


  /// ── เลือกรูปลายเซ็น และ CROP ────────────────────────────────
  Future<void> _pickAndCropSignature() async {

    // เลือกรูปจาก Gallery
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {

      // Crop ภาพ
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Signature',
            toolbarColor: const Color(0xFF18181C),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Signature',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {

        // ตัดไฟล์เป็น Bytes เพื่อนำไปแสดงผลและส่ง Payload
        final bytes = await croppedFile.readAsBytes();

        setState(() {
          _newSignatureImage = bytes;
        });
      }
    }
  }


  /// ── Format เบอร์โทร ────────────────────────────────
  String formatPhoneNumber(String phone) {

    // ลบทุกอย่างที่ไม่ใช่ตัวเลข
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return phone;

    // xxx-xxx-xxxx
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }


  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    super.dispose();
  }


  /// สั่งให้ทุก field ตรวจสอบความถูกต้อง เมื่อกดปุ่ม Save
  void editUser() async {
    if (!formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;
    final token = authState.userModel.token;

    // ลบ - ออกจากเบอร์โทร
    final phone = phoneController.text.replaceAll('-', '');

    await context.read<AuthCubit>().updateUserProfile(
      token:          token,
      titleName:      titleName ?? authState.userModel.titleName,
      firstName:      firstNameController.text.trim(),
      lastName:       lastNameController.text.trim(),
      phone:          phone,
      jobPosition:    jobPosition,
      jobLevel:       jobLevel,
      jobOffice:      jobOffice,
      jobDepartment:  jobDepartment,
      profileImage:   _newProfileImage,
      signatureImage: _newSignatureImage,
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is UpdateUserSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text: "แก้ไขข้อมูลสำเร็จ",
              assets_image: "assets/images/checkmark.png",
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              text_button: "ตกลง",
            ),
          );
        } else if (state is UpdateUserOfflineError) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text: "ไม่สามารถแก้ไขข้อมูลของคุณได้\nเนื่องจากอยู่ในโหมด offline",
              assets_image: "assets/images/no_wifi.png",
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              text_button: "ตกลง",
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {

            if (state is AuthLoggedIn) {
              final user = state.userModel;

              return Column(
                children: [

                  /// Header
                  SizedBox(
                    height: 250,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [

                        /// Background
                        Container(
                          height: 200,
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
                        ),

                        /// Title
                        Positioned(
                          top: 65,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: w_text_big(
                              name: "Edit profile!",
                              font_Size: 36,
                              color: Colors.white,
                              shadow_color: Colors.black,
                            ),
                          ),
                        ),

                        /// รูปโปรไฟล์
                        Positioned(
                          top: 140,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 5.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: const Color(0xFFF3F3F3),
                                    backgroundImage: _newProfileImage != null
                                        ? MemoryImage(_newProfileImage!)
                                        : (context.read<AuthCubit>().state as AuthLoggedIn).userModel.profileImg != null
                                        ? NetworkImage("${Constants.backendUri}/uploads/profiles/${(context.read<AuthCubit>().state as AuthLoggedIn).userModel.profileImg}") as ImageProvider
                                        : null,
                                    child: (_newProfileImage == null && (context.read<AuthCubit>().state as AuthLoggedIn).userModel.profileImg == null)
                                        ? const Icon(Icons.person, size: 55, color: Colors.grey)
                                        : null,
                                  ),
                                ),

                                /// Edit Icon
                                Positioned(
                                  bottom: 3,
                                  right: 3,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque, // เพิ่มเพื่อให้ตรวจจับแรงกดได้ดีขึ้น
                                    onTap: _showPicker,
                                    child: Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF303030),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 15,
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

                  const SizedBox(height: 25),

                  /// Body
                  Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 0,
                                bottom: 30,
                                left: 30,
                                right: 30,
                              ),
                              child: Form(
                                key: formKey,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      // ชื่อ-สกุล
                                      Row(
                                        children: [

                                          SizedBox(
                                            width: 120,
                                            height: 110,
                                            child: dropdown_field_c5(
                                              name: "คำนำหน้า :",
                                              value: titleName,
                                              items: ['นาย', 'นาง', 'นางสาว'],
                                              //prefixIcon: Icons.person,
                                              validator: (val) {
                                                if (val == null)
                                                  return 'กรุณาเลือกคำนำหน้า';
                                                return null;
                                              },
                                              onChanged: (val) => setState(() => titleName = val),
                                            ),
                                          ),

                                          SizedBox(width: 10.0),

                                          Expanded(
                                            child: text_field_column_c5(
                                              name: "ชื่อ :",
                                              controller: firstNameController,
                                              hintText: "First Name",
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'กรุณากรอกชื่อ';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),

                                          SizedBox(width: 10.0),

                                          Expanded(
                                            child: text_field_column_c5(
                                              name: "สกุล :",
                                              controller: lastNameController,
                                              hintText: "Last Name",
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'กรุณากรอกสกุล';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),

                                        ],
                                      ),

                                      // ลายเซ็น
                                      Text(
                                        "ลายเซ็น :",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'NotoSansThai',
                                        ),
                                      ),

                                      SizedBox(height: 10.0),

                                      // Container แสดงรูปลายเซ็น
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              height: 300,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(color: Color.fromARGB(255, 34, 34, 34), width: 1.2),
                                              ),
                                              child: _newSignatureImage != null
                                                  ? Image.memory(_newSignatureImage!, fit: BoxFit.contain) // แสดงรูปที่เพิ่งตัด
                                                  : (user.signature != null
                                                  ? Image.network(
                                                "${Constants.backendUri}/uploads/signatures/${user.signature}",
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) =>
                                                const Center(
                                                    child: Text("ไม่สามารถโหลดรูปลายเซ็นได้",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.grey,
                                                          fontFamily: 'NotoSansThai',
                                                          fontWeight: FontWeight.w500,
                                                        )
                                                    )
                                                ),
                                              )
                                                  : const Center(
                                                  child: Text("ยังไม่มีลายเซ็น",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey,
                                                        fontFamily: 'NotoSansThai',
                                                        fontWeight: FontWeight.w500,
                                                      )
                                                  ))),
                                            ),
                                          ),

                                          SizedBox(width: 10.0),

                                          // icon ไปหน้าแก้ไขลายเซ็น
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF18181C),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: IconButton(
                                              onPressed: _pickAndCropSignature,
                                              icon: const Icon(Icons.save_alt, color: Colors.white, size: 25),
                                            ),
                                          ),

                                        ],
                                      ),

                                      SizedBox(height: 20.0),

                                      // Email + ปุ่มเปลี่ยนรหัสผ่าน
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [

                                                Text(
                                                  "Email :",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily: 'NotoSansThai',
                                                  ),
                                                ),

                                                SizedBox(height: 10.0),

                                                Container(
                                                  width: double.infinity,
                                                  height: 55,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  alignment: Alignment.centerLeft,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(5),
                                                    border: Border.all(
                                                      color: Color.fromARGB(255, 34, 34, 34),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    user.email,
                                                    style: const TextStyle(
                                                      fontFamily: 'NotoSansThai',
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.black,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),

                                              ],
                                            ),
                                          ),

                                          SizedBox(width: 10.0),

                                          SizedBox(
                                            height: 55,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  Profile_Reset_Password_Page.route(email: user.email),
                                                );
                                              },

                                              icon: const Icon(
                                                  Icons.lock_reset,
                                                  size: 18,
                                                  color: Colors.white
                                              ),

                                              label: const Text(
                                                "เปลี่ยนรหัสผ่าน",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'NotoSansThai',
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF18181C),
                                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                              ),
                                            ),
                                          ),

                                        ],
                                      ),

                                      SizedBox(height: 20.0),

                                      // เบอร์โทร
                                      text_field_column_c5(
                                        name: "เบอร์โทร :",
                                        controller: phoneController,
                                        hintText: "-",
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          PhoneFormat(),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'กรุณากรอกเบอร์โทรศัพท์';
                                          }

                                          final digits = value.replaceAll('-', '');
                                          if (digits.length != 10) {
                                            return 'กรุณาตรวจสอบเบอร์โทรศัพท์';
                                          }
                                          return null;
                                        },
                                      ),

                                      // ตำแหน่ง & ระดับ
                                      Row(
                                        children: [

                                          Expanded(
                                              child: dropdown_field_c5(
                                                  name: "ตำแหน่ง : ",
                                                  value: jobPosition,
                                                  items: [
                                                    'เจ้าหน้าที่เทคโนโลยีสารสนเทศ',
                                                    'เจ้าหน้าที่จัดการงานทั่วไป',
                                                    'เจ้าหน้าที่ประสานงานวิชาการ',
                                                    'นักพัฒนานวัตกรรม',
                                                    'นักภูมิสารสนเทศ',
                                                    'วิศวกร',
                                                  ],
                                                  prefixIcon: Icons.work_outline,
                                                  onChanged: (val) => setState(() => jobPosition = val)
                                              )
                                          ),

                                          SizedBox(width: 10.0),

                                          Expanded(
                                              child: dropdown_field_c5(
                                                  name: "ระดับ : ",
                                                  value: jobLevel,
                                                  items: [
                                                    'ปฏิบัติการ',
                                                    'ชำนาญการ',
                                                    'ชำนาญการพิเศษ'
                                                  ],
                                                  prefixIcon: Icons.trending_up,
                                                  onChanged: (val) => setState(() => jobLevel = val)
                                              )
                                          ),

                                        ],
                                      ),

                                      SizedBox(width: 20.0),

                                      // สำนัก & ฝ่าย
                                      Row(
                                        children: [

                                          Expanded(
                                              child: dropdown_field_c5(
                                                  name: "สำนัก : ",
                                                  value: jobOffice,
                                                  items: officeToDepartments.keys.toList(),
                                                  prefixIcon: Icons.apartment,
                                                  onChanged: (val) => setState(() {
                                                    jobOffice = val;
                                                    jobDepartment = null;
                                                  })
                                              )
                                          ),

                                          SizedBox(width: 10.0),

                                          Expanded(
                                            child: dropdown_field_c5(
                                                name: "ฝ่าย : ",
                                                value: jobDepartment,
                                                items: jobOffice != null
                                                    ? officeToDepartments[jobOffice]!
                                                    : [],
                                                prefixIcon: Icons.account_tree_outlined,
                                                onChanged: (val) => setState(() => jobDepartment = val)
                                            ),
                                          )

                                        ],
                                      ),

                                    ]
                                ),
                              ),
                            ),

                          ],
                        ),
                      )

                  )

                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },

        ),



        /// Button
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 95,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF18181C),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: button_icon(
                    name: 'Cancel',
                    name_size: 16,
                    icon: Icons.close,
                    icon_size: 20,
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => alert_image_two_button(
                          text: "ยกเลิกการแก้ไขข้อมูล",
                          assets_image: "assets/images/question.png",
                          one_text_button: "ยกเลิก",
                          one_onPressed: () => Navigator.of(context).pop(),
                          two_text_button: "ตกลง",
                          two_onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                    //onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: button_icon(
                    name: 'Save',
                    name_size: 16,
                    icon: Icons.save_alt_outlined,
                    icon_size: 20,
                    onPressed: editUser,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}