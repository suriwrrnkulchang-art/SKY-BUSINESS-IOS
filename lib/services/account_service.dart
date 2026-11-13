
import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class AccountService {
  static SupabaseClient get db => SupabaseService.client;

  // --------------------------------------------------
  // CURRENT USER
  // --------------------------------------------------

  static String get uid {
    final userId = db.auth.currentUser?.id;

    if (userId == null || userId.isEmpty) {
      throw Exception('กรุณาเข้าสู่ระบบก่อน');
    }

    return userId;
  }

  // --------------------------------------------------
  // DEFAULT PROFILE DATA
  // --------------------------------------------------

  static String _defaultName() {
    final email = db.auth.currentUser?.email ?? '';
    final prefix = email.split('@').first.trim();

    if (prefix.isEmpty) {
      return 'SKY BUSINESS';
    }

    return prefix;
  }

  /// สร้าง Account ID รูปแบบ SKY- ตามด้วยตัวเลข 10 หลัก
  /// ต้องบันทึกลงฐานข้อมูล ไม่สร้างใหม่ทุกครั้งที่เปิดหน้าโปรไฟล์
  static String _generateAccountCode() {
    const digits = '0123456789';
    final random = Random.secure();

    final number = List.generate(
      10,
      (_) => digits[random.nextInt(digits.length)],
    ).join();

    return 'SKY-$number';
  }

  static String _randomAvatarName() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    return List.generate(
      16,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // --------------------------------------------------
  // GET PROFILE
  // --------------------------------------------------

  static Future<Map<String, dynamic>> getProfile() async {
    final userId = uid;

    try {
      final existingProfile = await db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // มีโปรไฟล์อยู่แล้ว
      if (existingProfile != null) {
        final profile = Map<String, dynamic>.from(existingProfile);

        final currentCode =
            profile['account_code']?.toString() ?? '';

        // เปลี่ยนรหัสเก่าที่ไม่ใช่ SKY- ตามด้วยเลข 10 หลัก
        if (!RegExp(r'^SKY-[0-9]{10}$').hasMatch(currentCode)) {
          for (var attempt = 0; attempt < 5; attempt++) {
            final newCode = _generateAccountCode();

            try {
              await db
                  .from('profiles')
                  .update({
                    'account_code': newCode,
                    'updated_at':
                        DateTime.now().toUtc().toIso8601String(),
                  })
                  .eq('id', userId);

              profile['account_code'] = newCode;
              break;
            } catch (error) {
              if (attempt == 4) rethrow;
            }
          }
        }

        return profile;
      }

      // ยังไม่มีโปรไฟล์: สร้างใหม่
      final newProfile = <String, dynamic>{
        'id': userId,
        'account_code': _generateAccountCode(),
        'display_name': _defaultName(),
        'business_description': '',
        'website_url': '',
        'social_links': <String, String>{},
        'onboarding_completed': false,
        'theme_mode': 'dark',
      };

      Object? lastError;

      // ลองใหม่หาก Account ID ซ้ำ
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          await db.from('profiles').upsert(
            newProfile,
            onConflict: 'id',
          );

          lastError = null;
          break;
        } catch (error) {
          lastError = error;

          if (attempt == 4) rethrow;

          newProfile['account_code'] = _generateAccountCode();
        }
      }

      if (lastError != null) {
        throw lastError;
      }

      final createdProfile = await db
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return Map<String, dynamic>.from(createdProfile);
    } catch (error) {
      throw Exception(
        'ไม่สามารถโหลดหรือสร้างข้อมูลโปรไฟล์ได้: $error',
      );
    }
  }

  // --------------------------------------------------
  // UPDATE PROFILE
  // --------------------------------------------------

  static Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? businessDescription,
    String? websiteUrl,
    Map<String, String>? socialLinks,
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
        throw Exception('ชื่อกิจการต้องไม่เป็นค่าว่าง');
      }

      updates['display_name'] = name;
    }

    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    if (businessDescription != null) {
      updates['business_description'] =
          businessDescription.trim();
    }

    if (websiteUrl != null) {
      updates['website_url'] = websiteUrl.trim();
    }

    if (socialLinks != null) {
      updates['social_links'] = socialLinks;
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

    try {
      final result = await db
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select('id')
          .maybeSingle();

      if (result == null) {
        throw Exception(
          'ไม่พบโปรไฟล์ที่ต้องการแก้ไข หรือไม่มีสิทธิ์อัปเดตข้อมูล',
        );
      }
    } catch (error) {
      throw Exception(
        'ไม่สามารถบันทึกข้อมูลโปรไฟล์ได้: $error',
      );
    }
  }

  // --------------------------------------------------
  // UPLOAD AVATAR
  // --------------------------------------------------

  static Future<String> uploadAvatar(XFile image) async {
    final userId = uid;

    try {
      final file = File(image.path);

      if (!await file.exists()) {
        throw Exception('ไม่พบไฟล์รูปภาพ');
      }

      final extension = image.path.split('.').last.toLowerCase();

      const allowedExtensions = [
        'jpg',
        'jpeg',
        'png',
        'webp',
      ];

      if (!allowedExtensions.contains(extension)) {
        throw Exception(
          'รองรับเฉพาะไฟล์ JPG, JPEG, PNG และ WEBP',
        );
      }

      final fileName = _randomAvatarName();
      final path = '$userId/$fileName.$extension';

      await db.storage.from('profile-avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '3600',
        ),
      );

      return db.storage
          .from('profile-avatars')
          .getPublicUrl(path);
    } catch (error) {
      throw Exception(
        'ไม่สามารถอัปโหลดรูปโปรไฟล์ได้: $error',
      );
    }
  }

  // --------------------------------------------------
  // SAVE THEME
  // --------------------------------------------------

  static Future<void> saveTheme(String mode) async {
    const allowedModes = [
      'light',
      'dark',
      'system',
    ];

    if (!allowedModes.contains(mode)) {
      throw Exception('รูปแบบธีมไม่ถูกต้อง');
    }

    await updateProfile(themeMode: mode);
  }
}
