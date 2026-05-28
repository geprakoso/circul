import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../mock_data.dart';
import '../shared/sarah_avatar.dart';

class EditableProfile {
  const EditableProfile({
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    this.imagePath,
  });

  final String name;
  final String username;
  final String bio;
  final String location;
  final String? imagePath;

  EditableProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? imagePath,
  }) {
    return EditableProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    this.takenUsernames = const {},
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker;

  final EditableProfile profile;
  final Set<String> takenUsernames;
  final ImagePicker? _imagePicker;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final ImagePicker _imagePicker;
  String? _imagePath;
  var _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _locationController = TextEditingController(text: widget.profile.location);
    _imagePath = widget.profile.imagePath;
    _imagePicker = widget._imagePicker ?? ImagePicker();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
      );
      if (!mounted || image == null) return;
      setState(() => _imagePath = image.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Foto belum bisa dipilih.')),
        );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() != true) return;

    Navigator.of(context).pop(
      EditableProfile(
        name: _nameController.text.trim(),
        username: _cleanUsername(_usernameController.text),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        imagePath: _imagePath,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi.';
    return null;
  }

  String? _validateUsername(String? value) {
    final cleanUsername = _cleanUsername(value ?? '');
    if (cleanUsername.isEmpty) return 'Username wajib diisi.';
    if (!RegExp(r'^[a-zA-Z0-9._]{3,24}$').hasMatch(cleanUsername)) {
      return '3-24 karakter: huruf, angka, titik, atau underscore.';
    }

    final normalized = cleanUsername.toLowerCase();
    final current = widget.profile.username.toLowerCase();
    final isTaken = widget.takenUsernames.any(
      (username) => username.toLowerCase() == normalized,
    );
    if (normalized != current && isTaken) return 'Username sudah dipakai.';

    return null;
  }

  String _cleanUsername(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: _EditableProfilePicture(
                  imagePath: _imagePath,
                  isLoading: _isPickingImage,
                  onTap: _pickProfilePicture,
                ),
              ),
              const SizedBox(height: 28),
              _ProfileFormField(
                label: 'Name',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: _validateRequired,
              ),
              const SizedBox(height: 16),
              _ProfileFormField(
                label: 'Username',
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                prefixText: '@',
                validator: _validateUsername,
              ),
              const SizedBox(height: 16),
              _ProfileFormField(
                label: 'Bio',
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                validator: _validateRequired,
              ),
              const SizedBox(height: 16),
              _ProfileFormField(
                label: 'City, Country',
                controller: _locationController,
                textInputAction: TextInputAction.done,
                validator: _validateRequired,
                onSubmitted: (_) => _saveProfile(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: kCirculGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableProfilePicture extends StatelessWidget {
  const _EditableProfilePicture({
    required this.imagePath,
    required this.isLoading,
    required this.onTap,
  });

  final String? imagePath;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;

    return Semantics(
      button: true,
      label: 'Ganti foto profil',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (path == null)
              const SarahAvatar(radius: 56)
            else
              CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFFE5E7EB),
                child: ClipOval(
                  child: Image.file(
                    File(path),
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(avatarAsset, fit: BoxFit.cover),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kCirculGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFormField extends StatelessWidget {
  const _ProfileFormField({
    required this.label,
    required this.controller,
    this.prefixText,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? prefixText;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(
        color: kInk,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kCirculGreen, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}
