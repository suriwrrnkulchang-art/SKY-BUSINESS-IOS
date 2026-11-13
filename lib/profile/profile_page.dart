
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

class _BusinessProfilePageState
    extends State<BusinessProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linksController = TextEditingController();

  Map<String, dynamic>? _profile;

  String? _avatarUrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;

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
    _linksController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // LOAD PROFILE
  // --------------------------------------------------

  Future<void> _loadProfile() async {
    try {
      final profile = await AccountService.getProfile();

      if (!mounted) return;

      final rawLinks = profile['social_links'];

      final links = rawLinks is Map
          ? rawLinks.entries
              .map((entry) =>
                  '${entry.key} | ${entry.value}')
              .join('\n')
          : '';

      setState(() {
        _profile = profile;

        _nameController.text =
            profile['display_name']?.toString() ?? '';

        _descriptionController.text =
            profile['business_description']?.toString() ?? '';

        _websiteController.text =
            profile['website_url']?.toString() ?? '';

        _linksController.text = links;

        _avatarUrl =
            profile['avatar_url']?.toString();

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage('โหลดโปรไฟล์ไม่สำเร็จ: $error');
    }
  }

  // --------------------------------------------------
  // MESSAGE
  // --------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: profilePanel2,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  // --------------------------------------------------
  // SOCIAL LINKS
  // --------------------------------------------------

  Map<String, String> _parseLinks() {
    final result = <String, String>{};

    for (final line in _linksController.text.split('\n')) {
      final separator = line.indexOf('|');

      if (separator <= 0) continue;

      final label =
          line.substring(0, separator).trim();

      final url =
          line.substring(separator + 1).trim();

      if (label.isNotEmpty && url.isNotEmpty) {
        result[label] = url;
      }
    }

    return result;
  }

  // --------------------------------------------------
  // PICK AVATAR
  // --------------------------------------------------

  Future<void> _pickAvatar() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return;

      setState(() => _uploading = true);

      final url = await AccountService.uploadAvatar(image);

      if (!mounted) return;

      setState(() {
        _avatarUrl = url;
        _uploading = false;
      });

      _showMessage('อัปโหลดรูปกิจการแล้ว กดบันทึกเพื่อยืนยัน');
    } catch (error) {
      if (!mounted) return;

      setState(() => _uploading = false);

      _showMessage('อัปโหลดรูปไม่สำเร็จ: $error');
    }
  }

  // --------------------------------------------------
  // SAVE PROFILE
  // --------------------------------------------------

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await AccountService.updateProfile(
        displayName: _nameController.text,
        avatarUrl: _avatarUrl,
        businessDescription:
            _descriptionController.text,
        websiteUrl: _websiteController.text,
        socialLinks: _parseLinks(),
      );

      if (!mounted) return;

      _showMessage('บันทึกโปรไฟล์กิจการเรียบร้อยแล้ว');

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() => _saving = false);

      _showMessage('บันทึกไม่สำเร็จ: $error');
    }
  }

  // --------------------------------------------------
  // COPY ACCOUNT ID
  // --------------------------------------------------

  Future<void> _copyAccountId(String code) async {
    await Clipboard.setData(
      ClipboardData(text: code),
    );

    if (!mounted) return;

    _showMessage('คัดลอก Business Account ID แล้ว');
  }

  // --------------------------------------------------
  // TEXT FIELD
  // --------------------------------------------------

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int lines = 1,
    String? hint,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        minLines: lines,
        maxLines: lines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: profilePanel2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
        ),
        validator: required
            ? (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'กรุณากรอก$label';
                }

                return null;
              }
            : null,
      ),
    );
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final accountCode =
        _profile?['account_code']?.toString() ?? '';

    return Scaffold(
      backgroundColor: profileNavy,
      appBar: AppBar(
        backgroundColor: profileNavy,
        title: const Text('Business Profile'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: profileCyan,
              ),
            )
          : _profile == null
              ? const Center(
                  child: Text(
                    'ไม่สามารถโหลดข้อมูลกิจการได้',
                  ),
                )
              : SafeArea(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // BUSINESS AVATAR
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: profilePanel,
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: profileCyan.withOpacity(.18),
                            ),
                          ),
                          child: Column(
                            children: [
                              Stack(
                                alignment:
                                    Alignment.bottomRight,
                                children: [
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor:
                                        profilePanel2,
                                    backgroundImage:
                                        _avatarUrl != null &&
                                                _avatarUrl!.isNotEmpty
                                            ? NetworkImage(_avatarUrl!)
                                            : null,
                                    child: _avatarUrl == null ||
                                            _avatarUrl!.isEmpty
                                        ? const Icon(
                                            Icons.business_rounded,
                                            size: 42,
                                            color: profileCyan,
                                          )
                                        : null,
                                  ),
                                  IconButton.filled(
                                    onPressed: _uploading
                                        ? null
                                        : _pickAvatar,
                                    icon: _uploading
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                          ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _nameController.text.isEmpty
                                    ? 'ชื่อกิจการของคุณ'
                                    : _nameController.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'BUSINESS ACCOUNT',
                                style: TextStyle(
                                  color: profileCyan,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ACCOUNT ID
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: profilePanel,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BUSINESS ACCOUNT ID',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 10,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    SelectableText(
                                      accountCode.isEmpty
                                          ? 'กำลังสร้าง Account ID'
                                          : accountCode,
                                      style: const TextStyle(
                                        color: profileCyan,
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'คัดลอก Account ID',
                                onPressed: accountCode.isEmpty
                                    ? null
                                    : () => _copyAccountId(
                                          accountCode,
                                        ),
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: profileCyan,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'BUSINESS INFORMATION',
                          style: TextStyle(
                            color: profilePurple,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildField(
                          'ชื่อกิจการ',
                          _nameController,
                          required: true,
                        ),

                        _buildField(
                          'คำอธิบายกิจการ',
                          _descriptionController,
                          lines: 4,
                          hint:
                              'แนะนำธุรกิจ สินค้า หรือบริการของคุณ',
                        ),

                        _buildField(
                          'เว็บไซต์',
                          _websiteController,
                          hint: 'https://example.com',
                          keyboardType: TextInputType.url,
                        ),

                        _buildField(
                          'ลิงก์ช่องทางอื่น ๆ',
                          _linksController,
                          lines: 5,
                          hint:
                              'Facebook | https://facebook.com/yourpage\n'
                              'Line | https://line.me/...\n'
                              'TikTok | https://tiktok.com/@username',
                        ),

                        const Text(
                          'ใส่หนึ่งลิงก์ต่อหนึ่งบรรทัด '
                          'ในรูปแบบ ชื่อช่องทาง | URL',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _saving
                                ? null
                                : _saveProfile,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: profileNavy,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_rounded,
                                  ),
                            label: Text(
                              _saving
                                  ? 'กำลังบันทึก...'
                                  : 'บันทึกโปรไฟล์กิจการ',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: profileCyan,
                              foregroundColor: profileNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
