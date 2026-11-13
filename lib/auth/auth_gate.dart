
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:business_dashboard/services/account_service.dart';
import 'login_page.dart';
import 'onboarding_page.dart';

class AuthGate extends StatefulWidget {
  final WidgetBuilder appBuilder;

  const AuthGate({
    super.key,
    required this.appBuilder,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;

  User? _user;
  Future<Map<String, dynamic>>? _profileFuture;

  bool _profileLoading = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();

    final client = Supabase.instance.client;

    _user = client.auth.currentUser;

    _loadProfile();

    _authSubscription =
        client.auth.onAuthStateChange.listen(
      _handleAuthChange,
      onError: (error) {
        if (!mounted) return;

        setState(() {
          _profileError = 'เกิดข้อผิดพลาดในการตรวจสอบบัญชี: $error';
          _profileLoading = false;
        });
      },
    );
  }

  void _handleAuthChange(AuthState state) {
    if (!mounted) return;

    final newUser = state.session?.user;

    // ไม่มีผู้ใช้ที่ล็อกอินอยู่
    if (newUser == null) {
      setState(() {
        _user = null;
        _profileFuture = null;
        _profileError = null;
        _profileLoading = false;
      });

      return;
    }

    // เปลี่ยนผู้ใช้ หรือมีการล็อกอินใหม่
    if (_user?.id != newUser.id ||
        state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.tokenRefreshed) {
      setState(() {
        _user = newUser;
        _loadProfile();
      });
    }
  }

  void _loadProfile() {
    if (!mounted) return;

    final currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      _profileFuture = null;
      _profileLoading = false;
      return;
    }

    _user = currentUser;
    _profileError = null;
    _profileLoading = true;

    _profileFuture = AccountService.getProfile();

    _profileFuture!.then((profile) {
      if (!mounted) return;

      setState(() {
        _profileLoading = false;
        _profileError = null;
      });
    }).catchError((error) {
      if (!mounted) return;

      setState(() {
        _profileLoading = false;
        _profileError = error.toString();
      });
    });
  }

  void _reloadProfile() {
    if (!mounted) return;

    setState(() {
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ยังไม่ได้เข้าสู่ระบบ
    if (_user == null) {
      return const LoginPage();
    }

    // กำลังโหลดข้อมูล
    if (_profileLoading) {
      return const _AuthLoadingScreen();
    }

    // โหลดข้อมูลผิดพลาด
    if (_profileError != null) {
      return _AuthErrorScreen(
        message: _profileError!,
        onRetry: _reloadProfile,
      );
    }

    final future = _profileFuture;

    if (future == null) {
      return _AuthErrorScreen(
        message: 'ไม่พบข้อมูลการโหลดโปรไฟล์',
        onRetry: _reloadProfile,
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        if (snapshot.hasError) {
          return _AuthErrorScreen(
            message: snapshot.error.toString(),
            onRetry: _reloadProfile,
          );
        }

        final profile = snapshot.data;

        if (profile == null) {
          return _AuthErrorScreen(
            message: 'ไม่พบข้อมูลโปรไฟล์ของบัญชีนี้',
            onRetry: _reloadProfile,
          );
        }

        final completed =
            profile['onboarding_completed'] == true;

        // ยังไม่ได้เริ่มต้นใช้งาน
        if (!completed) {
          return OnboardingPage(
            onCompleted: _reloadProfile,
          );
        }

        // เริ่มต้นใช้งานเรียบร้อยแล้ว
        return widget.appBuilder(context);
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF070B14),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF36D9FF),
            ),
            SizedBox(height: 18),
            Text(
              'กำลังตรวจสอบบัญชี SKY BUSINESS',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AuthErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 55,
              ),
              const SizedBox(height: 18),
              const Text(
                'ไม่สามารถโหลดข้อมูลบัญชีได้',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
