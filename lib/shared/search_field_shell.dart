import 'package:flutter/material.dart';

import '../core/constants.dart';

class SearchFieldShell extends StatelessWidget {
  const SearchFieldShell({
    super.key,
    required this.hint,
    this.icon = Icons.search_rounded,
    this.onTap,
    this.height = 60,
    this.horizontalPadding = 22,
    this.iconSize = 30,
    this.borderRadius = 32,
    this.textStyle,
  });

  final String hint;
  final IconData icon;
  final VoidCallback? onTap;
  final double height;
  final double horizontalPadding;
  final double iconSize;
  final double borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Icon(icon, color: kMuted, size: iconSize),
          SizedBox(width: height <= 48 ? 10 : 14),
          Expanded(
            child: Text(
              hint,
              style:
                  textStyle ??
                  Theme.of(context).textTheme.titleMedium?.copyWith(
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
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}
