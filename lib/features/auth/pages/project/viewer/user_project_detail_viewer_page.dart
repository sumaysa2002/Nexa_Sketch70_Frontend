import 'package:offline_gnss69_new/export.dart';

class User_Project_Detail_Viewer_Page extends StatefulWidget {
  final ProjectModel project;

  static MaterialPageRoute route(ProjectModel project) => MaterialPageRoute(
    builder: (context) => User_Project_Detail_Viewer_Page(project: project),
  );

  const User_Project_Detail_Viewer_Page({super.key, required this.project});

  @override
  State<User_Project_Detail_Viewer_Page> createState() =>
      _User_Project_Detail_Viewer_PageState();
}

class _User_Project_Detail_Viewer_PageState extends State<User_Project_Detail_Viewer_Page> {
  late ProjectModel _project;

  // ค้นหา
  final _searchController = TextEditingController();

  // เช็ค internet
  bool _isOnline = true;

  // list member
  String _activeTab = 'list';

  // สมาชิกที่ expand อยู่ >> ถ้า null = ไม่มีใคร expand
  int? _expandedMemberId;

  // cache สมาชิก
  List<UserModel> _members = [];
  bool _membersLoaded = false;


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();
    _project = widget.project;

    // เช็คสถานะ internet
    Connectivity().checkConnectivity().then((result) {
      if (mounted) {
        setState(() {
          _isOnline = result.contains(ConnectivityResult.wifi) ||
              result.contains(ConnectivityResult.mobile);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPoints());
  }


  /// ── โหลด Points ───────────────────────────────────────────
  void _loadPoints() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;
    context.read<PointTaskCubit>().getPoints(
      token: authState.userModel.token,
      projectId: _project.id,
    );
  }


  /// ── เรียงสมาชิกตาม email ──────────────────
  List<UserModel> _sortByEmail(List<UserModel> users) {
    return users
      ..sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
  }

  /// ── โหลดสมาชิกที่ผ่านการอนุมัติ ──────────────────
  Future<void> _loadMembers() async {
    if (_membersLoaded) return;
    if (_project.memberIds.isEmpty) {
      setState(() => _membersLoaded = true);
      return;
    }

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthLoggedIn) return;

      final repo = AuthRemoteRepository();
      final allUsers = await repo.getUsersByIds(
        token: authState.userModel.token,
        ids: _project.memberIds,
      );
      final members = _sortByEmail(
        allUsers.where((u) => _project.memberIds.contains(u.id)).toList(),
      );

      if (mounted) setState(() {
        _members = members;
        _membersLoaded = true;
      });
    } catch (_) {
      final authLocal = AuthLocalRepository();
      final localUsers = await authLocal.getApprovedUsers();
      final members = _sortByEmail(
        localUsers.where((u) => _project.memberIds.contains(u.id)).toList(),
      );

      if (mounted) setState(() {
        _members = members;
        _membersLoaded = true;
      });
    }
  }


  /// ── Export Project ──────────────────
  void _onExportTap() {
    final pointState = context.read<PointTaskCubit>().state;
    final points = pointState is GetPointsSuccess
        ? pointState.points
        : <PointModel>[];

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthLoggedIn) return;

