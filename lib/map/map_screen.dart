import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../shared/circul_header.dart';
import 'widgets/activity_sheet.dart';
import 'widgets/impact_legend.dart';
import 'widgets/location_bubble.dart';
import 'widgets/map_marker.dart';
import 'widgets/map_square_button.dart';
import 'widgets/waste_map_painter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  var _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const CirculHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: kCirculGreen,
                    size: 31,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi saat ini',
                          style: TextStyle(color: kMuted),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Gondang Manis, Solo',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 48, color: kLine),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.energy_savings_leaf_rounded,
                    color: Color(0xFF62BF65),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dampak lingkungan',
                        style: TextStyle(color: kMuted),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Sedang',
                        style: TextStyle(
                          color: Color(0xFFE68A00),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: WasteMapPainter())),
                const Positioned(left: 20, top: 22, child: ImpactLegend()),
                const Positioned(
                  right: 28,
                  top: 30,
                  child: MapSquareButton(icon: Icons.my_location_rounded),
                ),
                const Positioned(
                  left: 24,
                  bottom: 304,
                  child: MapSquareButton(
                    icon: Icons.tune_rounded,
                    label: 'Filter',
                  ),
                ),
                const Positioned(
                  right: 30,
                  bottom: 304,
                  child: MapSquareButton(
                    icon: Icons.near_me_rounded,
                    label: 'Lokasi saya',
                  ),
                ),
                const Positioned(
                  left: 360,
                  top: 272,
                  child: MapMarker(
                    label: 'Pasar\nTokanan',
                    distance: '450 m',
                    color: Color(0xFF7B2CBF),
                    icon: Icons.local_mall_rounded,
                  ),
                ),
                const Positioned(
                  left: 52,
                  top: 430,
                  child: MapMarker(
                    label: 'Taman\nGondang Manis',
                    distance: '350 m',
                    color: kCirculGreen,
                    icon: Icons.park_rounded,
                  ),
                ),
                const Positioned(
                  right: 42,
                  top: 590,
                  child: MapMarker(
                    label: 'Bengkel Las\nSunan Karan',
                    distance: '200 m',
                    color: Color(0xFF7B2CBF),
                    icon: Icons.factory_rounded,
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LocationBubble(),
                      SizedBox(height: 4),
                      UserLocationPulse(),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ActivitySheet(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    onSeeAll: widget.onSeeAll,
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
