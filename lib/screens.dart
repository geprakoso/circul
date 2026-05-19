import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'feed_post_repository.dart';
import 'mock_data.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.feedPostRepository});

  final FeedPostRepository? feedPostRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FeedPostRepository _repository;
  late Future<List<FeedPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _postsFuture = _repository.getPosts();
  }

  Future<void> _openComposer() async {
    final didPost = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => NewPostScreen(feedPostRepository: _repository),
      ),
    );
    if (!mounted || didPost != true) return;

    setState(() {
      _postsFuture = _repository.getPosts();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Postingan komunitas tersimpan lokal.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<FeedPost>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          final posts = snapshot.data ?? const <FeedPost>[];

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 18),
              children: [
                _HomeHeader(onComposeTap: _openComposer),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: Text(
                    'Database lokal belum bisa dibuka.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              posts.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(bottom: 18),
              children: [
                _HomeHeader(onComposeTap: _openComposer),
                const SizedBox(height: 36),
                const Center(child: CircularProgressIndicator()),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 18),
            itemCount: posts.length + 1,
            separatorBuilder: (context, index) {
              if (index < 1) return const SizedBox.shrink();
              return const Divider(
                height: 1,
                indent: 24,
                endIndent: 24,
                color: kLine,
              );
            },
            itemBuilder: (context, index) {
              if (index == 0) return _HomeHeader(onComposeTap: _openComposer);

              return FeedPostCard(post: posts[index - 1]);
            },
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onComposeTap});

  final VoidCallback onComposeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CirculHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 26),
          child: Row(
            children: [
              const SarahAvatar(radius: 31, showAddBadge: true),
              const SizedBox(width: 20),
              Expanded(child: _HomeComposerEntry(onTap: onComposeTap)),
            ],
          ),
        ),
        const Divider(height: 1, color: kLine),
      ],
    );
  }
}

