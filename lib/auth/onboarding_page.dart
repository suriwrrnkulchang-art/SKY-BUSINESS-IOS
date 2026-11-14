
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  static const Color background = Color(0xFF070B14);
  static const Color primary = Color(0xFF36D9FF);
  static const Color panel = Color(0xFF101827);
  static const Color panel2 = Color(0xFF172337);

  final PageController _pageController = PageController();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _websiteController =
      TextEditingController();

  final TextEditingController _socialController =
      TextEditingController();

  int _currentStep = 0;

  bool _loading = true;
  bool _saving = false;

  String _accountCode = '';
  String _themeMode = 'dark';
  String? _avatarUrl;

  XFile? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  final int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // LOAD PROFILE
  // --------------------------------------------------

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final profile = await AccountService.getProfile();

      if (!mounted) return;

      final socialLinks =
          Map<String, dynamic>.from(
        profile['social_links'] ?? {},
      );

      setState(() {
        _nameController.text =
            profile['display_name']?.toString() ?? '';

        _descriptionController.text =
            profile['business_description']?.toString() ?? '';

        _websiteController.text =
            profile['website_url']?.toString() ?? '';

        _accountCode =
            profile['account_code']?.toString() ?? '';

        _avatarUrl =
            profile['avatar_url']?.toString();

        _themeMode =
            profile['theme_mode']?.toString() ?? 'dark';

        if (!['dark', 'light', 'system']
            .contains(_themeMode)) {
          _themeMode = 'dark';
        }

        _socialController.text = socialLinks.entries
            .map((entry) => '${entry.key} | ${entry.value}')
            .join('\n');

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'ไม่สามารถโหลดข้อมูลบัญชีได้: $error',
        isError: true,
      );
    }
  }

  // --------------------------------------------------
  // IMAGE PICKER
  // --------------------------------------------------

  Future<void> _pickAvatar() async {
    if (_saving) return;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedImage = image;
      });
    } catch (error) {
      _showMessage(
        'ไม่สามารถเลือกรูปภาพได้: $error',
        isError: true,
      );
    }
  }

  void _removeSelectedAvatar() {
    setState(() {
      _selectedImage = null;
    });
  }

  // --------------------------------------------------
  // SOCIAL LINKS
  // --------------------------------------------------

  Map<String, String> _parseSocialLinks() {
    final result = <String, String>{};

    for (final line in _socialController.text.split('\n')) {
      final text = line.trim();

      if (text.isEmpty) continue;

      final separator = text.indexOf('|');

      if (separator <= 0) continue;

      final label = text.substring(0, separator).trim();
      final url = text.substring(separator + 1).trim();

      if (label.isNotEmpty && url.isNotEmpty) {
        result[label] = url;
      }
    }

    return result;
  }

  // --------------------------------------------------
  // VALIDATION
  // --------------------------------------------------

  bool _validateCurrentStep() {
    if (_currentStep == 1) {
      if (_nameController.text.trim().isEmpty) {
        _showMessage(
          'กรุณากรอกชื่อที่ต้องการแสดง',
          isError: true,
        );
        return false;
      }

      if (_nameController.text.trim().length > 80) {
        _showMessage(
          'ชื่อควรมีความยาวไม่เกิน 80 ตัวอักษร',
          isError: true,
        );
        return false;
      }
    }

    if (_currentStep == 2) {
      final website = _websiteController.text.trim();

      if (website.isNotEmpty) {
        final uri = Uri.tryParse(website);

        if (uri == null ||
            !uri.hasScheme ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.host.isEmpty) {
          _showMessage(
            'กรุณากรอกเว็บไซต์ในรูปแบบ https://example.com',
            isError: true,
          );
          return false;
        }
      }
    }

    return true;
  }

  // --------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------

  void _nextStep() {
    if (_saving || !_validateCurrentStep()) return;

    if (_currentStep >= _totalSteps - 1) {
      _saveProfile();
      return;
    }

    setState(() {
      _currentStep++;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_saving || _currentStep <= 0) return;

    setState(() {
      _currentStep--;
    });

    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _goToStep(int step) {
    if (_saving || step < 0 || step >= _totalSteps) return;

    if (step > _currentStep && !_validateCurrentStep()) {
      return;
    }

    setState(() {
      _currentStep = step;
    });

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  // --------------------------------------------------
  // SAVE PROFILE
  // --------------------------------------------------

  Future<void> _saveProfile() async {
    if (_saving) return;

    if (_nameController.text.trim().isEmpty) {
      _showMessage(
        'กรุณากรอกชื่อที่ต้องการแสดง',
        isError: true,
      );

      _goToStep(1);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      String? uploadedAvatarUrl;

      // อัปโหลดรูปภาพเมื่อผู้ใช้เลือกรูปใหม่
      if (_selectedImage != null) {
        uploadedAvatarUrl =
            await AccountService.uploadAvatar(_selectedImage!);
      }

      await AccountService.updateProfile(
        displayName: _nameController.text.trim(),
        businessDescription:
            _descriptionController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        socialLinks: _parseSocialLinks(),
        themeMode: _themeMode,
        avatarUrl: uploadedAvatarUrl,
        onboardingCompleted: true,
      );

      if (!mounted) return;

      _showMessage('ตั้งค่าบัญชีเรียบร้อยแล้ว');

      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'บันทึกข้อมูลไม่สำเร็จ: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // SKIP ONBOARDING
  // --------------------------------------------------

  Future<void> _skipSetup() async {
    if (_saving) return;

    final shouldSkip = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: panel,
          title: const Text(
            'ข้ามการตั้งค่า?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'คุณสามารถตั้งค่าโปรไฟล์และข้อมูลธุรกิจภายหลังได้ '
            'ระบบจะใช้ข้อมูลเริ่มต้นของบัญชีให้ก่อน',
            style: TextStyle(
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('กลับไปตั้งค่า'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ข้ามไปก่อน'),
            ),
          ],
        );
      },
    );

    if (shouldSkip != true || !mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      // ไม่ลบข้อมูลเดิมและไม่สร้าง Account ID ใหม่
      await AccountService.updateProfile(
        onboardingCompleted: true,
      );

      if (!mounted) return;

      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'ไม่สามารถข้ามการตั้งค่าได้: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFB3261E) : panel2,
      ),
    );
  }

  // --------------------------------------------------
  // COMMON UI
  // --------------------------------------------------

  InputDecoration _decoration(
    String label, {
    String? hint,
    IconData? icon,
    int? maxLines = 1,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: primary,
            ),
      alignLabelWithHint: maxLines != 1,
      filled: true,
      fillColor: panel,
      labelStyle: const TextStyle(
        color: Colors.white60,
      ),
      hintStyle: const TextStyle(
        color: Colors.white30,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.white12,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.white12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                SelectableText(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // STEP 1: WELCOME
  // --------------------------------------------------

  Widget _welcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.08),
              border: Border.all(
                color: primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.12),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 50,
              color: primary,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Center(
          child: Column(
            children: [
              const Text(
                'WELCOME TO',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'SKY BUSINESS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'มาสร้างพื้นที่จัดการธุรกิจของคุณกัน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 35),

        _infoCard(
          icon: Icons.badge_outlined,
          title: 'ACCOUNT ID',
          value: _accountCode,
        ),

        const SizedBox(height: 14),

        _infoCard(
          icon: Icons.verified_user_outlined,
          title: 'บัญชีของคุณ',
          value: 'บัญชีส่วนตัว SKY BUSINESS',
        ),

        const SizedBox(height: 25),

        const Text(
          'การตั้งค่านี้จะช่วยให้ระบบจดจำข้อมูลโปรไฟล์และธุรกิจของคุณ '
          'คุณสามารถแก้ไขข้อมูลเหล่านี้ได้ภายหลัง',
          style: TextStyle(
            color: Colors.white54,
            height: 1.8,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // STEP 2: PROFILE
  // --------------------------------------------------

  Widget _profileStep() {
    ImageProvider? avatarProvider;

    if (_selectedImage != null) {
      avatarProvider = FileImage(
        File(_selectedImage!.path),
      );
    } else if (_avatarUrl != null &&
        _avatarUrl!.trim().isNotEmpty) {
      avatarProvider = NetworkImage(_avatarUrl!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'สร้างโปรไฟล์ของคุณ',
          'ตั้งชื่อและเลือกรูปภาพสำหรับบัญชี SKY BUSINESS',
        ),

        const SizedBox(height: 30),

        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: panel2,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? const Icon(
                            Icons.business_rounded,
                            size: 45,
                            color: primary,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickAvatar,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: background,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: _pickAvatar,
                icon: const Icon(
                  Icons.upload_rounded,
                  size: 18,
                ),
                label: const Text('เลือกรูปโปรไฟล์ / โลโก้'),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                ),
              ),

              if (_selectedImage != null ||
                  (_avatarUrl != null &&
                      _avatarUrl!.isNotEmpty))
                TextButton(
                  onPressed: _removeSelectedAvatar,
                  child: const Text(
                    'ใช้รูปเดิม / ไม่เปลี่ยนรูป',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        TextField(
          controller: _nameController,
          maxLength: 80,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'ชื่อที่ต้องการแสดง',
            hint: 'เช่น SKYFILM STUDIO',
            icon: Icons.person_outline_rounded,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'ชื่อนี้จะแสดงในพื้นที่บัญชีและหน้า Dashboard',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 20),

        _infoCard(
          icon: Icons.fingerprint_rounded,
          title: 'ACCOUNT ID ของคุณ',
          value: _accountCode,
        ),
      ],
    );
  }

  // --------------------------------------------------
  // STEP 3: BUSINESS
  // --------------------------------------------------

  Widget _businessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'ข้อมูลธุรกิจ',
          'กรอกข้อมูลเพื่อให้คุณจัดการธุรกิจได้สะดวกขึ้น '
          'ทุกช่องในหน้านี้สามารถเว้นว่างได้',
        ),

        const SizedBox(height: 25),

        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'รายละเอียดธุรกิจ',
            hint: 'อธิบายเกี่ยวกับธุรกิจของคุณ...',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
        ),

        const SizedBox(height: 18),

        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: const TextStyle(color: Colors.white),
          decoration: _decoration(
            'เว็บไซต์',
            hint: 'https://example.com',
            icon: Icons.language_rounded,
          ),
        ),

        const SizedBox(height: 25),

        const Text(
          'ช่องทางโซเชียลมีเดีย',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'กรอกหนึ่งช่องทางต่อหนึ่งบรรทัด '
          'โดยใช้รูปแบบ ชื่อแพลตฟอร์ม | URL',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _socialController,
          minLines: 4,
          maxLines: 7,
          autocorrect: false,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
          ),
          decoration: _decoration(
            'Social Links',
            hint:
                'Facebook | https://facebook.com/...\n'
                'Instagram | https://instagram.com/...\n'
                'TikTok | https://tiktok.com/...',
            maxLines: 5,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: primary,
                size: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ข้อมูลธุรกิจและช่องทางติดต่อสามารถแก้ไขได้ภายหลัง '
                  'ไม่จำเป็นต้องกรอกให้ครบในตอนนี้',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // STEP 4: PREFERENCES
  // --------------------------------------------------

  Widget _preferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'ปรับแต่งการใช้งาน',
          'เลือกรูปแบบหน้าตาที่คุณต้องการใช้ใน SKY BUSINESS',
        ),

        const SizedBox(height: 30),

        const Text(
          'ธีมของแอปพลิเคชัน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        _themeOption(
          mode: 'dark',
          title: 'Dark Mode',
          description: 'ธีมสีเข้ม เหมาะกับการใช้งานในที่แสงน้อย',
          icon: Icons.dark_mode_rounded,
        ),

        const SizedBox(height: 12),

        _themeOption(
          mode: 'light',
          title: 'Light Mode',
          description: 'ธีมสีสว่าง',
          icon: Icons.light_mode_rounded,
        ),

        const SizedBox(height: 12),

        _themeOption(
          mode: 'system',
          title: 'System Default',
          description: 'ใช้ธีมตามการตั้งค่าของอุปกรณ์',
          icon: Icons.settings_brightness_rounded,
        ),

        const SizedBox(height: 25),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white12,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: primary,
                size: 23,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Text(
                  'คุณสามารถเปลี่ยนธีมได้อีกครั้งในเมนูตั้งค่าภายหลัง',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _themeOption({
    required String mode,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final selected = _themeMode == mode;

    return InkWell(
      onTap: () {
        setState(() {
          _themeMode = mode;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.09)
              : panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : Colors.white12,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? primary : Colors.white60,
              size: 25,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? primary : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // STEP 5: REVIEW
  // --------------------------------------------------

  Widget _reviewStep() {
    final socialLinks = _parseSocialLinks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'ตรวจสอบข้อมูล',
          'ตรวจสอบข้อมูลก่อนเริ่มต้นใช้งาน SKY BUSINESS',
        ),

        const SizedBox(height: 25),

        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: panel2,
            backgroundImage: _selectedImage != null
                ? FileImage(File(_selectedImage!.path))
                : (_avatarUrl != null &&
                        _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null),
            child: _selectedImage == null &&
                    (_avatarUrl == null ||
                        _avatarUrl!.isEmpty)
                ? const Icon(
                    Icons.business_rounded,
                    size: 35,
                    color: primary,
                  )
                : null,
          ),
        ),

        const SizedBox(height: 15),

        Center(
          child: Text(
            _nameController.text.trim().isEmpty
                ? 'ยังไม่ได้ตั้งชื่อ'
                : _nameController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),

        const SizedBox(height: 25),

        _reviewItem(
          'ACCOUNT ID',
          _accountCode,
          Icons.fingerprint_rounded,
        ),

        _reviewItem(
          'รายละเอียดธุรกิจ',
          _descriptionController.text.trim(),
          Icons.description_outlined,
        ),

        _reviewItem(
          'เว็บไซต์',
          _websiteController.text.trim(),
          Icons.language_rounded,
        ),

        _reviewItem(
          'ช่องทางโซเชียล',
          socialLinks.isEmpty
              ? 'ยังไม่ได้เพิ่ม'
              : '${socialLinks.length} ช่องทาง',
          Icons.link_rounded,
        ),

        _reviewItem(
          'ธีม',
          _themeMode == 'dark'
              ? 'Dark Mode'
              : _themeMode == 'light'
                  ? 'Light Mode'
                  : 'System Default',
          Icons.palette_outlined,
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary.withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_rounded,
                color: primary,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'เมื่อกดยืนยัน ระบบจะบันทึกข้อมูลโปรไฟล์ '
                  'และนำคุณเข้าสู่หน้า Dashboard',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewItem(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: background,
        body: Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(
              Icons.business_center_rounded,
              color: primary,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'SKY BUSINESS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _skipSetup,
            child: const Text(
              'ข้าม',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ตั้งค่าบัญชีของคุณ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_currentStep + 1}/$_totalSteps',
                            style: const TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value:
                              (_currentStep + 1) / _totalSteps,
                          minHeight: 5,
                          backgroundColor: panel2,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        [
                          'ยินดีต้อนรับ',
                          'ข้อมูลโปรไฟล์',
                          'ข้อมูลธุรกิจ',
                          'การตั้งค่า',
                          'ตรวจสอบข้อมูล',
                        ][_currentStep],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _welcomeStep(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _profileStep(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _businessStep(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _preferencesStep(),
                      ),
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _reviewStep(),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    15,
                    24,
                    20,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(
                          alpha: 0.07,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : _previousStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white24,
                              ),
                              minimumSize:
                                  const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text('ย้อนกลับ'),
                          ),
                        ),

                      if (_currentStep > 0)
                        const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _saving
                              ? null
                              : _nextStep,
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: background,
                            disabledBackgroundColor:
                                primary.withValues(alpha: 0.35),
                            minimumSize:
                                const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(13),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: background,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentStep ==
                                              _totalSteps - 1
                                          ? 'บันทึกและเริ่มใช้งาน'
                                          : 'ดำเนินการต่อ',
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentStep ==
                                              _totalSteps - 1
                                          ? Icons.check_rounded
                                          : Icons
                                              .arrow_forward_rounded,
                                      size: 19,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
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
