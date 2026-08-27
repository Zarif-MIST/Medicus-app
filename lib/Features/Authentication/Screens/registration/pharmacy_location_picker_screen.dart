import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:medicus/Utilities/colors.dart';

/// Full-screen map picker used during pharmacist registration to capture
/// the pharmacy's real coordinates — tap anywhere to drop a pin, or use the
/// current-location button, then confirm to return the picked [LatLng].
class PharmacyLocationPickerScreen extends StatefulWidget {
  const PharmacyLocationPickerScreen({super.key, this.initial});

  final LatLng? initial;

  @override
  State<PharmacyLocationPickerScreen> createState() =>
      _PharmacyLocationPickerScreenState();
}

class _PharmacyLocationPickerScreenState
    extends State<PharmacyLocationPickerScreen> {
  static const LatLng _fallbackCenter = LatLng(23.8103, 90.4125); // Dhaka

  final MapController _mapController = MapController();
  LatLng? _picked;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final LatLng target = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _picked = target);
      _mapController.move(target, 16);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin your pharmacy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initial ?? _fallbackCenter,
              initialZoom: 14,
              onTap: (_, latLng) => setState(() => _picked = latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.medicus',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.location_on,
                        size: 36,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _picked == null
                    ? 'Tap anywhere on the map to drop a pin at your pharmacy.'
                    : 'Pin set at ${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'useCurrentLocation',
              backgroundColor: Colors.white,
              foregroundColor: MColors.primaryColor,
              onPressed: _locating ? null : _useCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _picked == null
                    ? null
                    : () => Navigator.of(context).pop(_picked),
                style: FilledButton.styleFrom(
                  backgroundColor: MColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
