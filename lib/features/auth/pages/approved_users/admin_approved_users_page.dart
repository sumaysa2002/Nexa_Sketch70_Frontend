import 'package:http/http.dart' as http;
import 'package:offline_gnss69_new/export.dart';

class Admin_Approved_Users_Page extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const Admin_Approved_Users_Page(),
  );

  const Admin_Approved_Users_Page({super.key});

  @override
  State<Admin_Approved_Users_Page> createState() => _Admin_Approved_Users_PageState();
}

class _Admin_Approved_Users_PageState extends State<Admin_Approved_Users_Page> {

  List<UserModel> _members = [];
  bool _isLoading          = true;
  String? _error;
  int? _expandedId;

  // เช็คอินเทอร์เน็ต
  bool _isOnline = true;

  // ค้นหา
  String _searchQuery = '';
  final _searchController = TextEditingController();


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();

    // เช็คสถานะ internet
    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        setState(() {
          _isOnline = result.contains(ConnectivityResult.wifi) ||
              result.contains(ConnectivityResult.mobile);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers());
  }


  /// ── โหลดสมาชิกที่ผ่านการอนุมัติ ──────────────────────
  Future<void> _loadMembers() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthLoggedIn) return;

      final repo  = AuthRemoteRepository();
      final users = await repo.getAllUsers(token: authState.userModel.token);

      if (mounted) setState(() { _members = users; _isLoading = false; });
    } catch (e) {
      final local = await AuthLocalRepository().getApprovedUsers();
      if (mounted) setState(() { _members = local; _isLoading = false; });
    }
  }


  /// ── dialog อนุมัติสมาชิก ──────────────────────
  Future<void> _openAddMemberDialog() async {
    if (!_isOnline) {
      _showOfflineWarning();
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddMemberDialog(
        token:   authState.userModel.token,
        onAdded: (user) {
          setState(() => _members.add(user));
        },
      ),
    );
  }


  /// ── ยกเลิกการอนุมัติสมาชิก ──────────────────────
  Future<void> _removeMember(UserModel member) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;

    try {
      final res = await http.put(
        Uri.parse('${Constants.backendUri}/auth/revoke_approval_user/${member.id}'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authState.userModel.token,
        },
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _members.removeWhere((u) => u.id == member.id);
            _expandedId = null;
          });

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text:         'ยกเลิกการอนุมัติสมาชิกสำเร็จ',
              assets_image: 'assets/images/checkmark.png',
              text_button:  'ตกลง',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          );
        }
      } else {
        _showError('ไม่สามารถยกเลิกการอนุมัติสมาชิกได้');
      }
    } catch (e) {
      _showOfflineWarning();
    }
  }


  /// ── Popup ยืนยันยกเลิกการอนุมัติสมาชิก ───────────────────────────────────────────────────────
  void _showRemoveConfirm(UserModel member) {
    if (!_isOnline) {
      _showOfflineWarning();
      return;
    }

    showDialog(
      context: context,
      builder: (_) =>

          alert_image_two_button(
            text: "ยกเลิกการอนุมัติสมาชิก\n${member.titleName} ${member.firstName} ${member.lastName}",
            one_fontWeight: FontWeight.w700,
            assets_image: "assets/images/icon_bin.png",
            one_text_button: "ยกเลิก",
            one_onPressed: () => Navigator.of(context).pop(),
            two_text_button: "ยืนยัน",
            two_onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
          ),

    );
  }


  /// ── แสดง Error ──────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.grey.shade900),
    );
  }


  /// ── แจ้งเตือนตอนอยู่โหมด offline ────────────────────────────────────────────
  void _showOfflineWarning() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => alert_image_one_button(
        text: "ไม่สามารถแก้ไขการอนุมัติสมาชิกได้\nเนื่องจากอยู่ในโหมด offline",
        assets_image: "assets/images/no_wifi.png",
        onPressed: () {
          Navigator.of(context).pop();
          //Navigator.of(context).pop();
        },
        text_button: "ตกลง",
      ),
    );
  }


  /// ── ลำดับการแสดง members ────────────────────────────────────────────
  List<UserModel> get _filtered {
    List<UserModel> list = _members;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) =>
      '${u.firstName} ${u.lastName}'.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q)
      ).toList();
    }

    // admin ขึ้นก่อน >> ตามด้วย user (a-z ของ email)
    final admins = list.where((u) => u.status == 'admin').toList();
    final others = list.where((u) => u.status != 'admin').toList();
    return [...admins, ...others];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [

            /// Header
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F0F10), Color(0xFF2A2A2D)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.elliptical(2000, 400),
                  bottomRight: Radius.elliptical(2000, 400),
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      w_text_big(
                          name: 'Approved Users!',
                          font_Size: 36,
                          color: Colors.white,
                          shadow_color: Colors.black
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'สมาชิกผ่านการอนุมัติ ${_members.length} คน',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'NotoSansThai',
                          color: Colors.white60,
                        ),
                      )

                    ],
                  ),
                ),
              ),
            ),

            /// Body
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 16, 30, 15),
              child: Row(
                children: [

                  /// ค้นหา
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontFamily: 'NotoSansThai', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อ หรือ Email',
                        hintStyle: const TextStyle(
                          fontFamily: 'NotoSansThai', color: Colors.grey,
                        ),

                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// ปุ่มเพิ่มการอนุมัติสมาชิก
                  GestureDetector(
                    onTap: _openAddMemberDialog,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),

                  const SizedBox(width: 8),

                  /// ปุ่ม refresh
                  GestureDetector(
                    onTap: _loadMembers,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF18181C), size: 20),
                    ),
                  ),
                ],
              ),
            ),

            /// รายชื่อสมาชิก
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF18181C)),
              )
                  : _error != null
                  ? Center(child: Text(_error!,
                  style: const TextStyle(
                    color: Colors.red, fontFamily: 'NotoSansThai',
                  )))
                  : _filtered.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_off_rounded,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text(
                      'ไม่มีสมาชิกในกลุ่ม',
                      style: TextStyle(
                        fontSize: 16, color: Colors.grey,
                        fontFamily: 'NotoSansThai',
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 20),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final member = _filtered[index];
                  final isExpanded = _expandedId == member.id;
                  return _MemberCard(
                    member:     member,
                    isExpanded: isExpanded,
                    isFirst:    index == 0,
                    onTap: () => setState(() =>
                    _expandedId = isExpanded ? null : member.id,
                    ),
                    onRemove: () => _showRemoveConfirm(member),
                  );
                },
              ),
            ),

            SizedBox(height: 10,)

          ],
        ),
      ),
    );
  }
}


