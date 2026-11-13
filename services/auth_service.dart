
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static SupabaseClient get db => Supabase.instance.client;

  // สมัครด้วยอีเมลและรหัสผ่าน
  static Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await db.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  // ยืนยัน OTP ที่ส่งไปทางอีเมล
  static Future<void> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    await db.auth.verifyOTP(
      email: email.trim(),
      token: otp.trim(),
      type: OtpType.signup,
    );
  }

  // เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await db.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ส่ง OTP ใหม่
  static Future<void> resendOtp(String email) async {
    await db.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  // เข้าสู่ระบบด้วย Google ผ่าน Supabase OAuth
  static Future<void> signInWithGoogle() async {
    await db.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.skybusiness.app://login-callback/',
    );
  }

  // ส่งอีเมลสำหรับรีเซ็ตรหัสผ่าน
  static Future<void> sendPasswordReset(String email) async {
    await db.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'com.skybusiness.app://reset-password/',
    );
  }

  // เปลี่ยนรหัสผ่านหลังผ่านขั้นตอน Recovery
  static Future<void> updatePassword(String newPassword) async {
    await db.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // สร้าง Account ID แบบสุ่ม
  static String generateAccountCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    return List.generate(
      12,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ออกจากระบบ
  static Future<void> signOut() async {
    await db.auth.signOut();
  }
}
