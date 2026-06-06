import 'package:flutter/material.dart';

import '../mock_data.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({super.key});

  static const _milestones = [
    _ImpactMilestone(
      icon: Icons.park_rounded,
      title: 'Waste Hero Level 4',
      progressLabel: '1,240 / 2,000 kg',
      progress: .62,
      backgroundColor: Color(0xFF2F7652),
      foregroundColor: Color(0xFFA7E8C2),
    ),
    _ImpactMilestone(
      icon: Icons.handshake_rounded,
      title: 'Community Leader',
      progressLabel: '8 / 10 cleanups',
      progress: .8,
      backgroundColor: Color(0xFF9AF0BD),
      foregroundColor: kCirculGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        toolbarHeight: 58,
        leadingWidth: 56,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
        ),
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: kInk,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            const Text(
              'Badges',
              style: TextStyle(
                color: kInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            GridView.builder(
              itemCount: achievements.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 24,
                mainAxisExtent: 154,
              ),
              itemBuilder: (context, index) {
                return _AchievementTile(achievement: achievements[index]);
              },
            ),
            const SizedBox(height: 34),
            const Text(
              'Your Impact Milestones',
              style: TextStyle(
                color: kInk,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            for (final milestone in _milestones) ...[
              _MilestoneCard(milestone: milestone),
              if (milestone != _milestones.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final badgeSize = constraints.maxWidth < 82
            ? constraints.maxWidth
            : 82.0;
        return Column(
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8F2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                achievement.icon,
                color: const Color(0xFF0D6041),
                size: badgeSize * .42,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kInk,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone});

  final _ImpactMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final horizontalPadding = compact ? 14.0 : 18.0;
        final iconSize = compact ? 50.0 : 56.0;
        final gap = compact ? 12.0 : 16.0;
        final titleSize = compact ? 13.0 : 14.0;
        final labelSize = compact ? 12.5 : 13.5;

        return Container(
          height: compact ? 92 : 100,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -12,
                child: Icon(
                  milestone.icon,
                  color: kInk.withValues(alpha: .035),
                  size: compact ? 88 : 102,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: compact ? 18 : 22,
                ),
                child: Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: milestone.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        milestone.icon,
                        color: milestone.foregroundColor,
                        size: iconSize * .53,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  milestone.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: kInk,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  milestone.progressLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: const Color(0xFF0D6041),
                                    fontSize: labelSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: compact ? 10 : 12),
                          _MilestoneProgress(value: milestone.progress),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MilestoneProgress extends StatelessWidget {
  const _MilestoneProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final progressWidth = constraints.maxWidth * value.clamp(0, 1);
        return Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: progressWidth,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF137A53),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ImpactMilestone {
  const _ImpactMilestone({
    required this.icon,
    required this.title,
    required this.progressLabel,
    required this.progress,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String title;
  final String progressLabel;
  final double progress;
  final Color backgroundColor;
  final Color foregroundColor;
}