/// ── Card Member ────────────────────────────────
class _MemberCard extends StatelessWidget {
  final UserModel member;
  final bool isExpanded;
  final bool isFirst;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.isExpanded,
    required this.isFirst,
    required this.onTap,
    required this.onRemove,
  });

  bool get _isAdmin => member.status == 'admin';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(
          top: isFirst ? 0 : 6,
          bottom: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFF18181C)
                : Colors.grey.shade200,
            width: isExpanded ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 2),
          child: isExpanded
              ? members_tap_card(context)
              : members_card(),
        ),
      ),
    );
  }

  /// card ปกติ (ยังไม่กดการ์ด)
  Widget members_card() {
    return Padding(
      key: const ValueKey('collapsed'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [

          _avatar(radius: 28),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  '${member.titleName} ${member.firstName} ${member.lastName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansThai',
                    color: Color(0xFF18181C),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  member.email,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'NotoSansThai',
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                if (member.jobPosition != null &&
                    member.jobPosition!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.jobPosition!,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'NotoSansThai',
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

              ],
            ),
          ),

          Row(
            children: [

              // ถ้าเป็น admin ให้แสดงว่าเป็น admin
              if (_isAdmin) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 10, fontFamily: 'NotoSansThai',
                      color: Colors.white, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              SizedBox(width: 5),

              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
            ],
          )

        ],
      ),
    );
  }

  /// card ที่กดแล้ว
  Widget members_tap_card(BuildContext context) {
    return Container(
      key: const ValueKey('expanded'),
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [

          _avatar(radius: 40),

          const SizedBox(height: 12),

          Text(
            '${member.titleName} ${member.firstName} ${member.lastName}',
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansThai', color: Color(0xFF18181C),
            ),
            textAlign: TextAlign.center,
          ),

          _detailRow(Icons.email_outlined,        'Email',    member.email),
          _detailRow(Icons.work_outline,           'ตำแหน่ง', member.jobPosition),
          _detailRow(Icons.trending_up,            'ระดับ',   member.jobLevel),
          _detailRow(Icons.apartment,              'สำนัก',   member.jobOffice),
          _detailRow(Icons.account_tree_outlined,  'ฝ่าย',    member.jobDepartment),

          const SizedBox(height: 14),

          // ปุ่มยกเลิกการอนุมัติสมาชิก
          if (!_isAdmin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onRemove,
                icon: const Icon(Icons.person_remove_rounded, size: 18),
                label: const Text(
                  'ยกเลิกการอนุมัติสมาชิก',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai', fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            )

          // ถ้าเป็น admin >> แสดงข้อความแทน
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF18181C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Admin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, fontFamily: 'NotoSansThai',
                  color: Colors.white, fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 6),

          const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF18181C)),
        ],
      ),
    );
  }

  /// รูปโปรไฟล์ User
  Widget _avatar({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: member.profileImg != null
          ? NetworkImage(
          '${Constants.backendUri}/uploads/profiles/${member.profileImg}')
          : null,
      child: member.profileImg == null
          ? Icon(Icons.person, size: radius * 1.1, color: Colors.grey)
          : null,
    );
  }

  /// Row ใน card
  Widget _detailRow(IconData icon, String label, String? value) {
    final display = (value == null || value.isEmpty) ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(
            icon,
            size: 14,
            color: Color(0xFF515155),
          ),

          const SizedBox(width: 6),

          SizedBox(
            width: 65,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansThai',
                color: Color(0xFF515155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const Text(
            ':',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'NotoSansThai',
            ),
          ),

          const SizedBox(width: 6),

          // value
          Expanded(
            child: Text(
              display,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'NotoSansThai',
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),

        ],
      ),
    );
  }
}


