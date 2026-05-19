import 'package:flutter/material.dart';

import '../map/widgets/activity_sheet.dart';
import '../mock_data.dart';
import '../shared/chip_button.dart';
import '../shared/notification_icon.dart';
import '../shared/search_field_shell.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  var _selected = 'Semua';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        children: [
          Row(
            children: [
              Text(
                'Event',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              const NotificationIcon(),
            ],
          ),
          const SizedBox(height: 20),
          const SearchFieldShell(hint: 'Cari event, kampanye, atau aksi'),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in [
                  'Semua',
                  'Sampah',
                  'Event',
                  'Kampanye',
                  'Lainnya',
                ]) ...[
                  ChipButton(
                    label: category,
                    selected: _selected == category,
                    onTap: () => setState(() => _selected = category),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final item in nearbyActivities.where(
            (item) => _selected == 'Semua' || item.category == _selected,
          ))
            ActivityCard(item: item),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kSoftGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.add_location_alt_rounded,
                  color: kCirculGreen,
                  size: 34,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Laporkan titik sampah atau buat aksi komunitas baru.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
