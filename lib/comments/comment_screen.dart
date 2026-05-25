import 'package:flutter/material.dart';

import '../comment_repository.dart';
import '../home/widgets/feed_post_card.dart';
import '../mock_data.dart';
import '../new_post/widgets/attachment_media_strip.dart';

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key, required this.post, this.commentRepository});

  final FeedPost post;
  final CommentRepository? commentRepository;

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _controller = TextEditingController();
  late final CommentRepository _repository;
  late Future<List<PostComment>> _commentsFuture;
  var _isSubmitting = false;

  bool get _canSend => !_isSubmitting && _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repository = widget.commentRepository ?? CommentRepository();
    _commentsFuture = _repository.getComments(widget.post);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (!_canSend) return;

    setState(() => _isSubmitting = true);
    PostComment? savedComment;
    try {
      savedComment = await _repository.addComment(
        post: widget.post,
        body: text,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komentar gagal disimpan lokal.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted || savedComment == null) return;
    _controller.clear();
    setState(() => _commentsFuture = _repository.getComments(widget.post));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _CommentHeader(onBack: () => Navigator.of(context).pop()),
            const Divider(height: 1, color: kLine),
            Expanded(
              child: FutureBuilder<List<PostComment>>(
                future: _commentsFuture,
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? const <PostComment>[];

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      FeedPostCard(post: widget.post),
                      const Divider(height: 1, color: kLine),
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          comments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                          child: Text(
                            'Komentar belum bisa dibuka.',
                            style: TextStyle(
                              color: kInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      else
                        for (final comment in comments)
                          CommentTile(comment: comment),
                    ],
                  );
                },
              ),
            ),
            _CommentComposer(
              controller: _controller,
              canSend: _canSend,
              onSend: _submitComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentHeader extends StatelessWidget {
  const _CommentHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Kembali',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kInk,
              size: 22,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Komentar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: kInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Lainnya',
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Color(0xFF4B5563),
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  const CommentTile({super.key, required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kLine)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(comment: comment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const _Dot(),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        color: kMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (comment.locationEnabled) ...[
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return LocationPlaceholderBox(
                        enabled: true,
                        loading: false,
                        width: constraints.maxWidth,
                        label: comment.locationLabel,
                        coordinateLabel: comment.coordinateLabel,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sukai komentar',
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFF7D828C),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: comment.avatarColor,
      child: Text(
        comment.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Give your response',
                  hintStyle: TextStyle(
                    color: Color(0xFF7F7F7F),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Kirim komentar',
            onPressed: canSend ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFDADADA),
              disabledBackgroundColor: const Color(0xFFDADADA),
              foregroundColor: const Color(0xFF7D828C),
              disabledForegroundColor: const Color(0xFF9B9B9B),
              minimumSize: const Size.square(48),
            ),
            icon: const Icon(Icons.send_outlined, size: 24),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}
