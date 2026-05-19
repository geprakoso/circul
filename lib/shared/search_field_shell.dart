import 'package:flutter/material.dart';

import '../core/constants.dart';

class SearchFieldShell extends StatelessWidget {
  const SearchFieldShell({
    super.key,
    required this.hint,
    this.icon = Icons.search_rounded,
    this.onTap,
  });

  final String hint;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Icon(icon, color: kMuted, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hint,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: kMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: content,
      ),
    );
  }
}
