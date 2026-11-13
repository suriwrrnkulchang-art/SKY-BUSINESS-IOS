
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:business_dashboard/services/account_service.dart';
import 'login_page.dart' as login;
import 'onboarding_page.dart' as onboarding;

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
  int _profileRevision = 0;

  void _reloadProfile() {
    if (!mounted) return;

    setState(() {
      _profileRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, authSnapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        if (user == null) {
          return const login.LoginPage();
        }

        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey('${user.id}-$_profileRevision'),
          future: AccountService.getProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return _ErrorScreen(
                message: profileSnapshot.error.toString(),
                onRetry: _reloadProfile,
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _ErrorScreen(
                message: 'ไม่พบข้อมูลโปรไฟล์ กรุณาลองใหม่อีกครั้ง',
                onRetry: _reloadProfile,
              );
            }

            final onboardingCompleted =
                profile['onboarding_completed'] == true;

            if (!onboardingCompleted) {
              return onboarding.OnboardingPage(
                onCompleted: _reloadProfile,
              );
            }

            return widget.appBuilder(context);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF070B14),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF36D9FF),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ไม่สามารถโหลดข้อมูลบัญชีได้',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
