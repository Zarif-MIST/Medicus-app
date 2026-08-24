import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

/// A friendly placeholder shown wherever a doctor has no appointments to
/// display — the home screen queue and the full appointments list both use
/// this so the empty state looks consistent everywhere.
class EmptyAppointmentsPlaceholder extends StatefulWidget {
  const EmptyAppointmentsPlaceholder({
    super.key,
    this.title = 'No Appointments Today',
    this.subtitle = 'Enjoy the calm — new bookings will show up here.',
    this.icon = Icons.event_available_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  State<EmptyAppointmentsPlaceholder> createState() =>
      _EmptyAppointmentsPlaceholderState();
}

class _EmptyAppointmentsPlaceholderState
    extends State<EmptyAppointmentsPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _bob = Tween<double>(
    begin: -6,
    end: 6,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        builder: (context, entrance, child) {
          return Opacity(
            opacity: entrance,
            child: Transform.scale(
              scale: 0.9 + (0.1 * entrance),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _bob,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bob.value),
                  child: child,
                );
              },
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: MColors.primaryColor.withValues(
                    alpha: isDark ? 0.16 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 42, color: MColors.primaryColor),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
