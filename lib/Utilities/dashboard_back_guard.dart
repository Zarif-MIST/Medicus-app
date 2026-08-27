import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a role dashboard shell so the system back button behaves like a
/// normal app instead of immediately closing Medicus: from any non-home
/// tab it returns to the home tab first, and only exits after a second
/// back press on the home tab within [confirmWindow].
class DashboardBackGuard extends StatefulWidget {
  const DashboardBackGuard({
    super.key,
    required this.isOnHomeTab,
    required this.goToHomeTab,
    required this.child,
    this.confirmWindow = const Duration(seconds: 2),
  });

  final bool isOnHomeTab;
  final VoidCallback goToHomeTab;
  final Widget child;
  final Duration confirmWindow;

  @override
  State<DashboardBackGuard> createState() => _DashboardBackGuardState();
}

class _DashboardBackGuardState extends State<DashboardBackGuard> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (!widget.isOnHomeTab) {
          widget.goToHomeTab();
          return;
        }

        final DateTime now = DateTime.now();
        final DateTime? last = _lastBackPress;
        if (last == null || now.difference(last) > widget.confirmWindow) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Press back again to exit'),
              duration: widget.confirmWindow,
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: widget.child,
    );
  }
}
