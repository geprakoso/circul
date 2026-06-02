import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'event/event_screen.dart';
import 'feed_post_repository.dart';
import 'home/home_screen.dart';
import 'liked_post_repository.dart';
import 'map/map_screen.dart';
import 'mock_data.dart';
import 'profile/editable_profile.dart';
import 'profile/profile_screen.dart';
import 'saved_post_repository.dart';
import 'search/search_screen.dart';
import 'shared/relative_timestamp.dart';
import 'shared/sarah_avatar.dart';
import 'user_repository.dart';
import 'welcome/welcome_flow.dart';

void main() {
  runApp(const CirculApp());
}

class CirculApp extends StatelessWidget {
  const CirculApp({
    super.key,
    this.feedPostRepository,
    this.savedPostRepository,
    this.likedPostRepository,
    this.userRepository,
  });

  final FeedPostRepository? feedPostRepository;
  final SavedPostRepository? savedPostRepository;
  final LikedPostRepository? likedPostRepository;
  final UserRepository? userRepository;

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
      home: CirculShell(
        feedPostRepository: feedPostRepository,
        savedPostRepository: savedPostRepository,
        likedPostRepository: likedPostRepository,
        userRepository: userRepository,
      ),
    );
  }
}

class CirculShell extends StatefulWidget {
  const CirculShell({
    super.key,
    this.feedPostRepository,
    this.savedPostRepository,
    this.likedPostRepository,
    this.userRepository,
  });

  final FeedPostRepository? feedPostRepository;
  final SavedPostRepository? savedPostRepository;
  final LikedPostRepository? likedPostRepository;
  final UserRepository? userRepository;

  @override
  State<CirculShell> createState() => _CirculShellState();
}

class _CirculShellState extends State<CirculShell> {
  var _index = 0;
  var _homeRefreshToken = 0;
  var _profileRefreshToken = 0;
  var _mapCurrentLocationRefreshToken = 0;
  var _searchResetToken = 0;
  var _currentUserProfile = UserRepository.defaultProfile;
  MapFocusedCheckIn? _focusedCheckIn;
  final _issueClusters = <MapIssueCluster>[];
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _userRepository = widget.userRepository ?? UserRepository();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final profile = await _userRepository.getCurrentUserProfile();
      if (!mounted) return;
      setState(() => _currentUserProfile = profile);
    } catch (_) {
      // Keep the bundled profile if local persistence cannot be read yet.
    }
  }

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

  void _removeHeatmapLevel(LatLng point) {
    setState(() {
      final clusterIndex = _issueClusters.indexWhere(
        (cluster) => MapScreen.distanceMeters(cluster.point, point) <= 75,
      );
      if (clusterIndex == -1) return;

      final cluster = _issueClusters[clusterIndex];
      if (cluster.count <= 1) {
        _issueClusters.removeAt(clusterIndex);
      } else {
        _issueClusters[clusterIndex] = cluster.copyWith(
          count: cluster.count - 1,
        );
      }
    });
  }

  void _refreshPostConsumers() {
    setState(() {
      _homeRefreshToken++;
      _profileRefreshToken++;
    });
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
        author: _isCurrentUserPost(post)
            ? _currentUserProfile.username
            : post.author,
        authorImagePath: _isCurrentUserPost(post)
            ? _currentUserProfile.imagePath
            : null,
        timeLabel: post.createdAt == null
            ? post.timeAgo
            : formatRelativeTimestamp(post.createdAt!),
        imageAsset: post.imageAsset,
        imagePaths: post.imagePaths,
      );
      _index = 1;
    });
  }

  bool _isCurrentUserPost(FeedPost post) {
    return post.author.toLowerCase() == 'sarahmae' ||
        post.author.toLowerCase() == _currentUserProfile.username.toLowerCase();
  }

  void _handleProfileUpdated(EditableProfile profile) {
    setState(() {
      _currentUserProfile = profile;
      _homeRefreshToken++;
      _profileRefreshToken++;
    });
  }

  void _handleTabChanged(int index) {
    setState(() {
      if (index == 2 && _index == 2) {
        _searchResetToken++;
      }
      _index = index;
      if (index == 1) {
        _focusedCheckIn = null;
        _mapCurrentLocationRefreshToken++;
      } else if (index == 4) {
        _profileRefreshToken++;
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
        onPostCreated: _refreshPostConsumers,
        onPostUpdated: _refreshPostConsumers,
        savedPostRepository: widget.savedPostRepository,
        onPostSaved: _refreshPostConsumers,
        likedPostRepository: widget.likedPostRepository,
        onPostLiked: _refreshPostConsumers,
        refreshToken: _homeRefreshToken,
        currentUserProfile: _currentUserProfile,
      ),
      MapScreen(
        issueClusters: _issueClusters,
        feedPostRepository: widget.feedPostRepository,
        onDownCheckIn: _addHeatmapLevel,
        onPostCreated: _refreshPostConsumers,
        onCheckoutCompleted: _removeHeatmapLevel,
        focusedCheckIn: _focusedCheckIn,
        currentLocationRefreshToken: _mapCurrentLocationRefreshToken,
        currentUserProfile: _currentUserProfile,
      ),
      SearchScreen(
        feedPostRepository: widget.feedPostRepository,
        savedPostRepository: widget.savedPostRepository,
        likedPostRepository: widget.likedPostRepository,
        onPostUpdated: _refreshPostConsumers,
        onPostSaved: _refreshPostConsumers,
        onPostLiked: _refreshPostConsumers,
        resetToken: _searchResetToken,
        currentUserProfile: _currentUserProfile,
      ),
      const EventScreen(),
      ProfileScreen(
        feedPostRepository: widget.feedPostRepository,
        savedPostRepository: widget.savedPostRepository,
        likedPostRepository: widget.likedPostRepository,
        onPostUpdated: _refreshPostConsumers,
        profile: _currentUserProfile,
        userRepository: _userRepository,
        onProfileUpdated: _handleProfileUpdated,
        refreshToken: _profileRefreshToken,
        onOpenWelcomeFlow: _openWelcomeFlow,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: CirculBottomNav(
        selectedIndex: _index,
        onChanged: _handleTabChanged,
        currentUserProfile: _currentUserProfile,
      ),
    );
  }

  void _openWelcomeFlow() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) =>
            WelcomeFlow(onComplete: () => Navigator.of(routeContext).pop()),
      ),
    );
  }
}

class CirculBottomNav extends StatelessWidget {
  const CirculBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.currentUserProfile,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EditableProfile? currentUserProfile;

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
        height: 72,
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
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
                  currentUserProfile: currentUserProfile,
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
    this.currentUserProfile,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final EditableProfile? currentUserProfile;

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
        child: Center(
          child: item.label == 'Profil'
              ? _NavProfileAvatar(profile: currentUserProfile)
              : Icon(
                  selected ? item.activeIcon : item.icon,
                  color: color,
                  size: 31,
                ),
        ),
      ),
    );
  }
}

class _NavProfileAvatar extends StatelessWidget {
  const _NavProfileAvatar({this.profile});

  final EditableProfile? profile;

  @override
  Widget build(BuildContext context) {
    final imagePath = profile?.imagePath;
    if (imagePath == null || imagePath.trim().isEmpty) {
      return const SarahAvatar(radius: 18);
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE5E7EB),
      child: ClipOval(
        child: Image.file(
          File(imagePath),
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const SarahAvatar(radius: 18),
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
