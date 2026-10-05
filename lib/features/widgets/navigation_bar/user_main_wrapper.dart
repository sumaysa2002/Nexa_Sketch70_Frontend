import 'package:offline_gnss69_new/export.dart';

class UserMainWrapper extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (_) => BottomNavCubit(),
      child: const UserMainWrapper(),
    ),
  );

  const UserMainWrapper({super.key});

  @override
  State<UserMainWrapper> createState() => _UserMainWrapperState();
}

class _UserMainWrapperState extends State<UserMainWrapper> {
  late PageController _pageController;

  final List<Widget> _pages = const [
    User_Home_Page(),
    User_Approved_Users_Page(),
    Profile_Page(),
    About_Us_Page(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) =>
            context.read<BottomNavCubit>().changeSelectedIndex(page),
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(90, 0, 90, 70),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          height: 80,
          color: const Color(0xFF18181C),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _navItem(context, page: 0, label: "Home",     defaultIcon: IconlyLight.home,     filledIcon: IconlyBold.home),
              _navItem(context, page: 1, label: "Members",     defaultIcon: IconlyLight.user,     filledIcon: IconlyBold.user_2),
              _navItem(context, page: 2, label: "Profile",  defaultIcon: IconlyLight.profile,  filledIcon: IconlyBold.profile),
              _navItem(context, page: 3, label: "About us", defaultIcon: IconlyLight.document, filledIcon: IconlyBold.document),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context, {
        required int page,
        required String label,
        required IconData defaultIcon,
        required IconData filledIcon,
      }) {
    final isSelected = context.watch<BottomNavCubit>().state == page;
    return GestureDetector(
      onTap: () {
        context.read<BottomNavCubit>().changeSelectedIndex(page);
        _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : defaultIcon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}