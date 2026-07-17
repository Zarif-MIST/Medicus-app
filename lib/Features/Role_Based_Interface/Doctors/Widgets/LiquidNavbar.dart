import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A single tab entry for [LiquidGlassNavBar].
class LiquidNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const LiquidNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// A real, shader-rendered "Liquid Glass" bottom nav bar (iOS 26 style),
/// built on `liquid_glass_renderer` — actual GPU refraction + dynamic
/// specular highlights, not a blur/gradient approximation.
///
/// Requirements:
/// - Add to pubspec.yaml: `liquid_glass_renderer: ^0.2.0-dev.4`
/// - Only works on Impeller (default on iOS/Android/macOS). Web, Windows,
///   and Linux are not supported by the renderer yet.
/// - Must be placed on top of real content (Stack + extendBody: true) —
///   glass with nothing behind it to refract just looks flat.
class LiquidGlassNavBar extends StatefulWidget {
  final List<LiquidNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color? accentColor;
  final double height;
  final EdgeInsets margin;

  /// Falls back to a cheaper backdrop-filter approximation instead of real
  /// shader refraction. Flip this on if you see jank on low-end devices.
  final bool fake;

  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    this.accentColor,
    this.height = 68,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 24),
    this.fake = false,
  }) : assert(items.length >= 2, 'Provide at least 2 nav items');

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _positionAnim;
  late Animation<double> _stretchAnim;

  final List<AnimationController> _iconControllers = [];

  @override
  void initState() {
    super.initState();

    _morphController = AnimationController(vsync: this);
    _positionAnim = AlwaysStoppedAnimation(widget.selectedIndex.toDouble());
    _stretchAnim = const AlwaysStoppedAnimation(0);

    for (int i = 0; i < widget.items.length; i++) {
      _iconControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
          value: i == widget.selectedIndex ? 1 : 0,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animateTo(oldWidget.selectedIndex, widget.selectedIndex);
    }
  }

  void _animateTo(int from, int to) {
    // Under-damped spring: overshoots the target then settles — this is
    // what reads as "liquid" instead of a mechanical slide.
    final spring = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 180, damping: 16),
      0,
      1,
      0,
    );

    _morphController
      ..stop()
      ..value = 0;

    _positionAnim = Tween<double>(begin: from.toDouble(), end: to.toDouble())
        .animate(_morphController);

    // The blob widens mid-travel then relaxes back — a liquid bulge.
    _stretchAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_morphController);

    _morphController.animateWith(spring);

    _iconControllers[from].reverse();
    _iconControllers[to].forward();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _morphController.dispose();
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? (isDark ? const Color.fromARGB(255, 255, 17, 0) : const Color.fromARGB(255, 82, 7, 2));
    final radius = widget.height;

    // Settings for the main bar body — clear, frosted, barely tinted.
    final barSettings = LiquidGlassSettings(
      thickness: 22,
      blur: 16,
      glassColor: isDark ? const Color(0x26FFFFFF) : const Color(0x40FFFFFF),
      lightIntensity: 1.3,
      saturation: 1.25,
      refractiveIndex: 1.4,
    );

    // Settings for the moving selection blob — same glass physics, an
    // accent tint, and a stronger highlight so it reads as "lit".
    final indicatorSettings = LiquidGlassSettings(
      thickness: 26,
      blur: 6,
      glassColor: accent.withValues(alpha: 1),
      lightIntensity: 1.6,
      saturation: 1.3,
      refractiveIndex: 1.5,
    );

    return Padding(
      padding: widget.margin,
      child: Container(
        // Shadow-only decoration for a bit of "floating panel" depth —
        // no fill color, so it doesn't interfere with refraction below.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: widget.height,
          child: LiquidGlassLayer(
            settings: barSettings,
            fake: widget.fake,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / widget.items.length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // The glass bar body itself.
                    Positioned.fill(
                      child: LiquidGlass(
                        shape: LiquidRoundedSuperellipse(borderRadius: radius / 2),
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // The liquid selection indicator — its own glass layer
                    // so it can carry a different tint/intensity.
                    AnimatedBuilder(
                      animation: _morphController,
                      builder: (context, _) {
                        final pos = _positionAnim.value;
                        final stretch = _stretchAnim.value;
                        final left = pos * itemWidth;
                        final extraWidth = itemWidth * 0.5 * stretch;

                        return Positioned(
                          left: left - extraWidth / 2,
                          width: itemWidth + extraWidth,
                          top: 0,
                          bottom: 0,
                          child: LiquidGlass.withOwnLayer(
                            shape: LiquidRoundedSuperellipse(borderRadius: 999),
                            settings: indicatorSettings,
                            fake: widget.fake,
                            child: const SizedBox.expand(),
                          ),
                        );
                      },
                    ),

                    // Tab buttons — plain widgets rendered on top, unaffected
                    // by refraction, so icons/text stay crisp.
                    Row(
                      children: List.generate(widget.items.length, (i) {
                        return Expanded(
                          child: _NavItemButton(
                            item: widget.items[i],
                            selected: widget.selectedIndex == i,
                            isDark: isDark,
                            controller: _iconControllers[i],
                            onTap: () => widget.onTap(i),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatefulWidget {
  final LiquidNavItem item;
  final bool selected;
  final bool isDark;
  final AnimationController controller;
  final VoidCallback onTap;

  const _NavItemButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.controller,
    required this.onTap,
  });

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  double _pressScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 1.0, end: 1.12)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(widget.controller);

    // Selected sits on top of the accent-tinted glass blob, which is
    // saturated/dark enough in both themes for white to stay legible.
    // Unselected sits directly on the bar's own glass, which is pale in
    // light mode — so it needs a dark, not white, unselected color there.
    final unselectedColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.45);
    const selectedColor = Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressScale = 0.88),
      onTapUp: (_) => setState(() => _pressScale = 1.0),
      onTapCancel: () => setState(() => _pressScale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressScale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: scaleAnim,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: scaleAnim.value,
                  child: Icon(
                    widget.selected ? (widget.item.selectedIcon ?? widget.item.icon) : widget.item.icon,
                    color: widget.selected ? selectedColor : unselectedColor,
                    size: 24,
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    color: widget.selected ? selectedColor : unselectedColor,
                    fontSize: 10,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(widget.item.label),
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