    Export_Project.showExportDialog(
      context,
      project: _project,
      points: points,
      token: authState.userModel.token,
    );
  }


  @override
  Widget build(BuildContext context) {
    final pj = _project;

    final List<String> provinces = pj.province != null
        ? pj.province!.split(', ')
        : [];

    final String startDate = pj.projectStartDate ?? '-';
    final String endDate   = pj.projectEndDate   ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          /// Header
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Color(0xFF121212),
                      Color(0xFF303030)
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.elliptical(500, 100),
                    bottomRight: Radius.elliptical(500, 100),
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18
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

          /// Container ข้อมูลโครงการ
          Transform.translate(
            offset: const Offset(0, -110),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    w_text_thai_notosansthai(
                        name: pj.projectName,
                        font_Size: 18,
                        fontWeight: FontWeight.w700
                    ),

                    const SizedBox(height: 20),

                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      color: Colors.grey,
                      label: 'พื้นที่โครงการ',
                      value: provinces.isEmpty ? '-' : provinces.join(', '),
                      maxLines: 5,
                    ),

                    const SizedBox(height: 15),

                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      color: Colors.grey,
                      label: 'ช่วงการสำรวจ',
                      value: '$startDate  -  $endDate',
                    ),

                  ],
                ),
              ),
            ),
          ),

          /// ค้นหา + แถบปุ่ม
          Transform.translate(
            offset: const Offset(0, -90),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Row(
                children: [

                  // ค้นหา
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          //_searchQuery = value.toLowerCase();
                        });
                      },
                      style: const TextStyle(
                        fontFamily: 'NotoSansThai',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF18181C),
                      ),
                      decoration: InputDecoration(
                        hintText: "ค้นหาหมุดรังวัด",
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
                          borderRadius: BorderRadius.circular(50),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // list point
                  circle_icon_button(
                    icon: Icons.format_list_bulleted,
                    color: _activeTab == 'list'
                        ? const Color(0xFF303030)
                        : const Color(0xFFBDBDBD),
                    onTap: () => setState(() {
                      _activeTab = 'list';
                      _expandedMemberId = null;
                    }),
                  ),

                  const SizedBox(width: 8),

                  // members project
                  circle_icon_button(
                    icon: Icons.group_rounded,
                    color: _activeTab == 'member'
                        ? const Color(0xFF303030)
                        : const Color(0xFFBDBDBD),
                    onTap: () {
                      setState(() {
                        _activeTab = 'member';
                        _expandedMemberId = null;
                      });
                      _loadMembers();
                    },
                  ),

                  const SizedBox(width: 8),

                  // download project
                  circle_icon_button(
                    icon: Icons.save_alt,
                    onTap: _onExportTap,
                  ),

                ],
              ),
            ),
          ),

          SizedBox(height: 10),

          /// body
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _activeTab == 'list'
                    ? _PointListPanel(
                  projectId: _project.id,
                  searchQuery: _searchController.text.toLowerCase(),
                )
                    : _activeTab == 'member'
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: w_text_thai_notosansthai(
                            name: "สมาชิกในโครงการ",
                            font_Size: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _MemberPanel(
                          members: _members,
                          isLoaded: _membersLoaded,
                          isOnline: _isOnline,
                          expandedId: _expandedMemberId,
                          onExpand: (id) =>
                              setState(() => _expandedMemberId = id),
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

        ],
      ),
    );
  }
}


/// ── แสดงข้อมูล พื้นที่โครงการ ช่วงการสำรวจ ──────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ไอคอน
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
              icon,
              color: Colors.black54,
              size: 18
          ),
        ),

        const SizedBox(width: 12),

        // label + value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF707078),
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NotoSansThai',
                  color: Color(0xFF24252A),
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

      ],
    );
  }
}


/// ── Point List (ดึงข้อมูล point) ──────────────────────
class _PointListPanel extends StatelessWidget {
  final int projectId;
  final String searchQuery;

  const _PointListPanel({
    required this.projectId,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointTaskCubit, PointTaskState>(
      builder: (context, state) {

        if (state is PointTaskLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF18181C)),
          );
        }

        if (state is PointTaskError) {
          return Center(
            child: Text(
              state.error,
              style: const TextStyle(
                fontFamily: 'NotoSansThai',
                color: Colors.red,
              ),
            ),
          );
        }

        // กรองตาม searchQuery
        if (state is GetPointsSuccess) {
          final filtered = state.points.where((p) {
            if (searchQuery.isEmpty) return true;
            return p.pointName.toLowerCase().contains(searchQuery) ||
                (p.tambon   ?? '').toLowerCase().contains(searchQuery) ||
                (p.amphoe   ?? '').toLowerCase().contains(searchQuery) ||
                (p.province ?? '').toLowerCase().contains(searchQuery);
          }).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีหมุดรังวัดในโครงการ',
                style: TextStyle(
                  fontFamily: 'NotoSansThai',
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              mainAxisExtent: 475,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final p = filtered[index];
              return List_Point_Card(
                point: p,
                onTap: () {
                  Navigator.of(context).push(
                    Point_Detail_Viewer_Page.route(p),
                  );
                },
              );
            },
          );
        }

