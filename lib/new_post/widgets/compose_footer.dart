import 'package:flutter/material.dart';

class ComposeFooter extends StatelessWidget {
  const ComposeFooter({
    super.key,
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
      minimum: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;

          return Row(
            children: [
              if (compact)
                IconButton(
                  tooltip: 'Opsi posting',
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF9B9EA2),
                    size: 23,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  label: const Text('Opsi posting'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9B9EA2),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(),
              ReplyToggle(
                value: allowReplies,
                onChanged: onAllowRepliesChanged,
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: canPost ? onPost : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(84, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF2B2D2F),
                  disabledForegroundColor: const Color(0xFF151719),
                  textStyle: const TextStyle(
                    fontSize: 15,
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

class ReplyToggle extends StatelessWidget {
  const ReplyToggle({super.key, required this.value, required this.onChanged});

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
          width: 62,
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF3A3D40) : const Color(0xFF242628),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF33363A)),
          ),
          child: Align(
            alignment: value ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF111315),
                shape: BoxShape.circle,
              ),
              child: Icon(
                value ? Icons.public_rounded : Icons.lock_outline_rounded,
                color: const Color(0xFF7C8085),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
