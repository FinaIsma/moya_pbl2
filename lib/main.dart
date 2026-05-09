import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/opening_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/mood_input_screen.dart';
import 'screens/mood_journal_page.dart';
import 'screens/main_navigation.dart';
import 'screens/profile_screen.dart';
import 'screens/community_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/psychologist_dashboard.dart';
import 'screens/analytics_screen.dart';
import 'screens/psychologist_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Firebase — wajib sebelum runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash':    (context) => const SplashScreen(),
        '/opening':   (context) => const OpeningScreen(),
        '/login':     (context) => const LoginScreen(),
        '/register':  (context) => const RegisterScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/mood':      (context) => const MoodInputScreen(),
        '/mood-journal': (context) => const MoodJournalPage(),
        '/profile':   (context) => const ProfileScreen(),
        '/community': (context) => const CommunityScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/psychologist-dashboard': (context) => const PsychologistDashboard(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/psychologists': (context) => const PsychologistListPage(),
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String name;
  const _PlaceholderScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          '$name Screen\n(coming soon)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF748DAE),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}