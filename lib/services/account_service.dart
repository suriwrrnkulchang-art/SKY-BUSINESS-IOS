
import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AccountService {
  static SupabaseClient get db => SupabaseService.client;

  static String get uid {
    final id = db.auth.currentUser?.id;
    if (id == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');
    return id;
  }

  static String _defaultName() {
    final email = db.auth.currentUser?.email ?? '';
    final prefix = email.split('@').first;
    return prefix.isEmpty ? 'ผู้ใช้งาน' : prefix;
  }

  // สร้างรหัสบัญชีที่ไม่ซ้ำกันจาก UUID ของผู้ใช้
  static String _generateAccountCode() {
    final userId = uid.replaceAll('-', '').toUpperCase();
    return 'SKY-$userId';
  }

  static String _randomAvatarName() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      12,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final userId = uid;

    // ตรวจสอบโปรไฟล์เดิมก่อน
    final response = await db
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response != null) {
      return Map<String, dynamic>.from(response);
    }

    // สร้างโปรไฟล์ใหม่พร้อม account_code
    final profile = {
      'id': userId,
      'account_code': _generateAccountCode(),
      'display_name': _defaultName(),
      'onboarding_completed': false,
      'theme_mode': 'dark',
    };

    await db.from('profiles').upsert(profile);

    // ดึงข้อมูลโปรไฟล์ที่สร้างสำเร็จ
    final created = await db
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return Map<String, dynamic>.from(created);
  }

  
static Future<void> updateProfile({
  String? displayName,
  String? avatarUrl,
  bool? onboardingCompleted,
  String? themeMode,
}) async {
  final userId = uid;

  final updates = <String, dynamic>{
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  };

  if (displayName != null) {
    final name = displayName.trim();

    if (name.isEmpty) {
      throw Exception('กรุณากรอกชื่อผู้ใช้งาน');
    }

    updates['display_name'] = name;
  }

  if (avatarUrl != null) {
    updates['avatar_url'] = avatarUrl;
  }

  if (onboardingCompleted != null) {
    updates['onboarding_completed'] =
        onboardingCompleted;
  }

  if (themeMode != null) {
    if (!['light', 'dark', 'system'].contains(themeMode)) {
      throw Exception('รูปแบบธีมไม่ถูกต้อง');
    }

    updates['theme_mode'] = themeMode;
  }

  // ส่ง UPDATE และขอผลลัพธ์กลับมาตรวจสอบ
  final result = await db
      .from('profiles')
      .update(updates)
      .eq('id', userId)
      .select('id')
      .maybeSingle();

  // ถ้าไม่มีแถวถูกแก้ไข แสดงว่าไม่สามารถบันทึกได้
  if (result == null) {
    throw Exception(
      'ไม่พบโปรไฟล์ที่สามารถแก้ไขได้ '
      'กรุณาตรวจสอบข้อมูลบัญชีและ Supabase RLS Policy',
    );
  }
}
