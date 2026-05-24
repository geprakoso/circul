import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../feed_post_repository.dart';
import '../shared/sarah_avatar.dart';
import 'widgets/attachment_media_strip.dart';
import 'widgets/compose_footer.dart';
import 'widgets/compose_header.dart';
import 'widgets/compose_tools.dart';
import 'widgets/topic_autocomplete.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({
    super.key,
    this.feedPostRepository,
    this.initialBody = '',
    this.initialTopic = '',
    this.initialImagePaths = const [],
    this.initialLocationCheckInEnabled = false,
    this.initialLocationLabel,
    this.initialCoordinateLabel,
    this.initialLocationPoint,
  });

  final FeedPostRepository? feedPostRepository;
  final String initialBody;
  final String initialTopic;
  final List<String> initialImagePaths;
  final bool initialLocationCheckInEnabled;
  final String? initialLocationLabel;
  final String? initialCoordinateLabel;
  final LatLng? initialLocationPoint;

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  static const _background = Color(0xFF0E0F10);
  static const _softText = Color(0xFF8C8F93);
  static const _attachmentsChannel = MethodChannel('circul/attachments');

  late final FeedPostRepository _repository;
  final _controller = TextEditingController();
  var _selectedTopic = '';
  var _allowReplies = true;
  var _locationCheckInEnabled = false;
  var _isLocating = false;
  var _isSubmitting = false;
  final _selectedImagePaths = <String>[];
  String? _locationLabel;
  String? _coordinateLabel;
  LatLng? _locationPoint;

  bool get _canPost => !_isSubmitting && _controller.text.trim().isNotEmpty;
  String? get _postCityLabel {
    final label = _locationLabel?.trim();
    if (!_locationCheckInEnabled ||
        label == null ||
        label.isEmpty ||
        label == 'Getting location...' ||
        label == 'Location unavailable') {
      return null;
    }

    return label;
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.feedPostRepository ?? FeedPostRepository();
    _controller.text = widget.initialBody;
    _selectedTopic = widget.initialTopic;
    _locationCheckInEnabled = widget.initialLocationCheckInEnabled;
    _selectedImagePaths.addAll(widget.initialImagePaths);
    _locationLabel = widget.initialLocationLabel;
    _coordinateLabel = widget.initialCoordinateLabel;
    _locationPoint = widget.initialLocationPoint;
    _controller.addListener(() => setState(() {}));

    if (_locationCheckInEnabled &&
        (_locationLabel?.trim().isNotEmpty != true ||
            _coordinateLabel?.trim().isNotEmpty != true)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() => _isSubmitting = true);

    try {
      await _repository.addPost(
        body: _controller.text,
        topic: _selectedTopic,
        allowReplies: _allowReplies,
        city: _postCityLabel,
        imagePaths: List<String>.of(_selectedImagePaths),
        locationEnabled: _locationCheckInEnabled,
        locationLabel: _postCityLabel,
        coordinateLabel: _coordinateLabel,
        locationLatitude: _locationPoint?.latitude,
        locationLongitude: _locationPoint?.longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan gagal disimpan lokal.')),
      );
    }
  }

  Future<void> _openImageAttachmentChooser() async {
    try {
      final imagePaths = await _attachmentsChannel.invokeListMethod<String>(
        'openImageChooser',
      );
      if (!mounted || imagePaths == null || imagePaths.isEmpty) return;

      setState(() {
        for (final path in imagePaths) {
          if (!_selectedImagePaths.contains(path)) {
            _selectedImagePaths.add(path);
          }
        }
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Gagal membuka pilihan gambar.'),
        ),
      );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilihan sistem belum tersedia di platform ini.'),
        ),
      );
    }
  }

  void _removeSelectedImage(String path) {
    setState(() => _selectedImagePaths.remove(path));
  }

  void _toggleLocationCheckIn() {
    if (_locationCheckInEnabled) {
      setState(() => _locationCheckInEnabled = false);
      return;
    }

    setState(() => _locationCheckInEnabled = true);
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    if (_isLocating) return;

    setState(() {
      _isLocating = true;
      _locationLabel = 'Getting location...';
      _coordinateLabel = null;
      _locationPoint = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationUnavailable('Aktifkan layanan lokasi untuk check-in.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _setLocationUnavailable('Izin lokasi belum diberikan.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _setLocationUnavailable('Izin lokasi diblokir. Ubah lewat pengaturan.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final label = await _getPlaceLabel(position);

      if (!mounted) return;
      setState(() {
        _locationLabel = label;
        _coordinateLabel = _coordinateLabelFor(position);
        _locationPoint = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      _setLocationUnavailable('Tidak bisa mengambil lokasi saat ini.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _setLocationUnavailable(String message) {
    if (!mounted) return;
    setState(() {
      _locationLabel = 'Location unavailable';
      _coordinateLabel = null;
      _locationPoint = null;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

  String _coordinateLabelFor(Position position) {
    return '${position.latitude.toStringAsFixed(5)}, '
        '${position.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _background,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: kCirculGreen,
          surface: _background,
          onSurface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              ComposeHeader(onClose: () => Navigator.of(context).pop()),
              const Divider(height: 1, color: Color(0xFF202225)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SarahAvatar(radius: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    const Text(
                                      'sarahmae',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: _softText,
                                      size: 18,
                                    ),
                                    TopicAutocomplete(
                                      topic: _selectedTopic,
                                      onChanged: (value) => setState(
                                        () => _selectedTopic = value,
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: _controller,
                                  autofocus: true,
                                  minLines: 3,
                                  maxLines: 9,
                                  cursorColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    height: 1.32,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Apa yang baru?',
                                    hintStyle: TextStyle(
                                      color: _softText,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    contentPadding: EdgeInsets.only(top: 4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ComposeTools(
                                  locationCheckInEnabled:
                                      _locationCheckInEnabled,
                                  onImageTap: _openImageAttachmentChooser,
                                  onLocationCheckInTap: _toggleLocationCheckIn,
                                ),
                                const SizedBox(height: 12),
                                AttachmentMediaStrip(
                                  locationEnabled: _locationCheckInEnabled,
                                  locationLoading: _isLocating,
                                  locationLabel: _locationLabel,
                                  coordinateLabel: _coordinateLabel,
                                  imagePaths: _selectedImagePaths,
                                  onRemoveImage: _removeSelectedImage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ComposeFooter(
                allowReplies: _allowReplies,
                canPost: _canPost,
                onAllowRepliesChanged: (value) =>
                    setState(() => _allowReplies = value),
                onPost: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
