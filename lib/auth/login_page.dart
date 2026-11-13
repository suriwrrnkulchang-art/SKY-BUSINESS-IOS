
import 'package:flutter/material.dart';
import 'package:business_dashboard/services/account_service.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingPage({
    super.key,
    required this.onCompleted,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool loading = false;

  Future<void> completeSetup() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      await AccountService.updateProfile(
        onboardingCompleted: true,
      );

      if (!mounted) return;

      // แจ้ง AuthGate ให้โหลดข้อมูลโปรไฟล์ใหม่
      widget.onCompleted();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเริ่มต้นใช้งานได้: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rocket_launch,
                size: 75,
                color: Color(0xFF36D9FF),
              ),
              const SizedBox(height: 25),
              const Text(
                'WELCOME TO SKY BUSINESS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'ศูนย์บัญชาการธุรกิจของคุณ\nพร้อมเริ่มต้นแล้ว',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : completeSetup,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('เริ่มต้นใช้งาน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
