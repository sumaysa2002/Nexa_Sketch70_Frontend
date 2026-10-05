import 'package:offline_gnss69_new/export.dart';

class NullUser_Home_Page extends StatefulWidget {

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const NullUser_Home_Page(),
  );

  const NullUser_Home_Page({super.key});

  @override
  State<NullUser_Home_Page> createState() => _NullUser_Home_PageState();
}

class _NullUser_Home_PageState extends State<NullUser_Home_Page> {

  // ค้นหา
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // เช็คอินเทอร์เน็ต
  bool _isOnline = true;


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  void initState() {
    super.initState();

    /// ดึงข้อมูลโครงการ
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthLoggedIn) {
      final token = authState.userModel.token;

      AuthRemoteRepository().getAllUsers(token: token).catchError((_) {});

      context.read<TaskCubit>().syncUpdatedProjects(token: token).then((_) {
        if (mounted) {
          context.read<TaskCubit>().getAllProjects(token: token);
        }
      });

      context.read<AuthCubit>().syncPendingUser(token: token).catchError((_) {});

      // เช็คสถานะ internet
      Connectivity().checkConnectivity().then((result) {
        if (mounted) {
          setState(() {
            _isOnline = result.contains(ConnectivityResult.wifi) ||
                result.contains(ConnectivityResult.mobile);
          });
        }
      });

      // การเปลี่ยนแปลง internet
      Connectivity().onConnectivityChanged.listen((data) async {
        final online = data.contains(ConnectivityResult.wifi) ||
            data.contains(ConnectivityResult.mobile);

        // online / offline
        if (mounted) {
          setState(() {
            _isOnline = online;
          });
        }

        if (online) {
          await context.read<TaskCubit>().syncProjects(token: token);
          if (mounted) {
            context.read<TaskCubit>().getAllProjects(token: token);
          }
        }
      });

    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF18181C),
              Color(0xFF505050),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoggedIn) {
                    final user = state.userModel;
                    return Expanded(
                      child: Column(
                        children: [

                          const SizedBox(height: 30),

                          /// รูปโปรไฟล์
                          if (user.profileImg != null)
                            Stack(
                              children: [
                                Container(
                                  width: 80.0,
                                  height: 80.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3.0),
                                  ),
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundImage: NetworkImage(
                                      "${Constants.backendUri}/uploads/profiles/${user.profileImg}",
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _isOnline
                                          ? const Color(0xFF70FB54)
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3.0),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Stack(
                              children: [
                                Container(
                                  width: 80.0,
                                  height: 80.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3.0),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _isOnline
                                          ? const Color(0xFF70FB54)
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          w_text_thai_notosansthai(
                            name: "${user.firstName} ${user.lastName}",
                            fontWeight: FontWeight.w700,
                            font_Size: 22,
                            color: Colors.white,
                          ),

                          const SizedBox(height: 10),

                          w_text_thai_notosansthai(
                            name: (user.jobDepartment == null || user.jobDepartment!.isEmpty)
                                ? "ไม่ทราบสังกัดหน่วยงาน"
                                : user.jobDepartment!,
                            font_Size: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),

                          const SizedBox(height: 20),

                          /// Body
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [

                                Positioned.fill(
                                  top: 10,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [

                                            /// ค้นหา
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                              child: TextField(
                                                controller: _searchController,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _searchQuery = value.toLowerCase();
                                                  });
                                                },
                                                style: const TextStyle(
                                                  fontFamily: 'NotoSansThai',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF18181C),
                                                ),
                                                decoration: InputDecoration(
                                                  hintText: "ค้นหาชื่อโครงการ",
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

                                            Expanded(
                                              child: BlocBuilder<TaskCubit, TaskState>(
                                                builder: (context, state) {

                                                  // loading
                                                  if (state is ProjectLoading) {
                                                    return const Center(
                                                      child: CircularProgressIndicator(color: Color(0xFF18181C)),
                                                    );
                                                  }

                                                  // error
                                                  if (state is ProjectError) {
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

                                                  /// รายชื่อโครงการ
                                                  if (state is GetProjectsSuccess) {

                                                    // ไม่มีโครงการ
                                                    if (state.projects.isEmpty) {
                                                      return const Center(
                                                        child: Text(
                                                          'ไม่มีโครงการในระบบ',
                                                          style: TextStyle(
                                                            fontFamily: 'NotoSansThai',
                                                            fontSize: 16,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    if (state is GetProjectsSuccess) {

                                                      // กรองตาม _searchQuery (การค้นหา)
                                                      final filtered = state.projects.where((pj) {
                                                        if (_searchQuery.isEmpty) return true;
                                                        final nameMatch = pj.projectName.toLowerCase().contains(_searchQuery);
                                                        final provinceMatch = (pj.province ?? '').toLowerCase().contains(_searchQuery);
                                                        return nameMatch || provinceMatch;
                                                      }).toList();

                                                      if (filtered.isEmpty) {
                                                        return const Center(
                                                          child: Text(
                                                            'ไม่พบโครงการที่ค้นหา',
                                                            style: TextStyle(
                                                              fontFamily: 'NotoSansThai',
                                                              fontSize: 16,
                                                              color: Colors.grey,
                                                            ),
                                                          ),
                                                        );
                                                      }

                                                      return ListView.builder(
                                                        padding: const EdgeInsets.only(bottom: 20),
                                                        itemCount: filtered.length,
                                                        itemBuilder: (context, index) {
                                                          final pj = filtered[index];
                                                          return List_Project_Card(
                                                            userRole:    pj.userRole,
                                                            projectName: pj.projectName,
                                                            startDate:   pj.projectStartDate != null
                                                                ? DateTime.parse(pj.projectStartDate!)
                                                                : DateTime.now(),
                                                            endDate:     pj.projectEndDate != null
                                                                ? DateTime.parse(pj.projectEndDate!)
                                                                : DateTime.now(),
                                                            provinces:   pj.province != null
                                                                ? pj.province!.split(', ')
                                                                : [],
                                                            onTap: () {
                                                              if (pj.userRole == 'Editor') {
                                                                Navigator.of(context).push(
                                                                  User_Project_Detail_Editor_Page.route(pj),
                                                                );
                                                              } else {
                                                                Navigator.of(context).push(
                                                                  User_Project_Detail_Viewer_Page.route(pj),
                                                                );
                                                              }
                                                            },
                                                          );
                                                        },
                                                      );
                                                    }
                                                  }

                                                  return const SizedBox.shrink();
                                                },
                                              ),
                                            ),


                                            // แถบสีขาวด้านล่าง
                                            Container(
                                              width: double.infinity,
                                              height: 50,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(50),
                                                  bottomRight: Radius.circular(50),
                                                ),
                                              ),
                                            ),

                                          ],
                                        ),
                                      ), // placeholder content
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),

                        ],
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
