import 'package:flutter/material.dart';

import '../home/widgets/feed_post_card.dart';
import '../mock_data.dart';
import '../shared/shared_widgets.dart';
import 'widgets/achievement_badge.dart';
import 'widgets/profile_meta.dart';
import 'widgets/profile_placeholder.dart';
import 'widgets/profile_stats.dart';
import 'widgets/segmented_profile_tabs.dart';

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
