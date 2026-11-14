
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/account_service.dart';

class AboutOtherPage extends StatefulWidget {
  const AboutOtherPage({super.key});

  @override
  State<AboutOtherPage> createState() => _AboutOtherPageState();
}

class _AboutOtherPageState extends State<AboutOtherPage> {
  static const Color navy = Color(0xFF070B14);
  static const Color panel = Color(0xFF101827);
  static const Color panel2 = Color(0xFF172337);
  static const Color cyan = Color(0xFF36D9FF);

  bool _loading = true;
  String? _error;
  String _accountCode = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final profile = await AccountService.getProfile();

      if (!mounted) return;

      setState(() {
        _accountCode =
            profile['account_code']?.toString() ?? '';

        _displayName =
            profile['display_name']?.toString() ?? '';

        _loading = false;
        _error = null;
      });

      if (_accountCode.isEmpty) {
        setState(() {
          _error = 'ไม่พบ Account ID ในบัญชีนี้';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _copyAccountId() async {
    if (_accountCode.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _accountCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอก Account ID เรียบร้อยแล้ว'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: panel2,
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cyan),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountIdCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF142B40),
            Color(0xFF101827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cyan.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: cyan,
                size: 20,
              ),
              const SizedBox(width: 9),
              const Text(
                'BUSINESS ACCOUNT ID',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'รหัสประจำบัญชีของคุณ',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  _accountCode,
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'คัดลอก Account ID',
                onPressed: _copyAccountId,
                style: IconButton.styleFrom(
                  backgroundColor:
                      cyan.withValues(alpha: 0.12),
                  foregroundColor: cyan,
                ),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.white54,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Account ID เป็นรหัสประจำบัญชีที่ระบบกำหนด '
                  'ไม่สามารถเปลี่ยนแปลงได้ด้วยตนเอง',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'เกี่ยวกับอื่นๆ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: cyan,
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 45,
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'ไม่สามารถโหลดข้อมูลบัญชีได้',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              _loadAccount();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('ลองอีกครั้ง'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'ABOUT SKY BUSINESS',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ข้อมูลบัญชีและระบบ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'จัดการและตรวจสอบข้อมูลประจำบัญชี SKY BUSINESS',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 25),

                      _accountIdCard(),

                      const SizedBox(height: 25),

                      const Text(
                        'ACCOUNT INFORMATION',
                        style: TextStyle(
                          color: cyan,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _informationCard(
                        icon: Icons.person_outline,
                        title: 'ชื่อบัญชี',
                        subtitle: _displayName.isEmpty
                            ? 'ยังไม่ได้กำหนดชื่อบัญชี'
                            : _displayName,
                      ),

                      const SizedBox(height: 10),

                      _informationCard(
                        icon: Icons.cloud_done_outlined,
                        title: 'Database',
                        subtitle: 'Supabase',
                      ),

                      const SizedBox(height: 10),

                      _informationCard(
                        icon: Icons.security_outlined,
                        title: 'Account Security',
                        subtitle: 'บัญชีที่ผูกกับระบบยืนยันตัวตน',
                      ),

                      const SizedBox(height: 30),

                      const Center(
                        child: Text(
                          'SKY BUSINESS',
                          style: TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
