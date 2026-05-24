import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'event/event_screen.dart';
import 'feed_post_repository.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'mock_data.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'shared/relative_timestamp.dart';
import 'shared/sarah_avatar.dart';

void main() {
  runApp(const CirculApp());
}

class CirculApp extends StatelessWidget {
  const CirculApp({super.key, this.feedPostRepository});

  final FeedPostRepository? feedPostRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kCirculGreen,
          primary: kCirculGreen,
          surface: Colors.white,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: kInk,
          displayColor: kInk,
          fontFamily: 'SF Pro Display',
        ),
      ),
      home: CirculShell(feedPostRepository: feedPostRepository),
    );
  }
}

class CirculShell extends StatefulWidget {
  const CirculShell({super.key, this.feedPostRepository});

  final FeedPostRepository? feedPostRepository;

  @override
  State<CirculShell> createState() => _CirculShellState();
}

class _CirculShellState extends State<CirculShell> {
  var _index = 0;
  var _homeRefreshToken = 0;
  var _mapCurrentLocationRefreshToken = 0;
  MapFocusedCheckIn? _focusedCheckIn;
  final _issueClusters = <MapIssueCluster>[];

  void _recordHeatmapLevel(LatLng point, {required bool showMap}) {
    setState(() {
      final clusterIndex = _issueClusters.indexWhere(
        (cluster) => MapScreen.distanceMeters(cluster.point, point) <= 75,
      );

      if (clusterIndex == -1) {
        _issueClusters.add(MapIssueCluster(point: point));
      } else {
        final cluster = _issueClusters[clusterIndex];
        final nextCount = cluster.count + 1;
        _issueClusters[clusterIndex] = cluster.copyWith(
          point: LatLng(
            (cluster.point.latitude * cluster.count + point.latitude) /
                nextCount,
            (cluster.point.longitude * cluster.count + point.longitude) /
                nextCount,
          ),
          count: nextCount,
        );
      }

      if (showMap) _index = 1;
    });
  }

  void _addHeatmapLevel(LatLng point) {
    _recordHeatmapLevel(point, showMap: true);
  }

  void _addHomeCheckInHeatmapLevel(LatLng point) {
    _recordHeatmapLevel(point, showMap: false);
  }

  void _refreshHomePosts() {
    setState(() => _homeRefreshToken++);
  }

  void _openPostLocationOnMap(FeedPost post) {
    final point = post.locationPoint;
    if (point == null) return;

    setState(() {
      _focusedCheckIn = MapFocusedCheckIn(
        id: DateTime.now().microsecondsSinceEpoch,
        point: point,
        label: post.locationLabel ?? post.city,
        coordinateLabel: post.coordinateLabel,
        caption: post.body,
        author: post.author,
        timeLabel: post.createdAt == null
            ? post.timeAgo
            : formatRelativeTimestamp(post.createdAt!),
        imageAsset: post.imageAsset,
        imagePaths: post.imagePaths,
      );
      _index = 1;
    });
  }

  void _handleTabChanged(int index) {
    setState(() {
      _index = index;
      if (index == 1) {
        _focusedCheckIn = null;
        _mapCurrentLocationRefreshToken++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        feedPostRepository: widget.feedPostRepository,
        onDownCheckIn: _addHomeCheckInHeatmapLevel,
        onOpenLocationPost: _openPostLocationOnMap,
        refreshToken: _homeRefreshToken,
      ),
      MapScreen(
        issueClusters: _issueClusters,
        feedPostRepository: widget.feedPostRepository,
        onDownCheckIn: _addHeatmapLevel,
        onPostCreated: _refreshHomePosts,
        focusedCheckIn: _focusedCheckIn,
        currentLocationRefreshToken: _mapCurrentLocationRefreshToken,
      ),
      const SearchScreen(),
      const EventScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: CirculBottomNav(
        selectedIndex: _index,
        onChanged: _handleTabChanged,
      ),
    );
  }
}

class CirculBottomNav extends StatelessWidget {
  const CirculBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(Icons.flag_outlined, Icons.flag_rounded, 'Peta'),
      _NavItem(Icons.search_rounded, Icons.search_rounded, 'Cari'),
      _NavItem(
        Icons.calendar_today_outlined,
        Icons.calendar_month_rounded,
        'Event',
      ),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kLine)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _BottomNavButton(
                  item: items[i],
                  selected: selectedIndex == i,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? kCirculGreen : kMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.label == 'Profil')
              const SarahAvatar(radius: 18)
            else
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 31,
              ),
            const SizedBox(height: 5),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
