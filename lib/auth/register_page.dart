
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _email.text.trim().toLowerCase();

    try {
      await AuthService.signUp(
        email: email,
        password: _password.text,
        confirmPassword: _confirmPassword.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(email: email),
        ),
      );
    } catch (e) {
      _message('สมัครสมาชิกไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF36D9FF)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF101827),
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
        borderSide: const BorderSide(color: Color(0xFF36D9FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        title: const Text('สร้างบัญชี SKY BUSINESS'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Color(0xFF36D9FF),
                    size: 55,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'สมัครสมาชิก',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สร้างบัญชีใหม่เพื่อเริ่มต้นใช้งาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration(
                      'อีเมลของคุณ',
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration(
                      'สร้างรหัสผ่าน',
                      Icons.lock_outline,
                      suffix: IconButton(
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
                    validator: (value) {
                      if ((value ?? '').length < 8) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration(
                      'ยืนยันรหัสผ่านอีกครั้ง',
                      Icons.lock_reset_rounded,
                    ),
                    validator: (value) {
                      if (value != _password.text) {
                        return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร\n'
                    '• ช่องยืนยันรหัสผ่านจะไม่สามารถเปิดดูได้\n'
                    '• ระบบจะส่งรหัส OTP 6 หลักไปยังอีเมลของคุณ',
                    style: TextStyle(
                      color: Colors.white54,
                      height: 1.8,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _register,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF36D9FF),
                        foregroundColor: const Color(0xFF070B14),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'สมัครสมาชิกและส่งรหัสยืนยัน',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
