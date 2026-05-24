import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';

const _capturePreviewAsset = 'assets/images/check_in_capture_preview.png';

class CaptureResultScreen extends StatefulWidget {
  const CaptureResultScreen({
    super.key,
    this.imagePath,
    this.onDownSelected,
    this.useDummyCapture = false,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker;

  final String? imagePath;
  final ValueChanged<LatLng>? onDownSelected;
  final bool useDummyCapture;
  final ImagePicker? _imagePicker;

  @override
  State<CaptureResultScreen> createState() => _CaptureResultScreenState();
}

class _CaptureResultScreenState extends State<CaptureResultScreen> {
  _ConditionChoice? _selectedChoice;
  late final ImagePicker _imagePicker;
  late String? _imagePath;
  late DateTime _capturedAt;
  LatLng? _capturedPoint;
  var _locationText = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _imagePicker = widget._imagePicker ?? ImagePicker();
    _imagePath = widget.imagePath;
    _capturedAt = DateTime.now();
    _loadCurrentLocation();
  }

  @override
  void didUpdateWidget(covariant CaptureResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _imagePath = widget.imagePath;
    }
  }

  void _selectChoice(_ConditionChoice choice) {
    setState(() => _selectedChoice = choice);
    if (choice == _ConditionChoice.down) {
      _addDownHeatmapLevel();
    }
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _retakePhoto() async {
    if (widget.useDummyCapture && Platform.isMacOS) {
      setState(() {
        _imagePath = null;
        _capturedAt = DateTime.now();
        _locationText = 'Getting location...';
      });
      _loadCurrentLocation();
      _showPlaceholderMessage('Dummy camera dipakai untuk development macOS.');
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 1800,
      );
      if (!mounted || image == null) return;

      setState(() {
        _imagePath = image.path;
        _capturedAt = DateTime.now();
        _locationText = 'Getting location...';
      });
      _loadCurrentLocation();
    } on PlatformException catch (_) {
      if (!mounted) return;
      _showPlaceholderMessage('Kamera belum bisa dibuka.');
    }
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _getCurrentLocation();
    if (!mounted) return;

    setState(() {
      _capturedPoint = location.point;
      _locationText = location.label;
    });
  }

