
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

  static String _randomAvatarName() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      12,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final profile = {
  'id': uid,
  'display_name': _defaultName(),
  'onboarding_completed': false,
  'theme_mode': 'dark',
};

await db.from('profiles').upsert(profile);

    final profile = {
      'id': uid,
      'display_name': _defaultName(),
      'onboarding_completed': false,
      'theme_mode': 'dark',
    };

    await db.from('profiles').upsert(profile);

    final created = await db
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();

    return Map<String, dynamic>.from(created);
  }

  static Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    bool? onboardingCompleted,
    String? themeMode,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (displayName != null) {
      updates['display_name'] = displayName.trim();
    }

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    if (onboardingCompleted != null) {
      updates['onboarding_completed'] = onboardingCompleted;
    }

    if (themeMode != null) {
      updates['theme_mode'] = themeMode;
    }

    await db.from('profiles').update(updates).eq('id', uid);
  }

  static Future<String> uploadAvatar(XFile image) async {
    final file = File(image.path);
    final extension = image.path.split('.').last.toLowerCase();

    const allowed = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowed.contains(extension)) {
      throw Exception('รองรับเฉพาะไฟล์ JPG, PNG และ WEBP');
    }

    final path = '$uid/${_randomAvatarName()}.$extension';

    await db.storage.from('profile-avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(
        upsert: true,
        cacheControl: '3600',
      ),
    );

    return db.storage.from('profile-avatars').getPublicUrl(path);
  }

  static Future<void> saveTheme(String mode) async {
    if (!['light', 'dark', 'system'].contains(mode)) {
      throw Exception('รูปแบบธีมไม่ถูกต้อง');
    }

    await updateProfile(themeMode: mode);
  }
}
