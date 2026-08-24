import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/bangladesh_hospitals.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';

/// Bottom sheet listing nearby hospitals with a search bar to filter by
/// name/area and a one-tap "call" action that opens the phone dialer
/// (pre-filled, via the device's SIM) for that number.
class EmergencyHospitalsSheet extends StatefulWidget {
  const EmergencyHospitalsSheet({super.key});

  @override
  State<EmergencyHospitalsSheet> createState() => _EmergencyHospitalsSheetState();
}

class _EmergencyHospitalsSheetState extends State<EmergencyHospitalsSheet> {
  String _query = '';

  Future<void> _call(BuildContext context, String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the phone dialer on this device.")),
      );
    }
  }

  List<HospitalContact> get _filtered {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return kNearbyHospitals;
    return kNearbyHospitals
        .where(
          (h) =>
              h.name.toLowerCase().contains(query) ||
              h.area.toLowerCase().contains(query) ||
              h.phone.contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final List<HospitalContact> hospitals = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
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
                          '${kNearbyHospitals.length} hospitals across Bangladesh · tap call to reach them.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppSearchBar(
                hintText: 'Search by hospital, area, or number',
                onChanged: (value) => setState(() => _query = value),
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
                        'Demo directory — verify a number before relying on it in a real emergency.',
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
              if (hospitals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No hospitals match "$_query".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                )
              else
                for (final HospitalContact hospital in hospitals) ...[
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

  final HospitalContact hospital;
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
                  '${hospital.area} · ${hospital.phone}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

