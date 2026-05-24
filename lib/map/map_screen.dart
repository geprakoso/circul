import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../check_in/capture_result_screen.dart';
import '../feed_post_repository.dart';
import '../mock_data.dart';
import '../shared/relative_timestamp.dart';

const _gondangManisCenter = LatLng(-7.5584, 110.8199);
const _osmTileTemplate = String.fromEnvironment(
  'OSM_TILE_URL_TEMPLATE',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);
const _osmUserAgentPackageName = String.fromEnvironment(
  'OSM_USER_AGENT_PACKAGE_NAME',
  defaultValue: 'com.example.circul',
);

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.issueClusters = const [],
    this.onDownCheckIn,
    this.feedPostRepository,
    this.onPostCreated,
    this.focusedCheckIn,
    this.currentLocationRefreshToken = 0,
  });

  final List<MapIssueCluster> issueClusters;
  final ValueChanged<LatLng>? onDownCheckIn;
  final FeedPostRepository? feedPostRepository;
  final VoidCallback? onPostCreated;
  final MapFocusedCheckIn? focusedCheckIn;
  final int currentLocationRefreshToken;

  static double distanceMeters(LatLng first, LatLng second) {
    return const Distance().as(LengthUnit.Meter, first, second);
  }

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  static const _visibleBoundsRefreshDelay = Duration(milliseconds: 280);

  final _mapController = MapController();
  late final AnimationController _cameraAnimationController;
  late final FeedPostRepository _repository;
  var _currentLocation = _gondangManisCenter;
  var _isLocating = false;
  var _isResolvingLocation = false;
  var _flagMenuExpanded = false;
  var _feedCheckIns = <FeedPost>[];
  DateTime? _lastResolvedLocationAt;
  Timer? _visibleBoundsRefreshTimer;
  LatLngBounds? _visibleBounds;

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadFeedCheckIns();
  }

  @override
  void dispose() {
    _visibleBoundsRefreshTimer?.cancel();
    _cameraAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusedCheckIn = widget.focusedCheckIn;
    if (focusedCheckIn != null &&
        focusedCheckIn.id != oldWidget.focusedCheckIn?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _flagMenuExpanded = false);
        _animateMapTo(focusedCheckIn.point, 17);
      });
    }

    if (widget.currentLocationRefreshToken !=
        oldWidget.currentLocationRefreshToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadFeedCheckIns();
        _centerToCurrentLocation(
          preferLastKnown: true,
          showErrors: false,
          showLoading: false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleCheckIns = _visibleCheckIns();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _gondangManisCenter,
            initialZoom: 16,
            minZoom: 12,
            maxZoom: 19,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onMapReady: _syncVisibleBounds,
            onPositionChanged: _scheduleVisibleBoundsSync,
          ),
          children: [
            TileLayer(
              urlTemplate: _osmTileTemplate,
              userAgentPackageName: _osmUserAgentPackageName,
              maxNativeZoom: 19,
            ),
            CircleLayer(circles: _clusterGlows(widget.issueClusters)),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 54,
                  height: 54,
                  child: const _CurrentLocationMarker(),
                ),
                for (final activity in _mapActivities)
                  Marker(
                    point: activity.point,
                    width: 42,
                    height: 42,
                    alignment: Alignment.topCenter,
                    child: _ActivityMarker(activity: activity),
                  ),
                for (final post in _feedCheckIns)
                  if (post.locationPoint case final point?)
                    Marker(
                      point: point,
                      width: 46,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: const _FeedPostCheckInMarker(),
                    ),
                for (final cluster in widget.issueClusters)
                  Marker(
                    point: cluster.point,
                    width: _clusterMarkerSizeForCount(cluster.count) + 8,
                    height: _clusterMarkerSizeForCount(cluster.count) + 8,
                    child: _IssueQuantityMarker(cluster: cluster),
                  ),
                if (widget.focusedCheckIn case final focusedCheckIn?)
                  Marker(
                    point: focusedCheckIn.point,
                    width: 58,
                    height: 58,
                    alignment: Alignment.topCenter,
                    child: const _FocusedCheckInMarker(),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 192,
          child: _LocateButton(
            isLoading: _isLocating,
            onPressed: () => _centerToCurrentLocation(),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 252,
          child: _FlagActionMenu(
            expanded: _flagMenuExpanded,
            onToggle: () =>
                setState(() => _flagMenuExpanded = !_flagMenuExpanded),
            onCheckIn: _openCaptureResult,
            onCheckOut: () => _showLocationMessage('Check-out dipilih.'),
          ),
        ),
        _CheckInBottomSheet(
          items: visibleCheckIns,
          onItemTap: (item) => _animateMapTo(item.point, 17),
        ),
      ],
    );
  }

  Future<void> _loadFeedCheckIns() async {
    try {
      final posts = await _repository.getPosts();
      if (!mounted) return;

      setState(() {
        _feedCheckIns = posts
            .where((post) => post.locationEnabled && post.locationPoint != null)
            .toList(growable: false);
      });
    } catch (_) {
      if (mounted) setState(() => _feedCheckIns = const []);
    }
  }

  void _syncVisibleBounds([MapCamera? camera]) {
    _visibleBoundsRefreshTimer?.cancel();
    final nextBounds =
        camera?.visibleBounds ?? _mapController.camera.visibleBounds;
    if (!mounted) return;
    setState(() => _visibleBounds = nextBounds);
  }

  void _scheduleVisibleBoundsSync(MapCamera camera, bool hasGesture) {
    _visibleBoundsRefreshTimer?.cancel();
    _visibleBoundsRefreshTimer = Timer(_visibleBoundsRefreshDelay, () {
      _syncVisibleBounds(camera);
    });
  }

  List<_VisibleCheckIn> _visibleCheckIns() {
    final bounds = _visibleBounds;
    final focusedCheckIn = widget.focusedCheckIn;
    final distanceAnchor = focusedCheckIn?.point ?? _currentLocation;
    final items = <_VisibleCheckIn>[
      if (focusedCheckIn != null)
        _VisibleCheckIn.fromFocusedCheckIn(
          focusedCheckIn: focusedCheckIn,
          currentLocation: distanceAnchor,
        ),
      for (final post in _feedCheckIns)
        if (post.locationPoint case final point?)
          _VisibleCheckIn.fromFeedPost(
            post: post,
            point: point,
            currentLocation: distanceAnchor,
          ),
      for (var i = 0; i < widget.issueClusters.length; i++)
        _VisibleCheckIn.fromCluster(
          cluster: widget.issueClusters[i],
          index: i,
          currentLocation: distanceAnchor,
        ),
      for (var i = 0; i < _impactSpots.length; i++)
        _VisibleCheckIn.fromImpactSpot(
          spot: _impactSpots[i],
          index: i,
          currentLocation: distanceAnchor,
        ),
    ];

    final visibleItems = bounds == null
        ? items
        : items.where((item) {
            return item.isFocused || bounds.contains(item.point);
          }).toList();

    visibleItems.sort(
      (first, second) => first.distanceMeters.compareTo(second.distanceMeters),
    );
    return visibleItems;
  }

  Future<void> _centerToCurrentLocation({
    bool preferLastKnown = false,
    bool showErrors = true,
    bool showLoading = true,
  }) async {
    if (_isResolvingLocation) return;

    final lastResolvedLocationAt = _lastResolvedLocationAt;
    final hasFreshLocation =
        lastResolvedLocationAt != null &&
        DateTime.now().difference(lastResolvedLocationAt) <
            const Duration(minutes: 2);
    if (preferLastKnown && hasFreshLocation) {
      _animateMapTo(_currentLocation, 17);
      return;
    }

    setState(() {
      _isResolvingLocation = true;
      _isLocating = showLoading;
    });

    try {
      final permissionGranted = await _ensureLocationPermission(
        showErrors: showErrors,
      );
      if (!permissionGranted) return;

      if (preferLastKnown) {
        final lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null && mounted) {
          _applyCurrentLocation(lastKnownPosition, animate: true);
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: preferLastKnown
              ? LocationAccuracy.medium
              : LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) _applyCurrentLocation(position, animate: true);
    } catch (_) {
      if (!mounted) return;
      if (showErrors) {
        _showLocationMessage('Tidak bisa mengambil lokasi saat ini.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
          _isLocating = false;
        });
      }
    }
  }

  void _applyCurrentLocation(Position position, {required bool animate}) {
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentLocation = point;
      _lastResolvedLocationAt = DateTime.now();
    });
    if (animate) _animateMapTo(point, 17);
  }

  Future<bool> _ensureLocationPermission({bool showErrors = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted && showErrors) {
        _showLocationMessage(
          'Aktifkan layanan lokasi untuk memakai tombol ini.',
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted && showErrors) {
        _showLocationMessage('Izin lokasi belum diberikan.');
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted && showErrors) {
        _showLocationMessage(
          'Izin lokasi diblokir. Ubah lewat pengaturan app.',
        );
      }
      return false;
    }

    return true;
  }

  void _showLocationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCaptureResult() async {
    setState(() => _flagMenuExpanded = false);
    final didPost = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => CaptureResultScreen(
          feedPostRepository: widget.feedPostRepository,
          onDownSelected: widget.onDownCheckIn,
        ),
      ),
    );
    if (didPost != true) return;
    await _loadFeedCheckIns();
    widget.onPostCreated?.call();
  }

  void _animateMapTo(LatLng center, double zoom) {
    _cameraAnimationController.stop();

    final centerAnimation =
        _LatLngTween(begin: _mapController.camera.center, end: center).animate(
          CurvedAnimation(
            parent: _cameraAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
    final zoomAnimation =
        Tween<double>(begin: _mapController.camera.zoom, end: zoom).animate(
          CurvedAnimation(
            parent: _cameraAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    void moveCamera() {
      _mapController.move(centerAnimation.value, zoomAnimation.value);
    }

    _cameraAnimationController
      ..addListener(moveCamera)
      ..forward(from: 0).whenCompleteOrCancel(() {
        _cameraAnimationController.removeListener(moveCamera);
      });
  }
}

class MapFocusedCheckIn {
  const MapFocusedCheckIn({
    required this.id,
    required this.point,
    required this.label,
    this.coordinateLabel,
    this.caption,
    this.author = 'sarahmae',
    this.timeLabel = 'Baru saja',
    this.imageAsset = '',
    this.imagePaths = const [],
  });

  final int id;
  final LatLng point;
  final String label;
  final String? coordinateLabel;
  final String? caption;
  final String author;
  final String timeLabel;
  final String imageAsset;
  final List<String> imagePaths;
}

class MapIssueCluster {
  const MapIssueCluster({
    required this.point,
    this.count = 1,
    this.radiusMeters = 68,
  });

  final LatLng point;
  final int count;
  final double radiusMeters;

  MapIssueCluster copyWith({LatLng? point, int? count, double? radiusMeters}) {
    return MapIssueCluster(
      point: point ?? this.point,
      count: count ?? this.count,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}

class _VisibleCheckIn {
  const _VisibleCheckIn({
    required this.point,
    required this.author,
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.color,
    required this.icon,
    required this.distanceMeters,
    this.imageAsset = '',
    this.imagePaths = const [],
    this.isFocused = false,
  });

  factory _VisibleCheckIn.fromFocusedCheckIn({
    required MapFocusedCheckIn focusedCheckIn,
    required LatLng currentLocation,
  }) {
    final distanceMeters = MapScreen.distanceMeters(
      currentLocation,
      focusedCheckIn.point,
    );

    return _VisibleCheckIn(
      point: focusedCheckIn.point,
      author: focusedCheckIn.author,
      timeLabel: focusedCheckIn.timeLabel,
      title: focusedCheckIn.label,
      subtitle: focusedCheckIn.caption ?? 'Submitted check-in',
      meta: focusedCheckIn.coordinateLabel ?? _distanceLabel(distanceMeters),
      color: kCirculGreen,
      icon: Icons.flag_rounded,
      distanceMeters: distanceMeters,
      imageAsset: focusedCheckIn.imageAsset,
      imagePaths: focusedCheckIn.imagePaths,
      isFocused: true,
    );
  }

  factory _VisibleCheckIn.fromFeedPost({
    required FeedPost post,
    required LatLng point,
    required LatLng currentLocation,
  }) {
    final distanceMeters = MapScreen.distanceMeters(currentLocation, point);
    final timestamp = post.createdAt == null
        ? post.timeAgo
        : formatRelativeTimestamp(post.createdAt!);

    return _VisibleCheckIn(
      point: point,
      author: post.author,
      timeLabel: timestamp,
      title: post.locationLabel ?? post.city,
      subtitle: post.body,
      meta: _distanceLabel(distanceMeters),
      color: kCirculGreen,
      icon: Icons.flag_rounded,
      distanceMeters: distanceMeters,
      imageAsset: post.imageAsset,
      imagePaths: post.imagePaths,
    );
  }

  factory _VisibleCheckIn.fromCluster({
    required MapIssueCluster cluster,
    required int index,
    required LatLng currentLocation,
  }) {
    final distanceMeters = MapScreen.distanceMeters(
      currentLocation,
      cluster.point,
    );

    return _VisibleCheckIn(
      point: cluster.point,
      author: 'Circul',
      timeLabel: _distanceLabel(distanceMeters),
      title: cluster.count == 1
          ? 'Check-in lingkungan turun'
          : '${cluster.count} check-in lingkungan turun',
      subtitle: 'Butuh perhatian komunitas',
      meta: _distanceLabel(distanceMeters),
      color: _clusterColorForCount(cluster.count),
      icon: Icons.flag_rounded,
      distanceMeters: distanceMeters,
    );
  }

  factory _VisibleCheckIn.fromImpactSpot({
    required _ImpactSpot spot,
    required int index,
    required LatLng currentLocation,
  }) {
    final distanceMeters = MapScreen.distanceMeters(
      currentLocation,
      spot.point,
    );
    final intensityPercent = (spot.intensity * 100).round();

    return _VisibleCheckIn(
      point: spot.point,
      author: 'Circul',
      timeLabel: _distanceLabel(distanceMeters),
      title: 'Titik check-in #${index + 1}',
      subtitle: 'Aktivitas terdeteksi di area map',
      meta: '${_distanceLabel(distanceMeters)} • $intensityPercent%',
      color: _heatmapColorForIntensity(spot.intensity),
      icon: Icons.place_rounded,
      distanceMeters: distanceMeters,
    );
  }

  final LatLng point;
  final String author;
  final String timeLabel;
  final String title;
  final String subtitle;
  final String meta;
  final Color color;
  final IconData icon;
  final double distanceMeters;
  final String imageAsset;
  final List<String> imagePaths;
  final bool isFocused;

  int get imageCount => imagePaths.length + (imageAsset.isEmpty ? 0 : 1);

  List<_CheckInPreviewMedia> get previewMedia {
    return [
      if (imageAsset.isNotEmpty) _CheckInPreviewMedia.asset(imageAsset),
      for (final path in imagePaths) _CheckInPreviewMedia.file(path),
    ];
  }
}

class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({required super.begin, required super.end});

  @override
  LatLng lerp(double t) {
    final start = begin!;
    final target = end!;

    return LatLng(
      start.latitude + (target.latitude - start.latitude) * t,
      start.longitude + (target.longitude - start.longitude) * t,
    );
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pusatkan ke lokasi saat ini',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 4,
        shadowColor: const Color(0x26000000),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF777777),
                      size: 26,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagActionMenu extends StatelessWidget {
  const _FlagActionMenu({
    required this.expanded,
    required this.onToggle,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    const buttonSize = 48.0;
    const actionWidth = 106.0;
    const expandedWidth = buttonSize + actionWidth * 2;
    const animationDuration = Duration(milliseconds: 320);
    const animationCurve = Curves.easeOutCubic;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: animationCurve,
        width: expanded ? expandedWidth : buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Positioned(
              top: 0,
              right: buttonSize,
              bottom: 0,
              width: actionWidth * 2,
              child: IgnorePointer(
                ignoring: !expanded,
                child: ClipRect(
                  child: AnimatedSlide(
                    duration: animationDuration,
                    curve: animationCurve,
                    offset: expanded ? Offset.zero : const Offset(1, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: expanded ? 1 : 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _FlagMenuAction(
                            icon: Icons.arrow_downward_rounded,
                            label: 'Check-in',
                            color: const Color(0xFF8A1D2A),
                            backgroundColor: const Color(0xFFFFF4F4),
                            onPressed: onCheckIn,
                          ),
                          _FlagMenuAction(
                            icon: Icons.arrow_upward_rounded,
                            label: 'Check-out',
                            color: const Color(0xFF0B5E35),
                            backgroundColor: const Color(0xFFE8FCF6),
                            onPressed: onCheckOut,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: expanded ? 'Tutup aksi check-in' : 'Buka aksi check-in',
              child: InkWell(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: animationDuration,
                  curve: animationCurve,
                  width: buttonSize,
                  height: buttonSize,
                  color: expanded ? const Color(0xFF3498F6) : Colors.white,
                  child: Icon(
                    Icons.flag_outlined,
                    color: expanded ? Colors.white : const Color(0xFF777777),
                    size: 25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagMenuAction extends StatelessWidget {
  const _FlagMenuAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 106,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: backgroundColor,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInBottomSheet extends StatelessWidget {
  const _CheckInBottomSheet({required this.items, required this.onItemTap});

  final List<_VisibleCheckIn> items;
  final ValueChanged<_VisibleCheckIn> onItemTap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .22,
      minChildSize: .15,
      maxChildSize: .56,
      snap: true,
      snapSizes: const [.22, .56],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 9, 18, 18),
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check-in nearby',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: kInk,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items.isEmpty
                              ? 'Tidak ada titik di area layar'
                              : '${items.length} titik terlihat di area layar',
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kSoftGreen,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                        color: kCirculGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: kLine),
              if (items.isEmpty)
                const _EmptyCheckInResult()
              else
                for (var i = 0; i < items.length; i++) ...[
                  _CheckInResultTile(
                    item: items[i],
                    onTap: () => onItemTap(items[i]),
                  ),
                  if (i < items.length - 1)
                    const Divider(height: 1, color: kLine),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyCheckInResult extends StatelessWidget {
  const _EmptyCheckInResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: kMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Geser atau zoom map untuk menemukan titik check-in lain.',
              style: TextStyle(
                color: kMuted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInResultTile extends StatelessWidget {
  const _CheckInResultTile({required this.item, required this.onTap});

  final _VisibleCheckIn item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bodyText = item.subtitle;
    final locationText = item.title;
    final previewItems = item.previewMedia.take(2).toList(growable: false);
    final previewSlots = previewItems.isEmpty
        ? const <_CheckInPreviewMedia?>[null, null]
        : previewItems;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  avatarAsset,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.timeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9A9A9A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    bodyText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      height: 1.28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final thumbSize = ((constraints.maxWidth - 18) / 2)
                          .clamp(78.0, 96.0)
                          .toDouble();

                      return Row(
                        children: [
                          for (var i = 0; i < previewSlots.length; i++) ...[
                            if (i > 0) const SizedBox(width: 18),
                            _CheckInPreviewBox(
                              size: thumbSize,
                              media: previewSlots[i],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInPreviewBox extends StatelessWidget {
  const _CheckInPreviewBox({required this.size, this.media});

  final double size;
  final _CheckInPreviewMedia? media;

  @override
  Widget build(BuildContext context) {
    final previewMedia = media;
    final image = previewMedia == null
        ? const ColoredBox(color: Color(0xFFD9D9D9))
        : previewMedia.filePath == null
        ? Image.asset(
            previewMedia.asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          )
        : Image.file(
            File(previewMedia.filePath!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(color: Color(0xFFD9D9D9));
            },
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

class _CheckInPreviewMedia {
  const _CheckInPreviewMedia.asset(this.asset) : filePath = null;

  const _CheckInPreviewMedia.file(this.filePath) : asset = '';

  final String asset;
  final String? filePath;
}

List<CircleMarker> _clusterGlows(List<MapIssueCluster> issueClusters) {
  return [
    for (final spot in _impactSpots) ...[
      CircleMarker(
        point: spot.point,
        radius: spot.radiusMeters * 1.9,
        useRadiusInMeter: true,
        color: _heatmapColorForIntensity(spot.intensity).withValues(alpha: .17),
      ),
      CircleMarker(
        point: spot.point,
        radius: spot.radiusMeters * 1.35,
        useRadiusInMeter: true,
        color: _heatmapColorForIntensity(
          spot.intensity * .72,
        ).withValues(alpha: .28),
      ),
      CircleMarker(
        point: spot.point,
        radius: spot.radiusMeters * .82,
        useRadiusInMeter: true,
        color: _heatmapColorForIntensity(spot.intensity).withValues(alpha: .46),
      ),
      CircleMarker(
        point: spot.point,
        radius: spot.radiusMeters * .48,
        useRadiusInMeter: true,
        color: _heatmapColorForIntensity(
          spot.intensity,
        ).withValues(alpha: spot.intensity.clamp(.32, .72)),
      ),
    ],
    for (final cluster in issueClusters) ...[
      CircleMarker(
        point: cluster.point,
        radius: _clusterGlowRadiusForCount(cluster.count),
        useRadiusInMeter: true,
        color: _clusterColorForCount(cluster.count).withValues(alpha: .16),
      ),
      CircleMarker(
        point: cluster.point,
        radius: _clusterGlowRadiusForCount(cluster.count) * .66,
        useRadiusInMeter: true,
        color: _clusterColorForCount(cluster.count).withValues(alpha: .26),
      ),
      CircleMarker(
        point: cluster.point,
        radius: _clusterGlowRadiusForCount(cluster.count) * .36,
        useRadiusInMeter: true,
        color: _clusterColorForCount(cluster.count).withValues(alpha: .42),
      ),
    ],
  ];
}

Color _clusterColorForCount(int count) {
  if (count <= 2) return const Color(0xFF22C55E);
  if (count <= 5) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _distanceLabel(double distanceMeters) {
  if (distanceMeters < 1000) return '${distanceMeters.round()} m';
  return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}

double _clusterGlowRadiusForCount(int count) {
  return (36 + count * 5).clamp(42, 86).toDouble();
}

double _clusterMarkerSizeForCount(int count) {
  return (34 + count * 2).clamp(36, 52).toDouble();
}

Color _heatmapColorForIntensity(double intensity) {
  final value = intensity.clamp(0, 1);
  if (value < .5) {
    return Color.lerp(
      const Color(0xFF21C45D),
      const Color(0xFFFACC15),
      value / .5,
    )!;
  }

  return Color.lerp(
    const Color(0xFFFACC15),
    const Color(0xFFEF4444),
    (value - .5) / .5,
  )!;
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCirculGreen.withValues(alpha: .18),
        shape: BoxShape.circle,
        border: Border.all(color: kCirculGreen.withValues(alpha: .32)),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF22C77A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusedCheckInMarker extends StatelessWidget {
  const _FocusedCheckInMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 8,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kCirculGreen.withValues(alpha: .18),
              shape: BoxShape.circle,
              border: Border.all(color: kCirculGreen.withValues(alpha: .34)),
            ),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kCirculGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _FeedPostCheckInMarker extends StatelessWidget {
  const _FeedPostCheckInMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: kCirculGreen,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
    );
  }
}

class _IssueQuantityMarker extends StatelessWidget {
  const _IssueQuantityMarker({required this.cluster});

  final MapIssueCluster cluster;

  @override
  Widget build(BuildContext context) {
    final color = _clusterColorForCount(cluster.count);
    final size = _clusterMarkerSizeForCount(cluster.count);

    return Center(
      child: Semantics(
        label: '${cluster.count} laporan lingkungan turun',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                cluster.count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityMarker extends StatelessWidget {
  const _ActivityMarker({required this.activity});

  final _MapActivity activity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: activity.color, width: 2),
      ),
      child: Icon(activity.icon, color: activity.color, size: 20),
    );
  }
}

class _MapActivity {
  const _MapActivity({
    required this.point,
    required this.icon,
    required this.color,
  });

  final LatLng point;
  final IconData icon;
  final Color color;
}

class _ImpactSpot {
  const _ImpactSpot({
    required this.point,
    required this.radiusMeters,
    required this.intensity,
  });

  final LatLng point;
  final double radiusMeters;
  final double intensity;
}

const _mapActivities = [
  _MapActivity(
    point: LatLng(-7.5559, 110.8186),
    icon: Icons.delete_outline_rounded,
    color: Color(0xFF7B2CBF),
  ),
  _MapActivity(
    point: LatLng(-7.5571, 110.8214),
    icon: Icons.campaign_rounded,
    color: kCirculGreen,
  ),
  _MapActivity(
    point: LatLng(-7.5606, 110.8192),
    icon: Icons.event_rounded,
    color: Color(0xFF7B2CBF),
  ),
];

const _impactSpots = [
  _ImpactSpot(
    point: LatLng(-7.5546, 110.8184),
    radiusMeters: 52,
    intensity: .82,
  ),
  _ImpactSpot(
    point: LatLng(-7.5568, 110.8202),
    radiusMeters: 44,
    intensity: .62,
  ),
  _ImpactSpot(
    point: LatLng(-7.5595, 110.8178),
    radiusMeters: 38,
    intensity: .58,
  ),
  _ImpactSpot(
    point: LatLng(-7.5612, 110.8185),
    radiusMeters: 92,
    intensity: .96,
  ),
  _ImpactSpot(
    point: LatLng(-7.5582, 110.8223),
    radiusMeters: 40,
    intensity: .48,
  ),
];