class _HomeComposerEntry extends StatelessWidget {
  const _HomeComposerEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SearchFieldShell(
      hint: 'Kirim sesuatu ke komunitas...',
      icon: Icons.edit_note_rounded,
      onTap: onTap,
    );
  }
}

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
              _ComposeHeader(onClose: () => Navigator.of(context).pop()),
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
                                    _TopicAutocomplete(
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
                                _ComposeTools(
                                  locationCheckInEnabled:
                                      _locationCheckInEnabled,
                                  onImageTap: _openImageAttachmentChooser,
                                  onLocationCheckInTap: () => setState(
                                    () => _locationCheckInEnabled =
                                        !_locationCheckInEnabled,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _AttachmentMediaStrip(
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
              _ComposeFooter(
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

class _ComposeHeader extends StatelessWidget {
  const _ComposeHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Tutup',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Post baru',
              style: TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Draf',
            onPressed: () {},
            icon: const Icon(
              Icons.note_add_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Lainnya',
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TopicAutocomplete extends StatefulWidget {
  const _TopicAutocomplete({required this.topic, required this.onChanged});

  final String topic;
  final ValueChanged<String> onChanged;

  @override
  State<_TopicAutocomplete> createState() => _TopicAutocompleteState();
}

class _TopicAutocompleteState extends State<_TopicAutocomplete> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.topic);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _TopicAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.topic,
        selection: TextSelection.collapsed(offset: widget.topic.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Iterable<String> _optionsFor(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    final topicTitles = topics.map((topic) => topic.title).toList()
      ..sort((a, b) => _topicKey(a).compareTo(_topicKey(b)));

    if (query.isEmpty) return topicTitles;

    return topicTitles.where((title) {
      final key = _topicKey(title);
      return key.startsWith(query) || key.contains(query);
    });
  }

  String _topicKey(String title) {
    return title
        .replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '')
        .trim()
        .toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: _optionsFor,
      onSelected: (value) {
        widget.onChanged(value);
        _controller.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return SizedBox(
              width: 214,
              child: TextField(
                controller: textEditingController,
                focusNode: focusNode,
                cursorColor: Colors.white,
                maxLines: 1,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: _NewPostScreenState._softText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Topik baru',
                  hintStyle: TextStyle(
                    color: _NewPostScreenState._softText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: widget.onChanged,
                onTap: () {
                  if (textEditingController.selection.isValid) return;
                  textEditingController.selection = TextSelection.collapsed(
                    offset: textEditingController.text.length,
                  );
                },
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 270,
              constraints: const BoxConstraints(maxHeight: 240),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF222426),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF34373A)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 20,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: optionList.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFF303336)),
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tag_rounded,
                            color: kCirculGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ComposeTools extends StatelessWidget {
  const _ComposeTools({
    required this.locationCheckInEnabled,
    required this.onImageTap,
    required this.onLocationCheckInTap,
  });

  final bool locationCheckInEnabled;
  final VoidCallback onImageTap;
  final VoidCallback onLocationCheckInTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        _ComposeToolButton(
          icon: Icons.image_outlined,
          tooltip: 'Foto',
          onPressed: onImageTap,
        ),
        _ComposeToolButton(
          icon: Icons.flag_outlined,
          tooltip: 'Check-in lokasi',
          selected: locationCheckInEnabled,
          onPressed: onLocationCheckInTap,
        ),
        const _ComposeToolButton(icon: Icons.gif_box_outlined, tooltip: 'GIF'),
        const _ComposeToolButton(
          icon: Icons.note_alt_outlined,
          tooltip: 'Stiker',
        ),
        const _ComposeToolButton(
          icon: Icons.article_outlined,
          tooltip: 'Template',
        ),
        const _ComposeToolButton(
          icon: Icons.more_horiz_rounded,
          tooltip: 'Lainnya',
        ),
      ],
    );
  }
}

class _ComposeToolButton extends StatelessWidget {
  const _ComposeToolButton({
    required this.icon,
    required this.tooltip,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF183B2A) : null,
      ),
      onPressed: onPressed ?? () {},
      icon: Icon(
        icon,
        color: selected ? kCirculGreen : const Color(0xFF73777C),
        size: 34,
      ),
    );
  }
}

class _AttachmentMediaStrip extends StatelessWidget {
  const _AttachmentMediaStrip({
    required this.locationEnabled,
    required this.imagePaths,
    required this.onRemoveImage,
  });

  final bool locationEnabled;
  final List<String> imagePaths;
  final ValueChanged<String> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 170.0;
        final cardWidth = imagePaths.isEmpty
            ? constraints.maxWidth
            : math.min(170.0, constraints.maxWidth * 0.72);

        if (imagePaths.isEmpty) {
          return _LocationPlaceholderBox(
            enabled: locationEnabled,
            width: cardWidth,
          );
        }

        return SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _LocationPlaceholderBox(
                  enabled: locationEnabled,
                  width: cardWidth,
                ),
                const SizedBox(width: 12),
                for (final path in imagePaths) ...[
                  _ImagePreviewCard(
                    path: path,
                    width: cardWidth,
                    onRemove: () => onRemoveImage(path),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.path,
    required this.width,
    required this.onRemove,
  });

  final String path;
  final double width;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: width,
        height: 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(path), fit: BoxFit.cover),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationPlaceholderBox extends StatelessWidget {
  const _LocationPlaceholderBox({required this.enabled, required this.width});

  final bool enabled;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFF151819),
            border: Border.all(
              color: enabled ? kCirculGreen : const Color(0xFF2B2E31),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _MiniMapPlaceholderPainter()),
              ),
              if (!enabled)
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
                ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1D1F),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF303438)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag_outlined, color: kCirculGreen, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Lokasi check-in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(child: _MapPinPlaceholder(enabled: enabled)),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xE61A1D1F),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF303438)),
                  ),
                  child: Text(
                    enabled ? 'Map placeholder' : 'Tap bendera untuk check-in',
                    style: const TextStyle(
                      color: Color(0xFFB8BBBF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _MapPinPlaceholder extends StatelessWidget {
  const _MapPinPlaceholder({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: enabled ? 1 : 0.86,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFE9FFF0) : const Color(0xFF39403C),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF101113), width: 5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: enabled ? 0.4 : 0.18),
              blurRadius: enabled ? 18 : 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.flag_rounded,
          color: enabled ? kCirculGreen : const Color(0xFF73777C),
          size: 28,
        ),
      ),
    );
  }
}

