import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'screens/admin_login.dart';
import 'screens/main_layout.dart';
// Legacy dashboard deployed separately
// import 'screens/admin_dashboard_legacy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XEPI Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundGray,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.blue,
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            return const MainLayout();
          }
          return const AdminLoginScreen();
        },
      ),
    );
  }
}
