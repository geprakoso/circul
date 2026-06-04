import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/constants.dart';
import 'notification_icon.dart';

class CirculLogo extends StatelessWidget {
  const CirculLogo({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.circulLogoIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'Circul logo',
    );
  }
}

class CirculFullLogo extends StatelessWidget {
  const CirculFullLogo({super.key, this.height = 38});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.circulFullLogo,
      height: height,
      width: height * 3.17,
      fit: BoxFit.contain,
      semanticLabel: 'Circul',
    );
  }
}

class CirculHeader extends StatelessWidget {
  const CirculHeader({
    super.key,
    this.showChat = true,
    this.title = 'Circul',
    this.primaryAction = const NotificationIcon(),
  });

  final bool showChat;
  final String title;
  final Widget primaryAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
      child: Row(
        children: [
          if (title == 'Circul')
            const CirculFullLogo(height: 42)
          else ...[
            const CirculLogo(size: 44),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: kInk,
              ),
            ),
          ],
          const Spacer(),
          primaryAction,
          if (showChat) ...[
            const SizedBox(width: 14),
            IconButton(
              tooltip: 'Pesan',
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 27),
            ),
          ],
        ],
      ),
    );
  }
}
