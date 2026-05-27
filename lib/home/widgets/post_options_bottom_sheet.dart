import 'package:flutter/material.dart';

import '../../mock_data.dart';
import '../../saved_post_repository.dart';

const _currentUserAuthor = 'sarahmae';

Future<void> showPostOptionsBottomSheet(
  BuildContext context, {
  required FeedPost post,
  SavedPostRepository? savedPostRepository,
  VoidCallback? onPostSaved,
  bool savedTabMode = false,
}) {
  final repository = savedPostRepository ?? SavedPostRepository();

  if (savedTabMode) {
    return _showSavedPostOptionsBottomSheet(
      context,
      post: post,
      repository: repository,
      onDeleted: onPostSaved,
    );
  }

  final isOwnPost = post.author.toLowerCase() == _currentUserAuthor;
  final canEdit = isOwnPost && _isEditablePost(post);

  Future<void> handleSave(BuildContext sheetContext) async {
    SavePostResult result;
    try {
      result = await repository.savePost(post);
    } catch (_) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Postingan gagal disimpan.')),
          );
      }
      return;
    }

    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    onPostSaved?.call();
    if (!context.mounted) return;

    final message = result == SavePostResult.saved
        ? 'Postingan disimpan.'
        : 'Postingan sudah ada di Disimpan.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PostOptionTile(
                icon: Icons.bookmark_border_rounded,
                label: 'Save',
                onTap: () => handleSave(context),
              ),
              if (canEdit)
                _PostOptionTile(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onTap: () => Navigator.of(context).pop(),
                ),
              if (isOwnPost)
                _PostOptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  destructive: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              _PostOptionTile(
                icon: Icons.flag_outlined,
                label: 'Report',
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showSavedPostOptionsBottomSheet(
  BuildContext context, {
  required FeedPost post,
  required SavedPostRepository repository,
  VoidCallback? onDeleted,
}) {
  Future<void> handleDelete(BuildContext sheetContext) async {
    try {
      await repository.deleteSavedPost(post);
    } catch (_) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Postingan gagal dihapus dari Disimpan.'),
            ),
          );
      }
      return;
    }

    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    onDeleted?.call();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Postingan dihapus dari Disimpan.')),
      );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PostOptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                destructive: true,
                onTap: () => handleDelete(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}

bool _isEditablePost(FeedPost post) {
  final createdAt = post.createdAt;
  if (createdAt == null) return false;

  return DateTime.now().difference(createdAt) < const Duration(hours: 1);
}

class _PostOptionTile extends StatelessWidget {
  const _PostOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFDC2626) : kInk;

    return ListTile(
      onTap: onTap,
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: color, size: 25),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
