import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/password_login_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notifications_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.getString('access_token') != null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: CafeApp(hasToken: hasToken),
    ),
  );
}

class AppState extends ChangeNotifier {
  String? currentQrToken;
  String? currentTableNumber;
  int? currentBranchId;
  int? selectedBranchId;        // branch user is browsing (home tab)
  String? selectedBranchName;   // display name for that branch

  void setTableSession(String qr, String table, int? branchId) {
    currentQrToken = qr;
    currentTableNumber = table;
    currentBranchId = branchId;
    notifyListeners();
  }

  void setSelectedBranch(int id, String name) {
    selectedBranchId = id;
    selectedBranchName = name;
    notifyListeners();
  }

  void clearSession() {
    currentQrToken = null;
    currentTableNumber = null;
    currentBranchId = null;
    notifyListeners();
  }
}

class CafeApp extends StatelessWidget {
  final bool hasToken;

  const CafeApp({super.key, required this.hasToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Café App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          primary: const Color(0xFF059669),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0FDF4), // emerald-50
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF064E3B), // emerald-950
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.light, // Force light mode always
      builder: (context, child) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)
              ]
            ),
            child: child,
          ),
        );
      },
      initialRoute: hasToken ? '/dashboard' : '/login',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/password_login': (context) => const PasswordLoginScreen(),
        '/otp_verification': (context) => const OtpVerificationScreen(),
        '/setup_profile': (context) => const SetupProfileScreen(),
        '/dashboard': (context) => const MainScreen(),
        '/qr_scanner': (context) => const QrScannerScreen(),
        '/menu': (context) => const MenuScreen(),
        '/notifications': (context) => NotificationsScreen(),
      },
    );
  }
}
