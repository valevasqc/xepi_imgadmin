import 'package:firebase_auth/firebase_auth.dart';

/// Authentication and authorization service
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Superuser UIDs (hardcoded for now)
  static const List<String> _superuserUids = [
    '9QFhlKjJMkXMvrB0ISh1rghfPAl1', // Valeria
    'yMnQBCQrtpblH3yTHd05XLVloZu2' // Michelle
  ];

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check if current user is a superuser (admin)
  static bool get isSuperuser {
    final uid = currentUser?.uid;
    if (uid == null) return false;
    return _superuserUids.contains(uid);
  }

  /// Check if current user is an employee (not superuser)
  static bool get isEmployee => !isSuperuser;

  /// Get user display name or email
  static String get userDisplayName {
    final user = currentUser;
    if (user == null) return 'Usuario';
    return user.displayName ?? user.email ?? 'Usuario';
  }

  /// Get user email
  static String? get userEmail => currentUser?.email;

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
