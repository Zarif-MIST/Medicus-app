import 'package:flutter/material.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/specialty_filter_chips.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/doctor_profile_screen.dart';

// Mock data — replaced by a Firestore query (users collection, role=doctor)
// once the data layer is wired up. One doctor per specialty so every chip
// returns a real result.
const List<DoctorSummary> _mockDoctors = [
  DoctorSummary(
    name: 'Dr. Kamrul Islam',
    specialty: 'General',
    hospital: 'United Hospital, Dhaka',
    rating: 4.6,
    experienceYears: 8,
    fee: 500,
    nextAvailable: 'Tomorrow 10 AM',
  ),
  DoctorSummary(
    name: 'Dr. Farhana Rahman',
    specialty: 'Cardiologist',
    hospital: 'Square Hospital, Dhaka',
    rating: 4.8,
    experienceYears: 12,
    fee: 800,
    nextAvailable: 'Today 5 PM',
  ),
  DoctorSummary(
    name: 'Dr. Nusrat Jahan',
    specialty: 'Dermatologist',
    hospital: 'Apollo Hospital, Dhaka',
    rating: 4.9,
    experienceYears: 15,
    fee: 1000,
    nextAvailable: 'Today 7 PM',
  ),
  DoctorSummary(
    name: 'Dr. Shafiul Alam',
    specialty: 'Pediatrician',
    hospital: 'Dhaka Shishu Hospital',
    rating: 4.7,
    experienceYears: 10,
    fee: 600,
    nextAvailable: 'Today 6 PM',
  ),
  DoctorSummary(
    name: 'Dr. Mahbub Hasan',
    specialty: 'Orthopedic',
    hospital: 'Square Hospital, Dhaka',
    rating: 4.5,
    experienceYears: 14,
    fee: 900,
    nextAvailable: 'Tomorrow 11 AM',
  ),
  DoctorSummary(
    name: 'Dr. Sadia Afrin',
    specialty: 'Dentist',
    hospital: 'Smile Dental Care',
    rating: 4.8,
    experienceYears: 9,
    fee: 700,
    nextAvailable: 'Today 4 PM',
  ),
  DoctorSummary(
    name: 'Dr. Rehana Begum',
    specialty: 'Gynecologist',
    hospital: 'LabAid Hospital, Dhaka',
    rating: 4.9,
    experienceYears: 18,
    fee: 900,
    nextAvailable: 'Tomorrow 9 AM',
  ),
  DoctorSummary(
    name: 'Dr. Anisur Rahman',
    specialty: 'ENT',
    hospital: 'Apollo Hospital, Dhaka',
    rating: 4.6,
    experienceYears: 11,
    fee: 650,
    nextAvailable: 'Today 3 PM',
  ),
  DoctorSummary(
    name: 'Dr. Fahmida Sultana',
    specialty: 'Psychiatrist',
    hospital: 'United Hospital, Dhaka',
    rating: 4.7,
    experienceYears: 7,
    fee: 750,
    nextAvailable: 'Tomorrow 2 PM',
  ),
  DoctorSummary(
    name: 'Dr. Zahidul Karim',
    specialty: 'Neurologist',
    hospital: 'Square Hospital, Dhaka',
    rating: 4.8,
    experienceYears: 16,
    fee: 1200,
    nextAvailable: 'Today 8 PM',
  ),
];

class SpecialistSelectionScreen extends StatefulWidget {
  const SpecialistSelectionScreen({super.key, required this.appointments, required this.onBook});

  final List<BookedAppointment> appointments;
  final ValueChanged<BookedAppointment> onBook;

  @override
  State<SpecialistSelectionScreen> createState() => _SpecialistSelectionScreenState();
}

class _SpecialistSelectionScreenState extends State<SpecialistSelectionScreen> {
  Specialty? _selectedSpecialty;

  void _handleSpecialtyTap(Specialty specialty) {
    setState(() {
      _selectedSpecialty = _selectedSpecialty?.name == specialty.name ? null : specialty;
    });
  }

  void _onDoctorSelected(DoctorSummary doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorProfileScreen(doctor: doctor, onBooked: widget.onBook),
      ),
    );
  }

  List<DoctorSummary> get _visibleDoctors {
    if (_selectedSpecialty == null) {
      return _mockDoctors.take(3).toList();
    }
    return _mockDoctors.where((d) => d.specialty == _selectedSpecialty!.name).toList();
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
            AppSearchBar(hintText: 'Search specialist or doctor name', onSubmitted: (_) {}),
            SizedBox(height: pad * 0.8),
            SpecialtyFilterChips(
              specialties: kSpecialties,
              selected: _selectedSpecialty,
              onSelected: _handleSpecialtyTap,
            ),
            SizedBox(height: pad * 0.5),
            Text(
              _selectedSpecialty == null ? 'Top Doctors' : '${_selectedSpecialty!.name} Specialists',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            if (doctors.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No doctors found for this specialty yet.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              )
            else
              for (int i = 0; i < doctors.length; i++) ...[
                if (i != 0) const SizedBox(height: 10),
                DoctorResultCard(doctor: doctors[i], onTap: () => _onDoctorSelected(doctors[i])),
              ],
          ],
        ),
      ),
    );
  }
}

const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final DateTime date = appointment.date;
    final String formattedDate = '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: MColors.primaryColor.withValues(alpha: 0.12),
              child: const Icon(Icons.event_available, color: MColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.doctorName, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    appointment.specialty,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formattedDate, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  appointment.time,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
