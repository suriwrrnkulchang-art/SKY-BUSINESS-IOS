
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/account_service.dart';
import 'auth_pages.dart';
import 'onboarding_page.dart';

class AuthGate extends StatelessWidget {
  final WidgetBuilder appBuilder;

  const AuthGate({
    super.key,
    required this.appBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: AccountService.getProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError) {
              return _ErrorScreen(
                message: profileSnapshot.error.toString(),
                onRetry: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => AuthGate(
                        appBuilder: appBuilder,
                      ),
                    ),
                  );
                },
              );
            }

            final profile = profileSnapshot.data!;

            if (profile['onboarding_completed'] != true) {
              return const OnboardingPage();
            }

            return appBuilder(context);
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
      body: Center(
        child: Padding(
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
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
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
    );
  }
}
ผ