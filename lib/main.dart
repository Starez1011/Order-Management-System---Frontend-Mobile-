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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  void setTableSession(String qr, String table) {
    currentQrToken = qr;
    currentTableNumber = table;
    notifyListeners();
  }

  void clearSession() {
    currentQrToken = null;
    currentTableNumber = null;
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
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
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
      },
    );
  }
}
