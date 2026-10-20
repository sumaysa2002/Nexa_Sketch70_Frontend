import 'package:offline_gnss69_new/export.dart';

class User_Approved_Users_Page extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const User_Approved_Users_Page(),
  );

  const User_Approved_Users_Page({super.key});

  @override
  State<User_Approved_Users_Page> createState() => _User_Approved_Users_PageState();
}

class _User_Approved_Users_PageState extends State<User_Approved_Users_Page> {

  List<UserModel> _members   = [];
  bool _isLoading            = true;
  String? _error;
  int? _expandedId;

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


  /// ── ลำดับการแสดง members ─────────────────────────
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
                        shadow_color: Colors.black,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'สมาชิกผ่านการอนุมัติ ${_members.length} คน',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'NotoSansThai',
                          color: Colors.white60,
                        ),
                      ),

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
                      child: const Icon(Icons.refresh_rounded,
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
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

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

  const _MemberCard({
    required this.member,
    required this.isExpanded,
    required this.isFirst,
    required this.onTap,
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
          child: isExpanded ? members_tap_card() : members_card(),
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
                    fontSize: 15, fontWeight: FontWeight.w700,
                    fontFamily: 'NotoSansThai', color: Color(0xFF18181C),
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
                  const SizedBox(height: 3),
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
                const SizedBox(width: 6),
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
  Widget members_tap_card() {
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

          _detailRow(Icons.email_outlined,       'Email',    member.email),
          _detailRow(Icons.work_outline,          'ตำแหน่ง', member.jobPosition),
          _detailRow(Icons.trending_up,           'ระดับ',   member.jobLevel),
          _detailRow(Icons.apartment,             'สำนัก',   member.jobOffice),
          _detailRow(Icons.account_tree_outlined, 'ฝ่าย',    member.jobDepartment),

          const SizedBox(height: 14),

          // ถ้าเป็น admin >> แสดงข้อความแทน
          if (_isAdmin) ...[
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
          ],

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
          ? NetworkImage(SecureImage.profileUrl(member.profileImg), headers: SecureImage.authHeaders)
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