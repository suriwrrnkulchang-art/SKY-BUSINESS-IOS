
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'กรุณากำหนด SUPABASE_URL และ SUPABASE_ANON_KEY',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static User? get currentUser => client.auth.currentUser;

  static String? get userId => currentUser?.id;

  static bool get isLoggedIn => currentUser != null;
}
