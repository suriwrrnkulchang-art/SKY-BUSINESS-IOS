
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/account_service.dart';

const Color profileNavy = Color(0xFF070B14);
const Color profilePanel = Color(0xFF101827);
const Color profilePanel2 = Color(0xFF172337);
const Color profileCyan = Color(0xFF36D9FF);
const Color profilePurple = Color(0xFFB18CFF);

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() =>
      _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _socialController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _avatarUrl;
  String _accountCode = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  
Future<void> _loadProfile() async {
  if (!mounted) return;

  setState(() => _loading = true);

  try {
    final profile = await AccountService.getProfile();

    if (!mounted) return;

    final socialLinks = Map<String, dynamic>.from(
      profile['social_links'] ?? {},
    );

    setState(() {
      _nameController.text =
          profile['display_name']?.toString() ?? '';

      _descriptionController.text =
          profile['business_description']?.toString() ?? '';

      _websiteController.text =
          profile['website_url']?.toString() ?? '';

      _avatarUrl = profile['avatar_url']?.toString();

      _accountCode =
          profile['account_code']?.toString() ?? '';

      _socialController.text = socialLinks.entries
          .map((entry) => '${entry.key} | ${entry.value}')
          .join('\n');
    });
  } catch (e) {
    if (!mounted) return;
    _showMessage('โหลดข้อมูลไม่สำเร็จ: $e');
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}


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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await AccountService.updateProfile(
        displayName: _nameController.text.trim(),
        businessDescription: _descriptionController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        socialLinks: _parseSocialLinks(),
      );

      if (!mounted) return;

      _showMessage('บันทึกข้อมูลธุรกิจเรียบร้อยแล้ว');
    } catch (e) {
      if (!mounted) return;

      _showMessage('บันทึกไม่สำเร็จ: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  
Future<void> _changeAvatar() async {
  try {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (!mounted || image == null) return;

    setState(() => _saving = true);

    final url = await AccountService.uploadAvatar(image);

    await AccountService.updateProfile(
      avatarUrl: url,
    );

    if (!mounted) return;

    setState(() {
      _avatarUrl = url;
    });

    _showMessage('เปลี่ยนรูปโปรไฟล์ธุรกิจแล้ว');
  } catch (e) {
    if (!mounted) return;

    _showMessage('เปลี่ยนรูปไม่สำเร็จ: $e');
  } finally {
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}


  Future<void> _copyAccountCode() async {
    if (_accountCode.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: _accountCode),
    );

    if (!mounted) return;

    _showMessage('คัดลอก Account ID แล้ว');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: profilePanel2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 22),
      child: Row(
        children: [
          Icon(icon, color: profileCyan, size: 20),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: profilePanel2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: profileCyan),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profileNavy,
      appBar: AppBar(
        backgroundColor: profileNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Business Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: profileCyan,
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _saving ? null : _changeAvatar,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 53,
                                  backgroundColor: profilePanel2,
                                  backgroundImage:
                                      _avatarUrl != null &&
                                              _avatarUrl!.isNotEmpty
                                          ? NetworkImage(_avatarUrl!)
                                          : null,
                                  child: _avatarUrl == null ||
                                          _avatarUrl!.isEmpty
                                      ? const Icon(
                                          Icons.business,
                                          color: profileCyan,
                                          size: 43,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: profileCyan,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: profileNavy,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Business Logo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'แตะรูปเพื่อเปลี่ยนโลโก้ธุรกิจ',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    _sectionTitle(
                      'Business Information',
                      Icons.business_outlined,
                    ),

                    _textField(
                      label: 'ชื่อธุรกิจ',
                      hint: 'กรอกชื่อธุรกิจของคุณ',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อธุรกิจ';
                        }
                        return null;
                      },
                    ),

                    _textField(
                      label: 'คำอธิบายธุรกิจ',
                      hint: 'อธิบายเกี่ยวกับธุรกิจของคุณ',
                      controller: _descriptionController,
                      maxLines: 4,
                    ),

                    _textField(
                      label: 'เว็บไซต์',
                      hint: 'https://example.com',
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                    ),

                    _sectionTitle(
                      'Social Links',
                      Icons.link,
                    ),

                    _textField(
                      label: 'ลิงก์โซเชียล',
                      hint: 'Facebook | https://facebook.com/...\nInstagram | https://instagram.com/...',
                      controller: _socialController,
                      maxLines: 5,
                    ),

                    const Text(
                      'ใส่หนึ่งลิงก์ต่อหนึ่งบรรทัด โดยใช้รูปแบบ ชื่อ | URL',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),

                    _sectionTitle(
                      'About Business Account',
                      Icons.verified_user_outlined,
                    ),

                    Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: profilePanel,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Business Account ID',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  _accountCode.isEmpty
                                      ? 'ยังไม่มี Account ID'
                                      : _accountCode,
                                  style: const TextStyle(
                                    color: profileCyan,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _accountCode.isEmpty
                                    ? null
                                    : _copyAccountCode,
                                icon: const Icon(
                                  Icons.copy,
                                  color: profileCyan,
                                ),
                                tooltip: 'คัดลอก Account ID',
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'รหัสประจำบัญชีธุรกิจ ใช้สำหรับแสดงตัวตนและอ้างอิงบัญชี',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveProfile,
                        icon: _saving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: profileNavy,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _saving ? 'กำลังบันทึก...' : 'บันทึกข้อมูลธุรกิจ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: profileCyan,
                          foregroundColor: profileNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