  Future<_CaptureLocation> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return const _CaptureLocation.unavailable();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const _CaptureLocation.unavailable();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      return _CaptureLocation(
        point: LatLng(position.latitude, position.longitude),
        label: await _getPlaceLabel(position),
      );
    } catch (_) {
      return const _CaptureLocation.unavailable();
    }
  }

  Future<void> _addDownHeatmapLevel() async {
    var point = _capturedPoint;
    if (point == null) {
      setState(() => _locationText = 'Getting location...');
      final location = await _getCurrentLocation();
      if (!mounted) return;

      point = location.point;
      setState(() {
        _capturedPoint = point;
        _locationText = location.label;
      });
    }

    if (point == null) {
      _showPlaceholderMessage('Lokasi belum tersedia untuk heatmap.');
      return;
    }

    widget.onDownSelected?.call(point);
    if (mounted) Navigator.of(context).pop();
  }

  Future<String> _getPlaceLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isEmpty) {
        return _formatCoordinates(position.latitude, position.longitude);
      }

      return _formatTwoLevelPlace(placemarks.first) ??
          _formatCoordinates(position.latitude, position.longitude);
    } catch (_) {
      return _formatCoordinates(position.latitude, position.longitude);
    }
  }

  String? _formatTwoLevelPlace(Placemark placemark) {
    final levels =
        <String?>[
              placemark.thoroughfare,
              placemark.street,
              placemark.subLocality,
              placemark.locality,
              placemark.subAdministrativeArea,
              placemark.administrativeArea,
            ]
            .where(_hasAddressValue)
            .map((value) => _cleanAddressValue(value!))
            .toList();

    final uniqueLevels = <String>[];
    for (final level in levels) {
      final alreadyIncluded = uniqueLevels.any(
        (item) => item.toLowerCase() == level.toLowerCase(),
      );
      if (!alreadyIncluded) uniqueLevels.add(level);
      if (uniqueLevels.length == 2) break;
    }

    if (uniqueLevels.isEmpty) return null;
    return uniqueLevels.join(', ');
  }

  bool _hasAddressValue(String? value) {
    return value != null && _cleanAddressValue(value).isNotEmpty;
  }

  String _cleanAddressValue(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lngDirection = longitude >= 0 ? 'E' : 'W';
    final lat = latitude.abs().toStringAsFixed(5);
    final lng = longitude.abs().toStringAsFixed(5);

    return '$lat° $latDirection, $lng° $lngDirection';
  }

  String _formatCaptureTime(DateTime dateTime) {
    final now = DateTime.now();
    final dateLabel = _isSameDate(dateTime, now)
        ? 'Today'
        : _formatDate(dateTime);
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';

    return '$dateLabel, $hour:$minute $period';
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewWidth = constraints.maxWidth - 36;
            final naturalPreviewHeight = previewWidth / (781 / 676);
            final maxPreviewHeight = constraints.maxHeight * .42;
            final previewHeight = naturalPreviewHeight > maxPreviewHeight
                ? maxPreviewHeight
                : naturalPreviewHeight;

            return Column(
              children: [
                _CaptureHeader(onClose: () => Navigator.of(context).pop()),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    height: previewHeight,
                    width: double.infinity,
                    child: _CapturePreview(
                      imagePath: _imagePath,
                      useDummyCapture: widget.useDummyCapture,
                      locationText: _locationText,
                      capturedTimeText: _formatCaptureTime(_capturedAt),
                      onRetake: _retakePhoto,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _ConditionPanel(
                    selectedChoice: _selectedChoice,
                    onChoiceSelected: _selectChoice,
                    onExamplesTap: () =>
                        _showPlaceholderMessage('Contoh kondisi akan dibuka.'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CaptureHeader extends StatelessWidget {
  const _CaptureHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 22,
            child: _HeaderIconButton(
              icon: Icons.close_rounded,
              label: 'Tutup',
              onPressed: onClose,
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Capture Result',
                style: TextStyle(
                  color: kInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Step 2 of 3',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Positioned(
            right: 22,
            child: _HeaderIconButton(
              icon: Icons.info_outline_rounded,
              label: 'Info',
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Bantu kami menilai kondisi lingkungan.'),
                    ),
                  );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onPressed,
        radius: 30,
        child: Icon(icon, color: const Color(0xFF116A3A), size: 33),
      ),
    );
  }
}

class _CapturePreview extends StatelessWidget {
  const _CapturePreview({
    required this.onRetake,
    required this.locationText,
    required this.capturedTimeText,
    required this.useDummyCapture,
    this.imagePath,
  });

  final VoidCallback onRetake;
  final String locationText;
  final String capturedTimeText;
  final bool useDummyCapture;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final capturedPath = imagePath;
    final hasCapture = capturedPath != null || useDummyCapture;
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: capturedPath == null
                ? Image.asset(_capturePreviewAsset, fit: BoxFit.cover)
                : Image.file(
                    File(capturedPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        _capturePreviewAsset,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
        ),
        if (hasCapture) ...[
          const Positioned(left: 16, top: 14, child: _CapturedBadge()),
          Positioned(
            left: 16,
            bottom: 14,
            child: _CaptureMetaCard(
              locationText: locationText,
              capturedTimeText: capturedTimeText,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 14,
            child: _RetakeButton(onTap: onRetake),
          ),
        ] else
          Positioned(
            right: 18,
            bottom: 14,
            child: Semantics(
              button: true,
              label: 'Retake',
              child: InkResponse(
                onTap: onRetake,
                radius: 42,
                child: const SizedBox(width: 74, height: 74),
              ),
            ),
          ),
      ],
    );
  }
}

class _CapturedBadge extends StatelessWidget {
  const _CapturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 13, 7),
      decoration: BoxDecoration(
        color: const Color(0xE13B9658),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          SizedBox(width: 7),
          Text(
            'Captured',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureMetaCard extends StatelessWidget {
  const _CaptureMetaCard({
    required this.locationText,
    required this.capturedTimeText,
  });

  final String locationText;
  final String capturedTimeText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .38)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MetaRow(icon: Icons.location_on_outlined, text: locationText),
            const SizedBox(height: 11),
            _MetaRow(icon: Icons.schedule_rounded, text: capturedTimeText),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RetakeButton extends StatelessWidget {
  const _RetakeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Retake',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 7,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 74,
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: Color(0xFF23824D), size: 31),
                SizedBox(height: 2),
                Text(
                  'Retake',
                  style: TextStyle(
                    color: Color(0xFF23824D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConditionPanel extends StatelessWidget {
  const _ConditionPanel({
    required this.selectedChoice,
    required this.onChoiceSelected,
    required this.onExamplesTap,
  });

  final _ConditionChoice? selectedChoice;
  final ValueChanged<_ConditionChoice> onChoiceSelected;
  final VoidCallback onExamplesTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 28,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          14,
          24,
          22 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          children: [
            Container(
              width: 37,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            const _LeafBadge(),
            const SizedBox(height: 15),
            const Text(
              'Is the environment\nup or down?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF083E23),
                fontSize: 27,
                height: 1.14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your answer helps us understand\nthe condition of our environment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 17,
                height: 1.38,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _ConditionCard(
                    choice: _ConditionChoice.up,
                    selected: selectedChoice == _ConditionChoice.up,
                    onTap: () => onChoiceSelected(_ConditionChoice.up),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ConditionCard(
                    choice: _ConditionChoice.down,
                    selected: selectedChoice == _ConditionChoice.down,
                    onTap: () => onChoiceSelected(_ConditionChoice.down),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            _ExamplesButton(onTap: onExamplesTap),
          ],
        ),
      ),
    );
  }
}

class _LeafBadge extends StatelessWidget {
  const _LeafBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFFE7F3EA),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco_outlined, color: Color(0xFF23824D), size: 33),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _ConditionChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUp = choice == _ConditionChoice.up;
    final color = isUp ? const Color(0xFF23824D) : const Color(0xFFC24E4E);
    final backgroundColor = isUp
        ? const Color(0xFFF0FAF3)
        : const Color(0xFFFEF5F4);
    final borderColor = selected ? color : color.withValues(alpha: .12);
    final title = isUp ? 'Up' : 'Down';
    final subtitle = isUp ? 'Good condition' : 'Needs improvement';
    final icon = isUp
        ? Icons.sentiment_satisfied_alt_rounded
        : Icons.sentiment_dissatisfied_rounded;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 141,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 57),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamplesButton extends StatelessWidget {
  const _ExamplesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9FAFA),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 57,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3EA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE0EEE5)),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF23824D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Not sure? ',
                    style: TextStyle(
                      color: kInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: 'See examples',
                        style: TextStyle(color: Color(0xFF23824D)),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF27313C),
                size: 33,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureLocation {
  const _CaptureLocation({required this.point, required this.label});

  const _CaptureLocation.unavailable()
    : point = null,
      label = 'Location unavailable';

  final LatLng? point;
  final String label;
}

enum _ConditionChoice { up, down }
