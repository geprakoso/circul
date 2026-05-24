import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../check_in/capture_result_screen.dart';
import '../comments/comment_screen.dart';
import '../feed_post_repository.dart';
import '../mock_data.dart';
import '../new_post/new_post_screen.dart';
import '../shared/shared_widgets.dart';
import 'widgets/feed_post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.feedPostRepository,
    this.onDownCheckIn,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker;

  final FeedPostRepository? feedPostRepository;
  final ValueChanged<LatLng>? onDownCheckIn;
  final ImagePicker? _imagePicker;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FeedPostRepository _repository;
  late Future<List<FeedPost>> _postsFuture;
  late final ImagePicker _imagePicker;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _postsFuture = _repository.getPosts();
    _imagePicker = widget._imagePicker ?? ImagePicker();
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

  void _openComments(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => CommentScreen(post: post)),
    );
  }

  Future<void> _openCheckInCamera() async {
    if (Platform.isMacOS) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => CaptureResultScreen(
            useDummyCapture: true,
            onDownSelected: widget.onDownCheckIn,
          ),
        ),
      );
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 1800,
      );
      if (!mounted || image == null) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => CaptureResultScreen(
            imagePath: image.path,
            onDownSelected: widget.onDownCheckIn,
          ),
        ),
      );
    } on PlatformException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Kamera belum bisa dibuka.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          FutureBuilder<List<FeedPost>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              final posts = snapshot.data ?? const <FeedPost>[];

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 104),
                  children: [
                    _HomeHeader(onComposeTap: _openComposer),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Text(
                        'Database lokal belum bisa dibuka.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  posts.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 104),
                  children: [
                    _HomeHeader(onComposeTap: _openComposer),
                    const SizedBox(height: 28),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 104),
                itemCount: posts.length + 1,
                separatorBuilder: (context, index) {
                  if (index < 1) return const SizedBox.shrink();
                  return const Divider(
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                    color: kLine,
                  );
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _HomeHeader(onComposeTap: _openComposer);
                  }

                  final post = posts[index - 1];
                  return FeedPostCard(
                    post: post,
                    onOpenComments: () => _openComments(post),
                  );
                },
              );
            },
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: _HomeCheckInButton(onTap: _openCheckInCamera),
          ),
        ],
      ),
    );
  }
}

class _HomeCheckInButton extends StatelessWidget {
  const _HomeCheckInButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Check-in',
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        elevation: 6,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: const SizedBox(
            width: 64,
            height: 64,
            child: Icon(
              Icons.add_location_alt_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: Row(
            children: [
              const SarahAvatar(radius: 25, showAddBadge: true),
              const SizedBox(width: 14),
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
      height: 48,
      horizontalPadding: 16,
      iconSize: 23,
      borderRadius: 24,
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: kMuted,
        fontWeight: FontWeight.w500,
      ),
      onTap: onTap,
    );
  }
}
