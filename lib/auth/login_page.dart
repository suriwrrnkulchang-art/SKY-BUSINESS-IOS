
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
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _secretCode = TextEditingController();

  bool _loading = false;
  bool _showPassword = false;
  bool _showTrial = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _secretCode.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.signIn(
        email: _email.text,
        password: _password.text,
      );
    } catch (e) {
      _message('เข้าสู่ระบบไม่สำเร็จ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      _message('เข้าสู่ระบบด้วย Google ไม่สำเร็จ: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _trialLogin() async {
    if (_secretCode.text.trim().isEmpty) {
      _message('กรุณากรอกรหัสทดลองใช้งาน');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.enterTrial(_secretCode.text);
    } catch (e) {
      _message('ไม่สามารถใช้รหัสนี้ได้: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text);

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รีเซ็ตรหัสผ่าน'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'อีเมลบัญชีของคุณ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('ส่งคำขอ'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (email == null || email.isEmpty) return;

    setState(() => _loading = true);
    try {
      await AuthService.sendPasswordReset(email);
      _message('ส่งคำขอรีเซ็ตรหัสผ่านแล้ว กรุณาตรวจสอบอีเมล');
    } catch (e) {
      _message('ส่งคำขอไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
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
                    const SizedBox(height: 35),
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF36D9FF),
                            Color(0xFF637BFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF070B14),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'SKY BUSINESS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'BUSINESS COMMAND CENTER',
                      style: TextStyle(
                        color: Color(0xFF36D9FF),
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 38),
                    const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เข้าสู่บัญชี SKY BUSINESS ของคุณ',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 25),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(
                        'อีเมล',
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'กรุณากรอกอีเมลให้ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration(
                        'รหัสผ่าน',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _showPassword = !_showPassword,
                          ),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          (value ?? '').isEmpty
                              ? 'กรุณากรอกรหัสผ่าน'
                              : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _forgotPassword,
                        child: const Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(
                            color: Color(0xFF36D9FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF36D9FF),
                          foregroundColor: const Color(0xFF070B14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'เข้าสู่ระบบ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'หรือเข้าสู่ระบบด้วย',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _googleLogin,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('ดำเนินการต่อด้วย Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => setState(
                        () => _showTrial = !_showTrial,
                      ),
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('มีรหัสทดลองใช้งาน?'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF36D9FF),
                        side: const BorderSide(color: Colors.white12),
                      ),
                    ),
                    if (_showTrial) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _secretCode,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoration(
                          'รหัสทดลองใช้งาน',
                          Icons.vpn_key_outlined,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _loading ? null : _trialLogin,
                        child: const Text('ตรวจสอบรหัสและเข้าใช้งาน'),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ยังไม่มีบัญชี?',
                          style: TextStyle(color: Colors.white54),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              color: Color(0xFF36D9FF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'SECURE ACCOUNT • SUPABASE AUTHENTICATION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                        letterSpacing: 1.2,
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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF36D9FF)),
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF101827),
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
        borderSide: const BorderSide(color: Color(0xFF36D9FF)),
      ),
    );
  }
}