class _MiniMapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF181C1D);
    canvas.drawRect(Offset.zero & size, background);

    final areaPaint = Paint()..color = const Color(0xFF1D2622);
    final area = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.55,
        size.width * 0.48,
        size.height * 0.92,
        size.width,
        size.height * 0.68,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, areaPaint);

    final primaryRoad = Paint()
      ..color = const Color(0xFF34393D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final secondaryRoad = Paint()
      ..color = const Color(0xFF2B3033)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-10, size.height * 0.35),
      Offset(size.width + 10, size.height * 0.18),
      secondaryRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height + 10),
      Offset(size.width * 0.68, -10),
      primaryRoad,
    );
    canvas.drawLine(
      Offset(-10, size.height * 0.56),
      Offset(size.width + 10, size.height * 0.48),
      secondaryRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, -8),
      Offset(size.width * 0.96, size.height + 8),
      secondaryRoad,
    );

    final gridPaint = Paint()
      ..color = const Color(0x223F464A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = 24.0; x < size.width; x += 46) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 22.0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ComposeFooter extends StatelessWidget {
  const _ComposeFooter({
    required this.allowReplies,
    required this.canPost,
    required this.onAllowRepliesChanged,
    required this.onPost,
  });

  final bool allowReplies;
  final bool canPost;
  final ValueChanged<bool> onAllowRepliesChanged;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;

          return Row(
            children: [
              if (compact)
                IconButton(
                  tooltip: 'Opsi posting',
                  onPressed: () {},
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF9B9EA2),
                    size: 28,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded, size: 28),
                  label: const Text('Opsi posting'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9B9EA2),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              _ReplyToggle(
                value: allowReplies,
                onChanged: onAllowRepliesChanged,
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: canPost ? onPost : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(104, 56),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF2B2D2F),
                  disabledForegroundColor: const Color(0xFF151719),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Kirim'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReplyToggle extends StatelessWidget {
  const _ReplyToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Izinkan balasan',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 78,
          height: 56,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF3A3D40) : const Color(0xFF242628),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF33363A)),
          ),
          child: Align(
            alignment: value ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF111315),
                shape: BoxShape.circle,
              ),
              child: Icon(
                value ? Icons.public_rounded : Icons.lock_outline_rounded,
                color: const Color(0xFF7C8085),
                size: 25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  var _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const CirculHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: kCirculGreen,
                    size: 31,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi saat ini',
                          style: TextStyle(color: kMuted),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Gondang Manis, Solo',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: kLine),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.energy_savings_leaf_rounded,
                    color: Color(0xFF62BF65),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dampak lingkungan',
                        style: TextStyle(color: kMuted),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Sedang',
                        style: TextStyle(
                          color: Color(0xFFE68A00),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: WasteMapPainter())),
                const Positioned(left: 20, top: 22, child: ImpactLegend()),
                const Positioned(
                  right: 28,
                  top: 30,
                  child: MapSquareButton(icon: Icons.my_location_rounded),
                ),
                const Positioned(
                  left: 24,
                  bottom: 304,
                  child: MapSquareButton(
                    icon: Icons.tune_rounded,
                    label: 'Filter',
                  ),
                ),
                const Positioned(
                  right: 30,
                  bottom: 304,
                  child: MapSquareButton(
                    icon: Icons.near_me_rounded,
                    label: 'Lokasi saya',
                  ),
                ),
                const Positioned(
                  left: 360,
                  top: 272,
                  child: MapMarker(
                    label: 'Pasar\nTokanan',
                    distance: '450 m',
                    color: Color(0xFF7B2CBF),
                    icon: Icons.local_mall_rounded,
                  ),
                ),
                const Positioned(
                  left: 52,
                  top: 430,
                  child: MapMarker(
                    label: 'Taman\nGondang Manis',
                    distance: '350 m',
                    color: kCirculGreen,
                    icon: Icons.park_rounded,
                  ),
                ),
                const Positioned(
                  right: 42,
                  top: 590,
                  child: MapMarker(
                    label: 'Bengkel Las\nSunan Karan',
                    distance: '200 m',
                    color: Color(0xFF7B2CBF),
                    icon: Icons.factory_rounded,
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocationBubble(),
                      SizedBox(height: 4),
                      UserLocationPulse(),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ActivitySheet(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    onSeeAll: widget.onSeeAll,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WasteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF8F9FA);
    canvas.drawRect(Offset.zero & size, background);

    final park = Paint()..color = const Color(0xFFE6F1E8);
    final path = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width * 0.26, size.height * 0.53)
      ..lineTo(size.width * 0.42, size.height * 0.63)
      ..lineTo(size.width * 0.34, size.height * 0.82)
      ..lineTo(0, size.height * 0.88)
      ..close();
    canvas.drawPath(path, park);

    final road = Paint()
      ..color = const Color(0xFFB7C1CB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final thinRoad = Paint()
      ..color = const Color(0xFFD7DCE2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height * 0.30),
      Offset(size.width, size.height * 0.34),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, -20),
      Offset(size.width * 0.72, size.height),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.80, 0),
      Offset(size.width * 0.76, size.height * 0.75),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height),
      Offset(size.width, size.height * 0.90),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.23, size.height * 0.96),
      Offset(size.width * 0.43, size.height * 0.12),
      thinRoad,
    );

    final buildingPaint = Paint()..color = const Color(0xFFE8E8E8);
    final random = math.Random(9);
    for (var i = 0; i < 120; i++) {
      final w = 16 + random.nextDouble() * 30;
      final h = 10 + random.nextDouble() * 38;
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final rect = Rect.fromLTWH(x, y, w, h);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate((random.nextDouble() - .5) * .35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        buildingPaint,
      );
      canvas.restore();
    }

    void heat(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .82),
            color.withValues(alpha: .22),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    heat(Offset(size.width * .30, size.height * .95), 120, Colors.red);
    heat(Offset(size.width * .29, size.height * .92), 90, Colors.yellow);
    heat(Offset(size.width * .39, size.height * .78), 82, Colors.greenAccent);
    heat(Offset(size.width * .50, size.height * .38), 95, Colors.blueAccent);
    heat(Offset(size.width * .83, size.height * .58), 75, Colors.greenAccent);
    heat(Offset(size.width * .35, size.height * .02), 88, Colors.yellow);
    heat(Offset(size.width * .53, size.height * .51), 96, Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImpactLegend extends StatelessWidget {
  const ImpactLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 276,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Tingkat dampak',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.info_outline_rounded, color: kMuted, size: 19),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [
                  Colors.green,
                  Colors.yellow,
                  Colors.orange,
                  Colors.red,
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rendah', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('Tinggi', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class MapSquareButton extends StatelessWidget {
  const MapSquareButton({super.key, required this.icon, this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: label == null ? 78 : 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: label == 'Lokasi saya' ? kCirculGreen : kInk,
            size: 31,
          ),
          if (label != null) ...[
            const SizedBox(height: 7),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class MapMarker extends StatelessWidget {
  const MapMarker({
    super.key,
    required this.label,
    required this.distance,
    required this.color,
    required this.icon,
  });

  final String label;
  final String distance;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_rounded, color: color, size: 44),
        Transform.translate(
          offset: const Offset(-28, -2),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        Transform.translate(
          offset: const Offset(-18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                distance,
                style: const TextStyle(
                  color: kMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LocationBubble extends StatelessWidget {
  const LocationBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Text(
        'Lokasi kamu',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class UserLocationPulse extends StatelessWidget {
  const UserLocationPulse({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0x5534C77B),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x9934C77B), width: 1),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF2EA7FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
      ),
    );
  }
}

class ActivitySheet extends StatelessWidget {
  const ActivitySheet({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSeeAll,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.grid_view_rounded, 'Semua'),
      (Icons.delete_outline_rounded, 'Sampah'),
      (Icons.event_rounded, 'Event'),
      (Icons.campaign_rounded, 'Kampanye'),
      (Icons.more_horiz_rounded, 'Lainnya'),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 66,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C7C7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas di sekitarmu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lihat apa yang sedang terjadi di area ini',
                      style: TextStyle(color: kMuted),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onSeeAll,
                style: FilledButton.styleFrom(
                  backgroundColor: kCirculGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories) ...[
                  ChipButton(
                    icon: category.$1,
                    label: category.$2,
                    selected: selectedCategory == category.$2,
                    onTap: () => onCategoryChanged(category.$2),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: nearbyActivities
                  .where(
                    (item) =>
                        selectedCategory == 'Semua' ||
                        item.category == selectedCategory,
                  )
                  .map((item) => ActivityCard(item: item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              cleanupAsset,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSoftGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: kCirculGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: kCirculGreen,
                      size: 21,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.distance,
                        style: const TextStyle(
                          color: kMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
          ),
          const Icon(Icons.chevron_right_rounded, color: kMuted),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var _selectedTrend = '#sampahplastik';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            'Search',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          const SearchFieldShell(hint: 'Search message, topic, or user'),
          const SizedBox(height: 28),
          Text(
            'Trending',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (final trend in ['#sampahplastik', '#zerowaste'])
                ChoiceChip(
                  selected: _selectedTrend == trend,
                  onSelected: (_) => setState(() => _selectedTrend = trend),
                  avatar: Icon(
                    Icons.trending_up_rounded,
                    color: kCirculGreen,
                    size: 19,
                  ),
                  label: Text(trend),
                  labelStyle: const TextStyle(
                    color: kCirculGreen,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor: kSoftGreen,
                  backgroundColor: const Color(0xFFF1F4F2),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Topik populer',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final topic in topics) TopicRow(topic: topic),
        ],
      ),
    );
  }
}

class TopicRow extends StatelessWidget {
  const TopicRow({super.key, required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F4F2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(topic.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  topic.count,
                  style: const TextStyle(color: kMuted, fontSize: 16),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kMuted, size: 30),
        ],
      ),
    );
  }
}

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  var _selected = 'Semua';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        children: [
          Row(
            children: [
              Text(
                'Event',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              const NotificationIcon(),
            ],
          ),
          const SizedBox(height: 20),
          const SearchFieldShell(hint: 'Cari event, kampanye, atau aksi'),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in [
                  'Semua',
                  'Sampah',
                  'Event',
                  'Kampanye',
                  'Lainnya',
                ]) ...[
                  ChipButton(
                    label: category,
                    selected: _selected == category,
                    onTap: () => setState(() => _selected = category),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final item in nearbyActivities.where(
            (item) => _selected == 'Semua' || item.category == _selected,
          ))
            ActivityCard(item: item),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kSoftGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.add_location_alt_rounded,
                  color: kCirculGreen,
                  size: 34,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Laporkan titik sampah atau buat aksi komunitas baru.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _selectedTab = 'Postingan';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          const CirculHeader(showChat: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SarahAvatar(radius: 72),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarah Mae',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '@sarahmae',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Berusaha hidup lebih berkelanjutan 🌿\nBelajar, berbagi, dan berdampak.',
                        style: TextStyle(fontSize: 17, height: 1.35),
                      ),
                      const SizedBox(height: 22),
                      const Wrap(
                        spacing: 18,
                        runSpacing: 10,
                        children: [
                          ProfileMeta(
                            icon: Icons.location_on_outlined,
                            text: 'Jakarta, Indonesia',
                          ),
                          ProfileMeta(
                            icon: Icons.calendar_today_outlined,
                            text: 'Bergabung Mei 2023',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_square),
                        label: const Text('Edit Profil'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: kInk,
                          side: const BorderSide(color: kLine),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const ProfileStats(),
          SectionTitle(
            title: 'Achievement',
            action: 'Lihat semua',
            onAction: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final achievement in achievements)
                  Expanded(child: AchievementBadge(achievement: achievement)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedProfileTabs(
              selected: _selectedTab,
              onSelected: (value) => setState(() => _selectedTab = value),
            ),
          ),
          if (_selectedTab == 'Postingan')
            FeedPostCard(post: feedPosts.first, compact: true, framed: true)
          else
            ProfilePlaceholder(tab: _selectedTab),
        ],
      ),
    );
  }
}

class ProfileMeta extends StatelessWidget {
  const ProfileMeta({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: kMuted, size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('124', 'Follower'),
      ('198', 'Following'),
      ('23', 'Contributions'),
      ('8', 'Achievement'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[i].$1,
                    style: const TextStyle(
                      color: kCirculGreen,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats[i].$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: kMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (i != stats.length - 1)
              Container(width: 1, height: 54, color: kLine),
          ],
        ],
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: kSoftGreen,
              shape: BoxShape.circle,
              border: Border.all(color: kLine),
            ),
            child: Icon(achievement.icon, color: kCirculGreen, size: 42),
          ),
          const SizedBox(height: 14),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kMuted, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class SegmentedProfileTabs extends StatelessWidget {
  const SegmentedProfileTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Postingan', 'Komentar', 'Disimpan', 'Aktivitas'];
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: InkWell(
                onTap: () => onSelected(tab),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == tab ? kSoftGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: selected == tab ? kCirculGreen : kMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key, required this.tab});

  final String tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, color: kCirculGreen, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$tab Sarah Mae akan tampil di sini.',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
