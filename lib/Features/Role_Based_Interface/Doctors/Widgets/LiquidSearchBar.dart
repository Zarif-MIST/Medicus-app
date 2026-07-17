import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// A real, shader-rendered "Liquid Glass" search field — same rendering
/// approach as [LiquidGlassNavBar], sized for use as a header search bar
/// (e.g. searching patient IDs on a colored dashboard header).
///
/// Requirements: `liquid_glass_renderer` in pubspec.yaml, Impeller
/// (default on iOS/Android/macOS), and something behind it to refract —
/// it's designed to sit on top of a colored/curved header, not a flat
/// solid scaffold background.
class LiquidGlassSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final double height;

  /// Tint of the glass itself. Defaults to a light frosted white, which
  /// reads well on a saturated header color.
  final Color glassTint;

  final Color iconColor;
  final Color textColor;
  final Color hintColor;
  final bool autofocus;

  /// Falls back to a cheaper backdrop-filter approximation instead of
  /// real shader refraction — flip on if you see jank on low-end devices.
  final bool fake;

  const LiquidGlassSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.height = 52,
    this.glassTint = const Color(0x40FFFFFF),
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.hintColor = const Color(0xB3FFFFFF),
    this.autofocus = false,
    this.fake = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Container(
        // Shadow-only decoration for a bit of lift off the header — no
        // fill color, so it doesn't interfere with refraction below.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LiquidGlassLayer(
          settings: LiquidGlassSettings(
            thickness: 20,
            blur: 14,
            glassColor: glassTint,
            lightIntensity: 1.3,
            saturation: 1.2,
            refractiveIndex: 1.4,
          ),
          fake: fake,
          child: LiquidGlass(
            shape: LiquidRoundedSuperellipse(borderRadius: radius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: iconColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      onTap: onTap,
                      autofocus: autofocus,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: iconColor,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: hintText,
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}