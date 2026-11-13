
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class OtpPage extends StatefulWidget {
  final String email;

  const OtpPage({
    super.key,
    required this.email,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otp = TextEditingController();
  bool _loading = false;
  bool _verified = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_otp.text.trim())) {
      _message('กรุณากรอกรหัส OTP ให้ครบ 6 หลัก');
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.verifySignupOtp(
        email: widget.email,
        otp: _otp.text.trim(),
      );

      if (!mounted) return;

      setState(() => _verified = true);

      _message('ยืนยันอีเมลสำเร็จ');

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _message('รหัสยืนยันไม่ถูกต้องหรือหมดอายุ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      await AuthService.resendOtp(widget.email);
      _message('ส่งรหัสยืนยันใหม่แล้ว กรุณาตรวจสอบอีเมล');
    } catch (e) {
      _message('ส่งรหัสใหม่ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        title: const Text('ยืนยันอีเมล'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF36D9FF),
                  size: 65,
                ),
                const SizedBox(height: 25),
                const Text(
                  'ตรวจสอบอีเมลของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'เราได้ส่งรหัสยืนยัน 6 หลักไปยัง',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF36D9FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    letterSpacing: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: const TextStyle(color: Colors.white24),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF101827),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading || _verified ? null : _verify,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF36D9FF),
                      foregroundColor: const Color(0xFF070B14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'ยืนยันรหัส OTP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : _resend,
                  child: const Text(
                    'ไม่ได้รับรหัส? ส่งรหัสใหม่',
                    style: TextStyle(color: Color(0xFF36D9FF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
