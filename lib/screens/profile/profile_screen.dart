// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving  = false;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text  = user.name;
      _bioCtrl.text   = user.bio;
      _phoneCtrl.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (file != null) setState(() => _pickedImage = File(file.path));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppHelpers.showSnackBar(context, 'الاسم لا يمكن أن يكون فارغاً',
          isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? photoUrl;
      if (_pickedImage != null) {
        photoUrl = await StorageService.instance.uploadProfileImage(
          userId: AuthService.instance.currentUser!.uid,
          file: _pickedImage!,
        );
      }
      await AuthService.instance.updateProfile(
        name:     _nameCtrl.text.trim(),
        bio:      _bioCtrl.text.trim(),
        phone:    _phoneCtrl.text.trim(),
        photoUrl: photoUrl,
      );
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      setState(() => _isEditing = false);
      AppHelpers.showSnackBar(context, 'تم حفظ التغييرات');
    } catch (e) {
      AppHelpers.showSnackBar(context, 'حدث خطأ أثناء الحفظ', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('الملف الشخصي'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: AppTheme.primary,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : (user.photoUrl.isNotEmpty
                            ? NetworkImage(user.photoUrl)
                            : null),
                    child: (_pickedImage == null && user.photoUrl.isEmpty)
                        ? Text(
                            AppHelpers.getInitials(user.name),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (!_isEditing) ...[
              Text(
                user.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              if (user.bio.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  user.bio,
                  style: const TextStyle(
                      color: Color(0xFF8797A7), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            const SizedBox(height: 28),

            // Info cards
            if (!_isEditing) ...[
              _infoCard(Icons.email_outlined, 'البريد الإلكتروني', user.email),
              if (user.phone.isNotEmpty)
                _infoCard(Icons.phone_outlined, 'رقم الهاتف', user.phone),
              _infoCard(Icons.calendar_today_outlined, 'تاريخ الانضمام',
                  AppHelpers.formatMessageTime(user.createdAt)),
            ] else ...[
              _editField(
                controller: _nameCtrl,
                label: 'الاسم',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _editField(
                controller: _bioCtrl,
                label: 'النبذة الشخصية',
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              _editField(
                controller: _phoneCtrl,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                isLtr: true,
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: () => setState(() {
                  _isEditing = false;
                  _pickedImage = null;
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: const Text('إلغاء'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Color(0xFF8797A7), fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isLtr = false,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      );
}
