import 'package:offline_gnss69_new/export.dart';

class Create_New_Project_Page extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const Create_New_Project_Page(),
  );

  const Create_New_Project_Page({super.key});

  @override
  State<Create_New_Project_Page> createState() => _Create_New_Project_PageState();
}

class _Create_New_Project_PageState extends State<Create_New_Project_Page> {

  final formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final name_project_id_Controller = TextEditingController();
  final project_name_Controller = TextEditingController();
  final project_details_Controller = TextEditingController();
  List<String> selectedProvinces = [];

  String? sensor;
  final gsd_num_Controller = TextEditingController();
  String? gsd_unit;

  String? survey_main;
  String? survey_sub;

  final project_start_date_Controller = TextEditingController();
  final project_end_date_Controller = TextEditingController();
  List<UserModel> selectedMembers = [];
  final project_note_Controller = TextEditingController();

  // กำหนดวันเริ่มต้น - สิ้นสุด
  DateTime start_date = DateTime.now();
  DateTime end_date = DateTime.now();


  /// วันเริ่มต้น
  void start_date_Selected(DateTime day, DateTime focusedDay) {
    setState(() {
      start_date = day;
      project_start_date_Controller.text = day.toString().split(" ")[0];
    });
  }


  /// วันสิ้นสุด
  void end_date_Selected(DateTime day, DateTime focusedDay) {
    setState(() {
      end_date = day;
      project_end_date_Controller.text = day.toString().split(" ")[0];
    });
  }


