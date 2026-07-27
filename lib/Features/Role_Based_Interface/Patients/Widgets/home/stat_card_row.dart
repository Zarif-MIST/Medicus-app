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

class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key, required this.stats});

  final List<StatCardData> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i != 0) SizedBox(width: Sizes.defaultpadding * 0.5),
          Expanded(child: _StatCard(data: stats[i])),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: MColors.primaryColor, size: 20),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: data.value.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '${value.round()}${data.suffix}',
                style: theme.textTheme.titleLarge,
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
