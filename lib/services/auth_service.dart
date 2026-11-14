
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AuthService {
  static SupabaseClient get db => SupabaseService.client;

  static Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(cleanEmail)) {
      throw Exception('กรุณากรอกอีเมลให้ถูกต้อง');
    }

    if (password.length < 8) {
      throw Exception('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    }

    if (password != confirmPassword) {
      throw Exception('รหัสผ่านทั้งสองช่องไม่ตรงกัน');
    }

    await db.auth.signUp(
      email: cleanEmail,
      password: password,
    );
  }

  static Future<void> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp.trim())) {
      throw Exception('กรุณากรอกรหัส OTP 6 หลัก');
    }

    await db.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: otp.trim(),
      type: OtpType.signup,
    );
  }

  static Future<void> resendOtp(String email) async {
    await db.auth.resend(
      type: OtpType.signup,
      email: email.trim().toLowerCase(),
    );
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await db.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  static Future<void> signInWithGoogle() async {
    await db.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.skybusiness.app://login-callback/',
    );
  }

  static Future<void> sendPasswordReset(String email) async {
    await db.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'com.skybusiness.app://reset-password/',
    );
  }

  static Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    if (!RegExp(r'^\d{6}$').hasMatch(otp.trim())) {
      throw Exception('กรุณากรอกรหัส OTP 6 หลัก');
    }

    await db.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: otp.trim(),
      type: OtpType.recovery,
    );
  }

  static Future<void> updatePassword(String password) async {
    if (password.length < 8) {
      throw Exception('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    }

    await db.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  static Future<void> signOut() async {
    await db.auth.signOut();
  }

  static Future<void> enterTrial(String secretCode) async {
    final code = secretCode.trim();

    if (code.isEmpty) {
      throw Exception('กรุณากรอกรหัสทดลองใช้');
    }

    final result = await db.functions.invoke(
      'create-trial-account',
      body: {
        'secret_code': code,
      },
    );

    if (result.status != 200 || result.data == null) {
      throw Exception('รหัสทดลองใช้ไม่ถูกต้อง');
    }

    final data = Map<String, dynamic>.from(result.data);

    final email = data['email']?.toString();
    final password = data['password']?.toString();

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      throw Exception('ข้อมูลบัญชีทดลองใช้ไม่ถูกต้อง');
    }

    await db.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> deleteOwnAccount() async {
    final result = await db.functions.invoke('delete-own-account');

    if (result.status != 200) {
      throw Exception('ไม่สามารถลบบัญชีได้');
    }

    await db.auth.signOut();
  }
}
