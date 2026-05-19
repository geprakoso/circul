import 'package:flutter/material.dart';

import '../mock_data.dart';
import '../shared/search_field_shell.dart';
import 'widgets/topic_row.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var _selectedTrend = '#sampahplastik';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(
            'Search',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 26),
          const SearchFieldShell(hint: 'Search message, topic, or user'),
          const SizedBox(height: 28),
          Text(
            'Trending',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (final trend in ['#sampahplastik', '#zerowaste'])
                ChoiceChip(
                  selected: _selectedTrend == trend,
                  onSelected: (_) => setState(() => _selectedTrend = trend),
                  avatar: Icon(
                    Icons.trending_up_rounded,
                    color: kCirculGreen,
                    size: 19,
                  ),
                  label: Text(trend),
                  labelStyle: const TextStyle(
                    color: kCirculGreen,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor: kSoftGreen,
                  backgroundColor: const Color(0xFFF1F4F2),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Topik populer',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final topic in topics) TopicRow(topic: topic),
        ],
      ),
    );
  }
}
