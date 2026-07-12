import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';

const List<String> _healthTips = [
  'Drink at least 8 glasses of water today.',
  'A 10-minute walk after meals aids digestion.',
  'Remember to take your medicines on time.',
  'Get 7-8 hours of sleep for better recovery.',
  'Deep breaths for a minute can lower stress.',
];

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key, required this.patientName});

  final String patientName;

  String get _healthTip {
    final DateTime now = DateTime.now();
    final int dayOfYear = now.month * 31 + now.day;
    return _healthTips[dayOfYear % _healthTips.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Hi, $patientName', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 16, color: MColors.primaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _healthTip,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
