import 'package:flutter/material.dart';

import '../../mock_data.dart';

class TopicRow extends StatelessWidget {
  const TopicRow({super.key, required this.topic, this.onTap});

  final Topic topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kMuted,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