  /// ── ข้อมูลจังหวัด ──────────────────────
  final List<String> allProvinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร',
    'ขอนแก่น', 'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท',
    'ชัยภูมิ', 'ชุมพร', 'เชียงราย', 'เชียงใหม่', 'ตรัง',
    'ตราด', 'ตาก', 'นครนายก', 'นครปฐม', 'นครพนม',
    'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี', 'นราธิวาส',
    'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์',
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง',
    'พิจิตร', 'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่',
    'พะเยา', 'ภูเก็ต', 'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน',
    'ยะลา', 'ยโสธร', 'ร้อยเอ็ด', 'ระนอง', 'ระยอง',
    'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย',
    'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ',
    'สมุทรสงคราม', 'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี',
    'สุโขทัย', 'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย',
    'หนองบัวลำภู', 'อ่างทอง', 'อุดรธานี', 'อุตรดิตถ์', 'อุทัยธานี',
    'อุบลราชธานี', 'อำนาจเจริญ'
  ];


  /// ── pop up เลือกจังหวัด ──────────────────────
  Widget provinceSelector(BuildContext context, StateSetter parentSetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "จังหวัด",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (_) {

                // popup conten
                return AlertDialog(
                  backgroundColor: Colors.white,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                  title: const Center(
                    child: Text(
                      "เลือกจังหวัด",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansThai',
                      ),
                    ),
                  ),

                  // สไตล์ จังหวัด
                  content: StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 500,
                            height: 400,
                            child: ListView(
                              children: allProvinces.map((province) {
                                return CheckboxListTile(
                                  title: Text(province,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'NotoSansThai',
                                      color: Colors.black,
                                    ),
                                  ),
                                  value: selectedProvinces.contains(province),
                                  activeColor: Colors.black,
                                  checkColor: Colors.white,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedProvinces.add(province);
                                      } else {
                                        selectedProvinces.remove(province);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ปุ่ม ตกลง
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                parentSetState(() {});
                              },
                              child: const Text(
                                "ตกลง",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'NotoSansThai',
                                  color: Colors.white,
                                ),
                              ),
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.hovered) || states.contains(MaterialState.pressed)) {
                                      return Colors.grey;
                                    }
                                    return Color(0xFF18181C);
                                  },
                                ),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      bottomRight: Radius.circular(30),
                                      bottomLeft: Radius.circular(30),
                                    ),
                                  ),
                                ),
                                fixedSize: MaterialStateProperty.all(Size(350, 45)),
                              ),
                            ),
                          ),

                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Color.fromARGB(255, 34, 34, 34),
                width: 1.2,
              ),
            ),
            child: Text(
              selectedProvinces.isEmpty
                  ? "เลือกได้มากกว่า 1 จังหวัด"
                  : selectedProvinces.join(", "),
              style: TextStyle(
                fontSize: 16,
                fontWeight: selectedProvinces.isEmpty ? FontWeight.w400 : FontWeight.w500,
                fontFamily: 'NotoSansThai',
                color: selectedProvinces.isEmpty ? Colors.black87 : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }


  /// ── เลือกสมาชิก ──────────────────────
  Widget memberSelector(BuildContext context, StateSetter parentSetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "สมาชิกในโครงการ",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),

        const SizedBox(height: 10),

        // popup conten
        InkWell(
          onTap: () => _showMemberDialog(context, parentSetState),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: const Color.fromARGB(255, 34, 34, 34),
                width: 1.2,
              ),
            ),
            child: selectedMembers.isEmpty
            // ยังไม่เลือก
                ? const Text(
              "เลือกได้มากกว่า 1 คน",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'NotoSansThai',
                color: Colors.black87,
              ),
            )
            // แสดง Avatar ของที่เลือกแล้ว
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedMembers.map((member) {
                return Chip(
                  backgroundColor: const Color(0xFF18181C),
                  avatar: CircleAvatar(
                    backgroundImage: member.profileImg != null
                        ? NetworkImage(
                        "${Constants.backendUri}/uploads/profiles/${member.profileImg}")
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: member.profileImg == null
                        ? const Icon(Icons.person,
                        size: 16, color: Colors.white)
                        : null,
                  ),
                  label: Text(
                    "${member.firstName} ${member.lastName}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'NotoSansThai',
                      color: Colors.white,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close,
                      size: 16, color: Colors.white70),
                  onDeleted: () {
                    parentSetState(() {
                      selectedMembers.remove(member);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Member Dialog
  void _showMemberDialog(
      BuildContext context, StateSetter parentSetState) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;
    final token = authState.userModel.token;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) {
        return _MemberPickerDialog(
          token: token,
          alreadySelected: List.from(selectedMembers),
          onConfirm: (List<UserModel> chosen) {
            parentSetState(() {
              selectedMembers = chosen;
            });
          },
        );
      },
    );
  }


  @override
  void dispose() {
    project_name_Controller.dispose();
    super.dispose();
  }


  void check_Create_New_Project() {

    // เลื่อนไปช่องที่ validation ไม่ถูกต้อง
    if (!formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
      return;
    }

    // validation ผ่าน >> ดึง token แล้วส่งข้อมูล
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;
    final token = authState.userModel.token;

    // ถ้าว่างให้คืน null
    String? _nullIfEmpty(String text) {
      final trimmed = text.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    // ตัวแปรช่วย — วันปัจจุบันในรูปแบบ yyyy-MM-dd
    final today = DateTime.now().toString().split(' ')[0];

    context.read<TaskCubit>().createProject(
      token:            token,
      nameProjectId:    _nullIfEmpty(name_project_id_Controller.text),
      projectName:      project_name_Controller.text.trim(),
      projectDetails:   _nullIfEmpty(project_details_Controller.text),
      province:         selectedProvinces.isEmpty ? null : selectedProvinces.join(', '),
      sensor:           sensor,
      gsdNum:           int.tryParse(gsd_num_Controller.text.trim()),
      gsdUnit:          gsd_unit,
      surveyMain:       survey_main,
      surveySub:        survey_sub,
      // ถ้าไม่ได้เลือกวัน >> ใช้วันปัจจุบัน
      projectStartDate: project_start_date_Controller.text.isEmpty
          ? today
          : project_start_date_Controller.text,
      projectEndDate:   project_end_date_Controller.text.isEmpty
          ? today
          : project_end_date_Controller.text,
      projectNote:      _nullIfEmpty(project_note_Controller.text),
      memberIds:        selectedMembers.map((m) => m.id).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskCubit, TaskState>(
        listener: (context, state) {

          /// สร้างโครงการสำเร็จ
          if (state is CreateProjectSuccess) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
              alert_image_one_button(
                  text: "สร้างโครงการสำเร็จ",
                  assets_image: "assets/images/checkmark.png",
                  onPressed : () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  text_button: "ตกลง"
              ),
            );
          } else if (state is ProjectError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },

      child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF505050),
                  Color(0xFF18181C),
                  Color(0xFF505050),
                  Color(0xFF505050),
                  Color(0xFF505050),
                  Color(0xFF505050),
                  Color(0xFF505050),
                ],
              ),
            ),
      
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  const SizedBox(height: 20),
      
                  w_text_big(
                      name: 'Create New Project!',
                      font_Size: 36,
                      color: Colors.white,
                      shadow_color: Colors.black
                  ),

                  const SizedBox(height: 40),
      
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
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  children: [
      
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: text_field_column_c5(
                                            name: "ID โครงการ",
                                            controller: name_project_id_Controller,
                                            hintText: "Project ID",
                                            validator: (value) {
      
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 10.0),
      
                                        Expanded(
                                          child: text_field_column_c5(
                                            name: "ชื่อโครงการ",
                                            controller: project_name_Controller,
                                            hintText: "Name",
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'กรุณาระบุชื่อโครงการ';
                                              }
                                              return null;
                                            },
                                          ),
                                        )
                                      ],
                                    ),

                                    const SizedBox(height: 10.0),
      
                                    text_field_column_c5(
                                      name: "รายละเอียดโครงการ",
                                      controller: project_details_Controller,
                                      hintText: "รายละเอียดโครงการ",
                                      validator: (value) {
      
                                      },
                                    ),

                                    const SizedBox(height: 10.0),
      
                                    provinceSelector(context, setState),

                                    const SizedBox(height: 25.0),
      
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: dropdown_field_c5(
                                            name: "Sensor",
                                            hintText: "Sensor",
                                            value: sensor,
                                            items: ['Satellites', 'UAVs', 'MMS'],
                                            onChanged: (val) {
                                              setState(() {
                                                sensor = val;
                                              });
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 10.0),

                                        Expanded(
                                          child: text_field_column_c5(
                                            name: "Ground Sample Distance (GSD)",
                                            controller: gsd_num_Controller,
                                            hintText: "กรอกค่า GSD",
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            validator: (value) {
                                              if (value != null && value.isNotEmpty) {
                                                if (int.tryParse(value) == null) {
                                                  return 'กรุณาระบุเป็นจำนวนเต็มเท่านั้น';
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 10.0),
      
                                        SizedBox(
                                          width: 120,
                                          child: dropdown_field_c5(
                                            name: "",
                                            hintText: "หน่วย",
                                            value: gsd_unit,
                                            items: ['cm.', 'm.'],
                                            onChanged: (val) {
                                              setState(() {
                                                gsd_unit = val;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10.0),
      
                                    Row(
                                      children: [
                                        Expanded(
                                          child: dropdown_field_c5(
                                            name: "วิธีการรังวัดหลัก",
                                            value: survey_main,
                                            items: ['Static', 'Kinematic'],
                                            onChanged: (val) {
                                              setState(() {
                                                survey_main = val;
                                                survey_sub = null;
                                              });
                                            },
                                          ),
                                        ),

                                        const SizedBox(width: 10.0),
      
                                        Expanded(
                                          child: dropdown_field_c5(
                                            name: "วิธีการรังวัดย่อย",
                                            value: survey_sub,
                                            items: survey_main == 'Static'
                                                ? ['Static', 'Fast Static']
                                                : survey_main == 'Kinematic'
                                                ? ['RTK', 'NRTK']
                                                : [],
                                            onChanged: (val) {
                                              setState(() {
                                                survey_sub = val;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10.0),
      
                                    Row(
                                      children: [
                                        Expanded(
                                            child: text_field_date_column(
                                              name: "วันเริ่มต้นการสำรวจ",
                                              hint_Text: start_date.toString().split(" ")[0],
                                              controller: project_start_date_Controller,
                                            )
                                        ),

                                        const SizedBox(width: 10.0),
      
                                        Expanded(
                                          child: text_field_date_column(
                                            name: "วันสิ้นสุดการสำรวจ",
                                            hint_Text: end_date.toString().split(" ")[0],
                                            controller: project_end_date_Controller,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10.0),
      
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Calendar(
                                            Date_name: start_date,
                                            Date_Selected: start_date_Selected,
                                          ),
                                        ),

                                        const SizedBox(width: 20.0),
      
                                        Expanded(
                                          child: Calendar(
                                            Date_name: end_date,
                                            Date_Selected: end_date_Selected,
                                          ),
                                        )
                                      ],
                                    ),

                                    const SizedBox(height: 25.0),
      
                                    /// Member Selector
                                    memberSelector(context, setState),

                                    const SizedBox(height: 20.0),
      
                                    text_field_column_c5(
                                      name: "หมายเหตุเพิ่มเติม",
                                      controller: project_note_Controller,
                                      hintText: "-",
                                      validator: (value) {
      
                                      },
                                    ),

                                    const SizedBox(height: 30.0),

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
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (_) => alert_image_two_button(
                                                  text: "ยกเลิกการสร้างโครงการ",
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
                                          ),
                                        ),

                                        const SizedBox(width: 10.0),

                                        BlocBuilder<TaskCubit, TaskState>(
                                          builder: (context, state) {
                                            final isLoading = state is ProjectLoading;
                                            return SizedBox(
                                              width: MediaQuery.of(context).size.width / 2.5,
                                              child: isLoading
                                                  ? const Center(child: CircularProgressIndicator())
                                                  : button_icon(
                                                name: 'Create New Project',
                                                name_size: 16,
                                                icon: Icons.add,
                                                icon_size: 20,
                                                onPressed: check_Create_New_Project,
                                              ),
                                            );
                                          },
                                        ),

                                      ],
                                    )
      
      
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                  ),
                ],
              ),
            ),
          )
      ),
    );
  }
}


/// ── popup เลือกสมาชิก ────────────────────────────────
class _MemberPickerDialog extends StatefulWidget {
  final String token;
  final List<UserModel> alreadySelected;
  final void Function(List<UserModel>) onConfirm;

  const _MemberPickerDialog({
    required this.token,
    required this.alreadySelected,
    required this.onConfirm,
  });

  @override
  State<_MemberPickerDialog> createState() => _MemberPickerDialogState();
}

class _MemberPickerDialogState extends State<_MemberPickerDialog> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];
  late List<UserModel> _selected;
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.alreadySelected);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final repo = AuthRemoteRepository();
      final users = await repo.getAllUsers(token: widget.token);
      setState(() {
        _allUsers = users;
        _filtered = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ค้นหา
  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _allUsers;
      } else {
        _filtered = _allUsers.where((u) {
          final full = "${u.firstName} ${u.lastName}".toLowerCase();
          return full.contains(query.toLowerCase()) ||
              u.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  bool _isSelected(UserModel user) =>
      _selected.any((u) => u.id == user.id);

  void _toggleUser(UserModel user) {
    setState(() {
      if (_isSelected(user)) {
        _selected.removeWhere((u) => u.id == user.id);
      } else {
        _selected.add(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /// แสดงรายละเอียดใน popup เลือกสมาชิก
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      title: const Center(
        child: Text(
          "เลือกสมาชิก",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ค้นหา
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: const TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF18181C),
                ),
                decoration: InputDecoration(
                  hintText: "ค้นหาชื่อ หรือ Email",
                  hintStyle: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /// list Users >>> เรียง a - z ตาม email
            SizedBox(
              height: 450,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Text(
                  "เกิดข้อผิดพลาด: $_error",
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'NotoSansThai',
                  ),
                ),
              )
                  : _filtered.isEmpty
                  ? const Center(
                child: Text(
                  "ไม่พบผู้ใช้งาน",
                  style: TextStyle(
                    fontFamily: 'NotoSansThai',
                    color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final user = _filtered[index];
                  final selected = _isSelected(user);
                  return _UserTile(
                    user: user,
                    isSelected: selected,
                    onTap: () => _toggleUser(user),
                  );
                },
              ),
            ),

            /// แสดงจำนวนที่เลือก
            if (_selected.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  "เลือกแล้ว ${_selected.length} คน",
                  style: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            /// ปุ่มตกลง
            SizedBox(
              width: double.infinity,
              height: 45,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(_selected);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) {
                      if (states.contains(MaterialState.hovered) ||
                          states.contains(MaterialState.pressed)) {
                        return Colors.grey;
                      }
                      return const Color(0xFF18181C);
                    },
                  ),
                  shape: MaterialStateProperty.all(
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                child: const Text(
                  "ตกลง",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansThai',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// ── User Tile ที่แสดงใน popup เลือกสมาชิก ────────────────────────────────
class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF18181C).withOpacity(0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF18181C)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            /// รูปโปรไฟล์
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: user.profileImg != null
                  ? NetworkImage(
                  "${Constants.backendUri}/uploads/profiles/${user.profileImg}")
                  : null,
              child: user.profileImg == null
                  ? const Icon(Icons.person, size: 28, color: Colors.grey)
                  : null,
            ),

            const SizedBox(width: 14),

            /// ชื่อ + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user.titleName} ${user.firstName} ${user.lastName}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'NotoSansThai',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'NotoSansThai',
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            /// Checkbox
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                  key: ValueKey(true),
                  color: Color(0xFF18181C),
                  size: 26)
                  : Icon(Icons.circle_outlined,
                  key: const ValueKey(false),
                  color: Colors.grey.shade400,
                  size: 26),
            ),
          ],
        ),
      ),
    );
  }
}


/// ── แสดงวันที่ ────────────────────────────────
class text_field_date_column extends StatelessWidget {
  final String name;
  final String hint_Text;
  final TextEditingController? controller;

  const text_field_date_column({
    required this.name,
    required this.hint_Text,
    required this.controller,

    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),

        const SizedBox(height: 10),

        TextFormField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),

          decoration: InputDecoration(
            hintText: hint_Text,
            helperText: ' ',
            errorStyle: const TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.red,
              height: 1.2,
            ),
            /// เมื่อไม่ถูกเลือก
            enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 34, 34, 34),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(5)
            ),
            /// เมื่อถูกเลือก
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.6),
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(5)
            ),
          ),
        ),
      ],
    );
  }
}

