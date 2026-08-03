import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';

class StatCardData {
  const StatCardData({required this.label, required this.value, required this.icon, this.suffix = ''});

  final String label;
  final int value;
  final IconData icon;
  final String suffix;
}

/// A bento-style stat layout: one "highlight" card (spotlighting the most
/// actionable stat) beside the remaining stats stacked in a column.
class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key, required this.stats, this.highlightIndex = 0, this.onHighlightTap});

  final List<StatCardData> stats;

  /// Index into [stats] to render as the highlight card.
  final int highlightIndex;

  /// Called when the highlight card is tapped. If null, the card is static.
  final VoidCallback? onHighlightTap;

  @override
  Widget build(BuildContext context) {
    final List<int> restIndices = [
      for (int i = 0; i < stats.length; i++)
        if (i != highlightIndex) i,
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _HighlightStatCard(data: stats[highlightIndex], onTap: onHighlightTap),
          ),
          SizedBox(width: Sizes.defaultpadding * 0.5),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                for (int i = 0; i < restIndices.length; i++) ...[
                  if (i != 0) const SizedBox(height: 10),
                  _StatCard(data: stats[restIndices[i]]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightStatCard extends StatelessWidget {
  const _HighlightStatCard({required this.data, this.onTap});

  final StatCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF92140C), Color(0xFF5D0B07)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: MColors.primaryColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: Colors.white, size: 18),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: data.value.toDouble()),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        '${value.round()}${data.suffix}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.label,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                    maxLines: 2,
                  ),
                  if (onTap != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'View calendar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: MColors.primaryColor, size: 14),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: data.value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '${value.round()}${data.suffix}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 1),
          Text(
            data.label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
