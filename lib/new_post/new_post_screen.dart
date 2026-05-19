import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../feed_post_repository.dart';
import '../shared/sarah_avatar.dart';
import 'widgets/attachment_media_strip.dart';
import 'widgets/compose_footer.dart';
import 'widgets/compose_header.dart';
import 'widgets/compose_tools.dart';
import 'widgets/topic_autocomplete.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key, this.feedPostRepository});

  final FeedPostRepository? feedPostRepository;

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  static const _background = Color(0xFF0E0F10);
  static const _softText = Color(0xFF8C8F93);
  static const _attachmentsChannel = MethodChannel('circul/attachments');

  late final FeedPostRepository _repository;
  final _controller = TextEditingController();
  var _selectedTopic = '';
  var _allowReplies = true;
  var _locationCheckInEnabled = false;
  var _isSubmitting = false;
  final _selectedImagePaths = <String>[];

  bool get _canPost => !_isSubmitting && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() => _isSubmitting = true);

    try {
      await _repository.addPost(
        body: _controller.text,
        topic: _selectedTopic,
        allowReplies: _allowReplies,
        imagePaths: List<String>.of(_selectedImagePaths),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan gagal disimpan lokal.')),
      );
    }
  }

  Future<void> _openImageAttachmentChooser() async {
    try {
      final imagePaths = await _attachmentsChannel.invokeListMethod<String>(
        'openImageChooser',
      );
      if (!mounted || imagePaths == null || imagePaths.isEmpty) return;

      setState(() {
        for (final path in imagePaths) {
          if (!_selectedImagePaths.contains(path)) {
            _selectedImagePaths.add(path);
          }
        }
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Gagal membuka pilihan gambar.'),
        ),
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilihan sistem belum tersedia di platform ini.'),
        ),
      );
    }
  }

  void _removeSelectedImage(String path) {
    setState(() => _selectedImagePaths.remove(path));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _background,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: kCirculGreen,
          surface: _background,
          onSurface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              ComposeHeader(onClose: () => Navigator.of(context).pop()),
              const Divider(height: 1, color: Color(0xFF202225)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SarahAvatar(radius: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    const Text(
                                      'sarahmae',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: _softText,
                                      size: 21,
                                    ),
                                    TopicAutocomplete(
                                      topic: _selectedTopic,
                                      onChanged: (value) => setState(
                                        () => _selectedTopic = value,
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  minLines: 3,
                                  maxLines: 9,
                                  cursorColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Apa yang baru?',
                                    hintStyle: TextStyle(
                                      color: _softText,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding: EdgeInsets.only(top: 6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ComposeTools(
                                  locationCheckInEnabled:
                                      _locationCheckInEnabled,
                                  onImageTap: _openImageAttachmentChooser,
                                  onLocationCheckInTap: () => setState(
                                    () => _locationCheckInEnabled =
                                        !_locationCheckInEnabled,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AttachmentMediaStrip(
                                  locationEnabled: _locationCheckInEnabled,
                                  imagePaths: _selectedImagePaths,
                                  onRemoveImage: _removeSelectedImage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ComposeFooter(
                allowReplies: _allowReplies,
                canPost: _canPost,
                onAllowRepliesChanged: (value) =>
                    setState(() => _allowReplies = value),
                onPost: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
