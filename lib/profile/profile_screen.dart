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
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SarahAvatar(radius: 56),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarah Mae',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '@sarahmae',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Berusaha hidup lebih berkelanjutan 🌿\nBelajar, berbagi, dan berdampak.',
                        style: TextStyle(fontSize: 15, height: 1.35),
                      ),
                      const SizedBox(height: 16),
                      const Wrap(
                        spacing: 14,
                        runSpacing: 8,
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
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_square),
                        label: const Text('Edit Profil'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
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
