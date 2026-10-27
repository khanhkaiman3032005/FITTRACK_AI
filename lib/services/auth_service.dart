import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// User hiện đang đăng nhập
  static User? get currentUser => _client.auth.currentUser;

  /// Session hiện tại
  static Session? get currentSession => _client.auth.currentSession;

  /// Kiểm tra đã đăng nhập hay chưa
  static bool get isLoggedIn => currentUser != null;

  /// Đăng ký
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );
  }

  /// Đăng nhập
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : 'io.fittrack.ai://login-callback/',
    );
  }

  static const String _rememberLoginKey = 'fittrack_remember_login';
  static const String _googleOAuthPendingKey = 'fittrack_google_oauth_pending';

  static Future<bool> getRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberLoginKey) ?? true;
  }

  static Future<void> setRememberLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberLoginKey, value);
  }

  static Future<void> markGoogleOAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_googleOAuthPendingKey, true);
  }

  static Future<bool> takeGoogleOAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_googleOAuthPendingKey) ?? false;

    await prefs.remove(_googleOAuthPendingKey);
    return pending;
  }

  static Future<void> clearGoogleOAuthPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_googleOAuthPendingKey);
  }

  /// Đăng xuất
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Gửi email đặt lại mật khẩu
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }
}
