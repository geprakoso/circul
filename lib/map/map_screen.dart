import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../check_in/capture_result_screen.dart';
import '../core/constants.dart';

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
  });

  final List<MapIssueCluster> issueClusters;
  final ValueChanged<LatLng>? onDownCheckIn;

  static double distanceMeters(LatLng first, LatLng second) {
    return const Distance().as(LengthUnit.Meter, first, second);
  }

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  late final AnimationController _cameraAnimationController;
  var _currentLocation = _gondangManisCenter;
  var _isLocating = false;
  var _flagMenuExpanded = false;

  @override
  void initState() {
    super.initState();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _cameraAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _gondangManisCenter,
            initialZoom: 16,
            minZoom: 12,
            maxZoom: 19,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
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
                for (final cluster in widget.issueClusters)
                  Marker(
                    point: cluster.point,
                    width: _clusterMarkerSizeForCount(cluster.count) + 8,
                    height: _clusterMarkerSizeForCount(cluster.count) + 8,
                    child: _IssueQuantityMarker(cluster: cluster),
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
          bottom: 18,
          child: _LocateButton(
            isLoading: _isLocating,
            onPressed: _centerToCurrentLocation,
          ),
        ),
        Positioned(
          right: 16,
          bottom: 78,
          child: _FlagActionMenu(
            expanded: _flagMenuExpanded,
            onToggle: () =>
                setState(() => _flagMenuExpanded = !_flagMenuExpanded),
            onCheckIn: _openCaptureResult,
            onCheckOut: () => _showLocationMessage('Check-out dipilih.'),
          ),
        ),
      ],
    );
  }

  Future<void> _centerToCurrentLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    try {
      final permissionGranted = await _ensureLocationPermission();
      if (!permissionGranted) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() => _currentLocation = point);
      _animateMapTo(point, 17);
    } catch (_) {
      if (!mounted) return;
      _showLocationMessage('Tidak bisa mengambil lokasi saat ini.');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
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
      if (mounted) {
        _showLocationMessage('Izin lokasi belum diberikan.');
      }
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
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

  void _openCaptureResult() {
    setState(() => _flagMenuExpanded = false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            CaptureResultScreen(onDownSelected: widget.onDownCheckIn),
      ),
    );
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