        return const Center(
          child: Text(
            'ยังไม่มีหมุดรังวัดในโครงการ',
            style: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}


/// ── Member List (ดึงข้อมูลสมาชิกในโครงการ) ──────────────────────
class _MemberPanel extends StatelessWidget {
  final List<UserModel> members;
  final bool isLoaded;
  final bool isOnline;
  final int? expandedId;
  final void Function(int? id) onExpand;

  const _MemberPanel({
    required this.members,
    required this.isLoaded,
    required this.isOnline,
    required this.expandedId,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: CircularProgressIndicator(color: Color(0xFF18181C))),
      );
    }

    if (members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'ยังไม่มีสมาชิกในโครงการ',
            style: TextStyle(
              fontFamily: 'NotoSansThai',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _MemberCard(
          member: member,
          isExpanded: expandedId == member.id,
          isOnline: isOnline,
          onTap: () =>
              onExpand(expandedId == member.id ? null : member.id),
          isFirst: index == 0,
        );
      },
    );
  }
}


/// ── Member Card ──────────────────────
class _MemberCard extends StatelessWidget {
  final UserModel member;
  final bool isExpanded;
  final bool isOnline;
  final VoidCallback onTap;
  final bool isFirst;

  const _MemberCard({
    required this.member,
    required this.isExpanded,
    required this.isOnline,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        //margin: const EdgeInsets.symmetric(vertical: 6),
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
          duration: const Duration(milliseconds: 0),
          child: isExpanded
              ? project_members_tap_card()
              : project_members_card(),
        ),
      ),
    );
  }

  /// card ปกติ (ยังไม่กดการ์ด)
  Widget project_members_card() {
    return Padding(
      key: const ValueKey('collapsed'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _ProfileAvatar(
            profileImg: member.profileImg,
            isOnline: isOnline,
            radius: 28,
          ),
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

                if (member.jobDepartment != null &&
                    member.jobDepartment!.isNotEmpty)
                  Text(
                    member.jobDepartment!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'NotoSansThai',
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),

          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }


  /// card ที่กดแล้ว
  Widget project_members_tap_card() {
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

          _ProfileAvatar(
            profileImg: member.profileImg,
            isOnline: isOnline,
            radius: 40,
          ),

          const SizedBox(height: 12),

          Text(
            '${member.titleName} ${member.firstName} ${member.lastName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'NotoSansThai',
              color: Color(0xFF18181C),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 14),

          // email (ใช้แบบเดิม)
          _DetailRowWithLabel(
            label: 'Email',
            icon: Icons.email_outlined,
            value: member.email,
          ),

          _DetailRowWithLabel(
            label: 'ตำแหน่ง',
            icon: Icons.work_outline,
            value: member.jobPosition,
          ),

          _DetailRowWithLabel(
            label: 'ระดับ',
            icon: Icons.trending_up,
            value: member.jobLevel,
          ),

          _DetailRowWithLabel(
            label: 'สำนัก',
            icon: Icons.apartment,
            value: member.jobOffice,
          ),

          _DetailRowWithLabel(
            label: 'ฝ่าย',
            icon: Icons.account_tree_outlined,
            value: member.jobDepartment,
          ),

          const SizedBox(height: 8),

          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: Color(0xFF18181C),
          ),
        ],
      ),
    );
  }
}

/// ── รูปแบบข้อมูลใน Member Card ──────────────────────
class _DetailRowWithLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;

  const _DetailRowWithLabel({
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
    (value == null || value!.isEmpty) ? '-' : value!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 65,
            child: Row(
              children: [

                Icon(
                  icon,
                  size: 14,
                  color: Color(0xFF515155),
                ),

                const SizedBox(width: 4),

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'NotoSansThai',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF515155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 4),

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
              displayValue,
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


/// ── รูป Profile ────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final String? profileImg;
  final bool isOnline;
  final double radius;

  const _ProfileAvatar({
    required this.profileImg,
    required this.isOnline,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final bool canLoad = isOnline && profileImg != null;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: canLoad
          ? NetworkImage(SecureImage.profileUrl(profileImg), headers: SecureImage.authHeaders)
          : null,
      child: !canLoad
          ? Icon(Icons.person,
          size: radius * 1.1, color: Colors.grey)
          : null,
    );
  }
}