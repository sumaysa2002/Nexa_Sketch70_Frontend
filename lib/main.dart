import 'package:offline_gnss69_new/export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  Hive.registerAdapter(SavedDrawingAdapter());

  await Hive.openBox<SavedDrawing>('drawings_field');
  await Hive.openBox<SavedDrawing>('drawings_note');
  await Hive.openBox<SavedDrawing>('drawings_field_edit');
  await Hive.openBox<SavedDrawing>('drawings_note_edit');

  runApp(MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => TaskCubit()),
        BlocProvider(create: (_) => PointTaskCubit()),
      ],
      child: const MyApp()
  ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState(){
    super.initState();
    context.read<AuthCubit>().getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF18181C),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Colors.grey[900],
          contentTextStyle: const TextStyle(
            fontFamily: 'NotoSansThai',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          behavior: SnackBarBehavior.fixed,
        ),
        useMaterial3: true,
      ),

      /// splash >> login >> otp >> home
      home: const SplashPage(),
    );
  }
}

/// Login แยกตาม status ของ User
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (previous, current) {
        return current is AuthLoggedIn || current is AuthInitial;
      },
      builder: (context, state) {

        if (state is AuthLoggedIn) {
          final userStatus = state.userModel.status;
          // admin
          if (userStatus == 'admin') return BlocProvider(
            create: (_) => BottomNavCubit(),
            child: const AdminMainWrapper(),
          );
          // user
          if (userStatus == 'user') return BlocProvider(
            create: (_) => BottomNavCubit(),
            child: const UserMainWrapper(),
          );
          // null
          return BlocProvider(
            create: (_) => BottomNavCubit(),
            child: const NullUserMainWrapper(),
          );
        }

        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return const LoginPage();
      },
    );
  }
}
