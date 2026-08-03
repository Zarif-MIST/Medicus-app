import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class _HospitalContact {
  const _HospitalContact({required this.name, required this.area, required this.phone});

  final String name;
  final String area;
  final String phone;
}

// Placeholder contacts for the Emergency quick action — not a real hospital
// directory. Swap for a real API/dataset before shipping.
const List<_HospitalContact> _kNearbyHospitals = [
  _HospitalContact(name: 'City Care Hospital', area: '1.2 km away', phone: '+15551010001'),
  _HospitalContact(name: 'Green Life Medical Center', area: '2.4 km away', phone: '+15551010002'),
  _HospitalContact(name: 'Sunrise General Hospital', area: '3.1 km away', phone: '+15551010003'),
  _HospitalContact(name: 'Lakeview Emergency Center', area: '4.6 km away', phone: '+15551010004'),
];

/// Bottom sheet listing nearby hospitals with a one-tap "call" action that
/// opens the phone dialer (pre-filled, via the device's SIM) for that number.
class EmergencyHospitalsSheet extends StatelessWidget {
  const EmergencyHospitalsSheet({super.key});

  Future<void> _call(BuildContext context, String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the phone dialer on this device.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181818) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emergency_outlined, color: MColors.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nearby Hospitals', style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          'Tap call to reach them directly.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: MColors.primaryColor.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: MColors.primaryColor.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Demo contacts for preview only — not a real hospital directory.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MColors.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final _HospitalContact hospital in _kNearbyHospitals) ...[
                _HospitalTile(hospital: hospital, onCall: () => _call(context, hospital.phone)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HospitalTile extends StatelessWidget {
  const _HospitalTile({required this.hospital, required this.onCall});

  final _HospitalContact hospital;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: MColors.primaryColor.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital_outlined, color: MColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hospital.name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  hospital.area,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: MColors.primaryColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onCall,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.call_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
