
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _trialCodeController = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  bool _trialLoading = false;
  bool _showPassword = false;
  bool _resetLoading = false;

  static const Color _background = Color(0xFF070B14);
  static const Color _primary = Color(0xFF36D9FF);
  static const Color _panel = Color(0xFF101827);

  bool get _isBusy =>
      _loading || _googleLoading || _trialLoading || _resetLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _trialCodeController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    if (_isBusy || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() => _loading = true);

    try {
      await AuthService.signIn(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );

      // AuthGate จะตรวจสอบ Supabase Session
      // และนำผู้ใช้ไปยังหน้าที่ถูกต้องโดยอัตโนมัติ
    } catch (error) {
      _message('เข้าสู่ระบบไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _googleLogin() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    setState(() => _googleLoading = true);

    try {
      await AuthService.signInWithGoogle();

      // OAuth จะนำผู้ใช้ไปยัง Google
      // หลังเข้าสู่ระบบสำเร็จ Supabase จะจัดการ Session
    } catch (error) {
      _message('เข้าสู่ระบบด้วย Google ไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  Future<void> _enterTrial() async {
    if (_isBusy) return;

    final code = _trialCodeController.text.trim();

    if (code.isEmpty) {
      _message('กรุณากรอกรหัสทดลองใช้');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _trialLoading = true);

    try {
      await AuthService.enterTrial(code);

      // AuthGate จะตรวจสอบ Session
      // และนำผู้ใช้เข้าสู่บัญชีทดลองใช้
    } catch (error) {
      _message('เข้าใช้งานบัญชีทดลองไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() => _trialLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _message('กรุณากรอกอีเมลให้ถูกต้องก่อนรีเซ็ตรหัสผ่าน');
      return;
    }

    if (_isBusy) return;

    setState(() => _resetLoading = true);

    try {
      await AuthService.sendPasswordReset(email);

      if (!mounted) return;

      _message('ส่งคำขอรีเซ็ตรหัสผ่านแล้ว กรุณาตรวจสอบอีเมล');
    } catch (error) {
      _message('ส่งคำขอรีเซ็ตรหัสผ่านไม่สำเร็จ: $error');
    } finally {
      if (mounted) {
        setState(() => _resetLoading = false);
      }
    }
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: suffix,
      filled: true,
      fillColor: _panel,
      labelStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }

  Widget _loadingIndicator({Color color = _background}) {
    return SizedBox(
      width: 21,
      height: 21,
      child: CircularProgressIndicator(
        strokeWidth: 2.3,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),

                    Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primary.withValues(alpha: 0.08),
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        size: 48,
                        color: _primary,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'SKY BUSINESS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'BUSINESS COMMAND CENTER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 35),

                    const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'เข้าสู่บัญชี SKY BUSINESS ของคุณ',
                      style: TextStyle(color: Colors.white54),
                    ),

                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _emailController,
                      enabled: !_isBusy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(
                        'อีเมล',
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(email)) {
                          return 'กรุณากรอกอีเมลให้ถูกต้อง';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isBusy,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(
                        'รหัสผ่าน',
                        Icons.lock_outline,
                        suffix: IconButton(
                          onPressed: _isBusy
                              ? null
                              : () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรหัสผ่าน';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isBusy ? null : _resetPassword,
                        child: Text(
                          _resetLoading
                              ? 'กำลังส่งคำขอ...'
                              : 'ลืมรหัสผ่าน?',
                          style: const TextStyle(color: _primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        onPressed: _isBusy ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: _background,
                          disabledBackgroundColor:
                              _primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? _loadingIndicator()
                            : const Text(
                                'เข้าสู่ระบบ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Colors.white12),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'หรือเข้าสู่ระบบด้วย',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Colors.white12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isBusy ? null : _googleLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _googleLoading
                            ? _loadingIndicator(color: _primary)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.g_mobiledata_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'เข้าสู่ระบบด้วย Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.white12),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ทดลองใช้งาน',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.white12),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _trialCodeController,
                      enabled: !_isBusy,
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      decoration: _decoration(
                        'Trial Code',
                        Icons.vpn_key_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isBusy ? null : _enterTrial,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _trialLoading
                            ? _loadingIndicator(color: _primary)
                            : const Text(
                                'เข้าใช้งานด้วยรหัสทดลอง',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ยังไม่มีบัญชี?',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),

                    const Text(
                      'SKY BUSINESS • BUSINESS COMMAND CENTER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
