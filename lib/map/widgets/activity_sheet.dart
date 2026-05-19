import 'package:flutter/material.dart';

import '../../mock_data.dart';
import '../../shared/chip_button.dart';

class ActivitySheet extends StatelessWidget {
  const ActivitySheet({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSeeAll,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final categories = [
      (Icons.grid_view_rounded, 'Semua'),
      (Icons.delete_outline_rounded, 'Sampah'),
      (Icons.event_rounded, 'Event'),
      (Icons.campaign_rounded, 'Kampanye'),
      (Icons.more_horiz_rounded, 'Lainnya'),
    ];

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 66,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFC7C7C7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktivitas di sekitarmu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lihat apa yang sedang terjadi di area ini',
                      style: TextStyle(color: kMuted),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onSeeAll,
                style: FilledButton.styleFrom(
                  backgroundColor: kCirculGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in categories) ...[
                  ChipButton(
                    icon: category.$1,
                    label: category.$2,
                    selected: selectedCategory == category.$2,
                    onTap: () => onCategoryChanged(category.$2),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: nearbyActivities
                  .where(
                    (item) =>
                        selectedCategory == 'Semua' ||
                        item.category == selectedCategory,
                  )
                  .map((item) => ActivityCard(item: item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              cleanupAsset,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kSoftGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      color: kCirculGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: kCirculGreen,
                      size: 21,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.distance,
                        style: const TextStyle(
                          color: kMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
          ),
          const Icon(Icons.chevron_right_rounded, color: kMuted),
        ],
      ),
    );
  }
}