/// ── Dialog อนุมัติสมาชิก ────────────────────────────────
class _AddMemberDialog extends StatefulWidget {
  final String token;
  final void Function(UserModel user) onAdded;

  const _AddMemberDialog({required this.token, required this.onAdded});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {

  List<UserModel> _allUsers  = [];
  List<UserModel> _filtered  = [];
  bool _isLoading            = true;
  String? _error;
  int? _addingId;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // มีค่า admin = null (สามารถอนุมัติได้)
  List<UserModel> _sorted(List<UserModel> list) {
    final free    = list.where((u) => u.admin == null).toList();
    final inGroup = list.where((u) => u.admin != null).toList();
    return [...free, ...inGroup];
  }

  // โหลด user ทั้งหมด (ยกเว้น admin)
  Future<void> _fetchAllUsers() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await http.get(
        Uri.parse('${Constants.backendUri}/auth/search_users?q='),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': widget.token,
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final users = data.map((item) => UserModel(
          id:            item['id']            ?? 0,
          titleName:     item['title_name']    ?? '',
          firstName:     item['first_name']    ?? '',
          lastName:      item['last_name']     ?? '',
          phone:         '',
          email:         item['email']         ?? '',
          profileImg:    item['profile_img'],
          jobPosition:   item['job_position'],
          jobLevel:      item['job_level'],
          jobOffice:     item['job_office'],
          jobDepartment: item['job_department'],
          admin:         item['admin'],
          status:        item['status'],
          signature:     null,
          token:         '',
        ))
        // เฉพาะ user ที่ status เป็น null
            .where((u) => u.status == null)
            .toList();

        setState(() {
          _allUsers  = users;
          _filtered  = _sorted(users);
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'โหลดข้อมูลไม่สำเร็จ'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ค้นหา
  void _onSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filtered = _sorted(_allUsers);
      } else {
        final q = query.toLowerCase();
        final matched = _allUsers.where((u) =>
        '${u.firstName} ${u.lastName}'.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q)
        ).toList();
        _filtered = _sorted(matched);
      }
    });
  }

  // อนุมัติสมาชิก
  Future<void> _addMember(UserModel user) async {
    setState(() => _addingId = user.id);

    try {
      final res = await http.put(
        Uri.parse('${Constants.backendUri}/auth/approved_user/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': widget.token,
        },
      );

      if (res.statusCode == 200) {
        // อัปเดต status
        setState(() {
          _addingId = null;
          final idx = _allUsers.indexWhere((u) => u.id == user.id);
          if (idx != -1) {
            _allUsers[idx] = UserModel(
              id:            user.id,
              titleName:     user.titleName,
              firstName:     user.firstName,
              lastName:      user.lastName,
              phone:         user.phone,
              email:         user.email,
              profileImg:    user.profileImg,
              jobPosition:   user.jobPosition,
              jobLevel:      user.jobLevel,
              jobOffice:     user.jobOffice,
              jobDepartment: user.jobDepartment,
              admin:         'added', // mark ว่าอนุมัติแล้ว
              status:        'user',
              signature:     user.signature,
              token:         '',
            );
            _onSearch(_searchController.text);
          }
        });

        widget.onAdded(user);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => alert_image_one_button(
              text:         'อนุมัติสมาชิกสำเร็จ',
              assets_image: 'assets/images/checkmark.png',
              text_button:  'ตกลง',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          );
        }
      } else {
        final body = jsonDecode(res.body);
        setState(() => _addingId = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['error'] ?? 'อนุมัติสมาชิกไม่สำเร็จ'),
              backgroundColor: Colors.grey.shade900,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _addingId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.grey.shade900),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      title: const Center(
        child: Text(
          'อนุมัติสมาชิก',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansThai',
          ),
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ค้นหา
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: false,
                style: const TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF18181C),
                ),
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อ หรือ Email',
                  hintStyle: const TextStyle(
                    fontFamily: 'NotoSansThai',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // รายการ User >> สถานะ null ขึ้นก่อน
            SizedBox(
              height: 450,
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF18181C)
                ),
              )
                  : _error != null
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Image.asset("assets/images/no_wifi.png", height: 120),

                    SizedBox(height: 10),

                    Text(
                      "ไม่สามารถอนุมัติสมาชิกได้\nเนื่องจากอยู่ในโหมด offline",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'NotoSansThai',
                      ),
                    ),

                  ],
                ),
              )
                  : _filtered.isEmpty
                  ? const Center(
                child: Text(
                  'ไม่พบการค้นหา',
                  style: TextStyle(
                    fontFamily: 'NotoSansThai', color: Colors.grey,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final user = _filtered[index];
                  final bool inThisGroup  = user.admin == 'added';
                  final bool inOtherGroup = user.admin != null && !inThisGroup;
                  final bool isAdding     = _addingId == user.id;

                  return _SearchResultTile(
                    user:         user,
                    inThisGroup:  inThisGroup,
                    inOtherGroup: inOtherGroup,
                    isAdding:     isAdding,
                    onAdd: inThisGroup ? null : () => _addMember(user),
                  );
                },
              ),
            ),

            SizedBox(
              height: 10,
              child: Container(
                color: Colors.white,
              ),
            ),

            // ปุ่มปิด
            SizedBox(
              width: double.infinity,
              height: 45,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    const Color(0xFF18181C),
                  ),
                  shape: MaterialStateProperty.all(
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft:  Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
                child: const Text(
                  'ปิด',
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


/// ── ผลการค้นหาสมาชิก ────────────────────────────────
class _SearchResultTile extends StatelessWidget {
  final UserModel user;
  final bool inThisGroup;
  final bool inOtherGroup;
  final bool isAdding;
  final VoidCallback? onAdd;

  const _SearchResultTile({
    required this.user,
    required this.inThisGroup,
    required this.inOtherGroup,
    required this.isAdding,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {

    // card สีจางลง (ถ้าอนุมัติแล้ว)
    final bool dimmed = inThisGroup;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dimmed
            ? Colors.grey.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dimmed
              ? Colors.grey.shade300
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [

          // รูปโปรไฟล์
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: user.profileImg != null
                ? NetworkImage(
                '${Constants.backendUri}/uploads/profiles/${user.profileImg}')
                : null,
            child: user.profileImg == null
                ? const Icon(Icons.person, size: 28, color: Colors.grey)
                : null,
          ),

          const SizedBox(width: 14),

          // ชื่อ + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.titleName} ${user.firstName} ${user.lastName}',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansThai',
                    color: dimmed
                        ? Colors.grey.shade500
                        : const Color(0xFF18181C),
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

                const SizedBox(height: 3),

                // อยู่กลุ่มนี้แล้ว
                if (inThisGroup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'อนุมัติแล้ว',
                      style: TextStyle(
                        fontSize: 10, fontFamily: 'NotoSansThai',
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )

                // อยู่กลุ่มอื่น — เพิ่มได้ แต่ขึ้นเตือน
                else if (inOtherGroup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'อยู่ในกลุ่มอื่นแล้ว',
                      style: TextStyle(
                        fontSize: 10, fontFamily: 'NotoSansThai',
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ปุ่มเพิ่ม / loading / disabled
          if (isAdding)
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF18181C),
              ),
            )
          else if (inThisGroup)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'อนุมัติแล้ว',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSansThai', color: Colors.grey.shade500,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'อนุมัติ',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansThai', color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}