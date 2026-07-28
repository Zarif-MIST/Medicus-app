import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/specialty_filter_chips.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Services/doctor_directory_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/doctor_profile_screen.dart';

class SpecialistSelectionScreen extends StatefulWidget {
  const SpecialistSelectionScreen({
    super.key,
    required this.appointments,
    required this.onBook,
  });

  final List<BookedAppointment> appointments;
  final ValueChanged<BookedAppointment> onBook;

  @override
  State<SpecialistSelectionScreen> createState() =>
      _SpecialistSelectionScreenState();
}

class _SpecialistSelectionScreenState extends State<SpecialistSelectionScreen> {
  Specialty? _selectedSpecialty;
  final DoctorDirectoryService _directoryService = DoctorDirectoryService.instance;
  List<DoctorSummary> _allDoctors = const <DoctorSummary>[];
  String _searchQuery = '';
  bool _isLoadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final List<DoctorSummary> doctors = await _directoryService.getDoctors();
    if (!mounted) {
      return;
    }
    setState(() {
      _allDoctors = doctors;
      _isLoadingDoctors = false;
    });
  }

  void _handleSpecialtyTap(Specialty specialty) {
    setState(() {
      _selectedSpecialty = _selectedSpecialty?.name == specialty.name
          ? null
          : specialty;
    });
  }

  void _onDoctorSelected(DoctorSummary doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DoctorProfileScreen(doctor: doctor, onBooked: widget.onBook),
      ),
    );
  }

  List<DoctorSummary> get _visibleDoctors {
    final String normalizedQuery = _searchQuery.trim().toLowerCase();
    Iterable<DoctorSummary> doctors = _allDoctors;

    if (_selectedSpecialty != null) {
      doctors = doctors.where((d) => d.specialty == _selectedSpecialty!.name);
    }

    if (normalizedQuery.isNotEmpty) {
      doctors = doctors.where((d) {
        return d.name.toLowerCase().contains(normalizedQuery) ||
            d.specialty.toLowerCase().contains(normalizedQuery) ||
            d.hospital.toLowerCase().contains(normalizedQuery);
      });
    }

    final List<DoctorSummary> filtered = doctors.toList();
    if (_selectedSpecialty == null && normalizedQuery.isEmpty) {
      return filtered.take(3).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);
    final List<DoctorSummary> doctors = _visibleDoctors;

    return Container(
      color: isDark ? const Color(0xFF181818) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.8, pad, 120),
          children: [
            if (widget.appointments.isNotEmpty) ...[
              Text('Upcoming Appointments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 14),
              for (int i = 0; i < widget.appointments.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                _UpcomingAppointmentCard(appointment: widget.appointments[i]),
              ],
              SizedBox(height: pad),
            ],
            Text('Find a Doctor', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Choose a specialist or search directly',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: pad * 0.8),
            LiquidGlassSearchBar(
              hintText: 'Search specialist or doctor name',
              onChanged: (value) => setState(() => _searchQuery = value),
              onSubmitted: (value) => setState(() => _searchQuery = value),
            ),
            SizedBox(height: pad * 0.8),
            SpecialtyFilterChips(
              specialties: kSpecialties,
              selected: _selectedSpecialty,
              onSelected: _handleSpecialtyTap,
            ),
            SizedBox(height: pad * 0.5),
            Text(
              _searchQuery.trim().isNotEmpty
                  ? 'Search Results'
                  : _selectedSpecialty == null
                  ? 'Top Doctors'
                  : '${_selectedSpecialty!.name} Specialists',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            if (_isLoadingDoctors)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
            if (doctors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _searchQuery.trim().isNotEmpty
                      ? 'No doctors match your search query.'
                      : 'No doctors found for this specialty yet.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )
            else
              for (int i = 0; i < doctors.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                DoctorResultCard(
                  doctor: doctors[i],
                  onTap: () => _onDoctorSelected(doctors[i]),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final DateTime date = appointment.date;
    final String formattedDate =
        '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        thickness: 16,
        blur: 10,
        glassColor: isDark ? const Color(0x22FFFFFF) : const Color(0x92FFFFFF),
        lightIntensity: 1.05,
        saturation: 1.15,
        refractiveIndex: 1.25,
      ),
      child: LiquidGlass(
        shape: LiquidRoundedSuperellipse(borderRadius: 16),
        child: Material(
          color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: MColors.primaryColor.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.event_available,
                    color: MColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appointment.specialty,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appointment.time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
