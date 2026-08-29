import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/bangladesh_hospitals.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/doctor_directory.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/pharmacy_registry_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/prescription_pdf.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/common/app_search_bar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/doctor_result_card.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/pharmacies/pharmacy.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/doctor_profile_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

/// A real cross-cutting search over the patient's own world: doctors,
/// prescriptions/medicines, registered pharmacies, emergency hospitals, and
/// the patient's own appointments — not the decorative, no-op field the home
/// header used to have.
class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({
    super.key,
    required this.initialQuery,
    required this.prescriptions,
    required this.appointments,
    required this.onBookAppointment,
    required this.patientId,
    required this.patientName,
  });

  final String initialQuery;
  final List<Prescription> prescriptions;
  final List<BookedAppointment> appointments;
  final ValueChanged<BookedAppointment> onBookAppointment;
  final String patientId;
  final String patientName;

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  static const DoctorDirectoryService _directoryService = DoctorDirectoryService();
  static const PharmacyRegistryService _pharmacyService = PharmacyRegistryService();

  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery;
  List<DoctorSummary> _allDoctors = [];
  List<RegisteredPharmacy> _allPharmacies = [];

  @override
  void initState() {
    super.initState();
    _directoryService.fetchAllDoctors().then((doctors) {
      if (!mounted) return;
      setState(() => _allDoctors = doctors);
    }).catchError((_) {
      // Leave doctors empty on failure — search for them just won't match
      // anything rather than crashing the screen.
    });
    _pharmacyService.fetchAllPharmacies().then((pharmacies) {
      if (!mounted) return;
      setState(() => _allPharmacies = pharmacies);
    }).catchError((_) {
      // Same graceful degradation for pharmacies.
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DoctorSummary> get _matchingDoctors {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _allDoctors
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q) ||
              d.hospital.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Prescription> get _matchingPrescriptions {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.prescriptions
        .where(
          (p) =>
              p.doctorName.toLowerCase().contains(q) ||
              p.medicines.any((m) => m.name.toLowerCase().contains(q)),
        )
        .toList();
  }

  List<RegisteredPharmacy> get _matchingPharmacies {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _allPharmacies
        .where((p) => p.name.toLowerCase().contains(q) || p.address.toLowerCase().contains(q))
        .toList();
  }

  List<HospitalContact> get _matchingHospitals {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return kNearbyHospitals
        .where((h) => h.name.toLowerCase().contains(q) || h.area.toLowerCase().contains(q))
        .toList();
  }

  List<BookedAppointment> get _matchingAppointments {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.appointments
        .where(
          (a) =>
              a.doctorName.toLowerCase().contains(q) ||
              a.specialty.toLowerCase().contains(q) ||
              a.hospital.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _viewPdf(Prescription prescription) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildPrescriptionPdf(
        prescription: prescription,
        patientName: widget.patientName,
        patientId: widget.patientId,
      ),
    );
  }

  void _openDoctor(DoctorSummary doctor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorProfileScreen(
          doctor: doctor,
          onBooked: widget.onBookAppointment,
          appointments: widget.appointments,
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the phone dialer on this device.")),
      );
    }
  }

  Future<void> _directionsTo(RegisteredPharmacy pharmacy) async {
    final Uri uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${pharmacy.lat},${pharmacy.lng}');
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open Google Maps for directions.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);
    final String q = _query.trim();
    final List<DoctorSummary> doctors = _matchingDoctors;
    final List<Prescription> prescriptions = _matchingPrescriptions;
    final List<RegisteredPharmacy> pharmacies = _matchingPharmacies;
    final List<HospitalContact> hospitals = _matchingHospitals;
    final List<BookedAppointment> appointments = _matchingAppointments;
    final bool hasQuery = q.isNotEmpty;
    final bool hasResults = doctors.isNotEmpty ||
        prescriptions.isNotEmpty ||
        pharmacies.isNotEmpty ||
        hospitals.isNotEmpty ||
        appointments.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchBar(
                hintText: 'Search doctors, medicines, pharmacies, hospitals…',
                controller: _controller,
                autofocus: widget.initialQuery.isEmpty,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: !hasQuery
                    ? _EmptyHint(
                        text: 'Search for a doctor, specialty, medicine, pharmacy, hospital, or one of your own appointments.',
                      )
                    : !hasResults
                        ? _EmptyHint(text: 'No matches for "$q".')
                        : ListView(
                            children: [
                              if (doctors.isNotEmpty) ...[
                                Text('Doctors', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                for (int i = 0; i < doctors.length; i++) ...[
                                  if (i != 0) const SizedBox(height: 10),
                                  DoctorResultCard(doctor: doctors[i], onTap: () => _openDoctor(doctors[i])),
                                ],
                                SizedBox(height: pad),
                              ],
                              if (appointments.isNotEmpty) ...[
                                Text('Your Appointments', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                for (int i = 0; i < appointments.length; i++) ...[
                                  if (i != 0) const SizedBox(height: 10),
                                  _AppointmentResultTile(appointment: appointments[i]),
                                ],
                                SizedBox(height: pad),
                              ],
                              if (prescriptions.isNotEmpty) ...[
                                Text('Prescriptions & Medicines', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                for (int i = 0; i < prescriptions.length; i++) ...[
                                  if (i != 0) const SizedBox(height: 10),
                                  _PrescriptionResultTile(
                                    prescription: prescriptions[i],
                                    onTap: () => _viewPdf(prescriptions[i]),
                                  ),
                                ],
                                SizedBox(height: pad),
                              ],
                              if (pharmacies.isNotEmpty) ...[
                                Text('Pharmacies', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                for (int i = 0; i < pharmacies.length; i++) ...[
                                  if (i != 0) const SizedBox(height: 10),
                                  _PharmacyResultTile(
                                    pharmacy: pharmacies[i],
                                    onCall: () => _call(pharmacies[i].phone),
                                    onDirections: () => _directionsTo(pharmacies[i]),
                                  ),
                                ],
                                SizedBox(height: pad),
                              ],
                              if (hospitals.isNotEmpty) ...[
                                Text('Hospitals', style: theme.textTheme.titleMedium),
                                const SizedBox(height: 12),
                                for (int i = 0; i < hospitals.length; i++) ...[
                                  if (i != 0) const SizedBox(height: 10),
                                  _HospitalResultTile(hospital: hospitals[i], onCall: () => _call(hospitals[i].phone)),
                                ],
                              ],
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionResultTile extends StatelessWidget {
  const _PrescriptionResultTile({required this.prescription, required this.onTap});

  final Prescription prescription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);
    final String medicines = prescription.medicines.map((m) => m.name).join(', ');

    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                child: const Icon(Icons.description_outlined, color: MColors.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(medicines, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      prescription.doctorName,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.picture_as_pdf_outlined, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentResultTile extends StatelessWidget {
  const _AppointmentResultTile({required this.appointment});

  final BookedAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 3)),
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
            child: const Icon(Icons.event_outlined, color: MColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.doctorName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${appointment.specialty} · ${appointment.hospital} · ${appointment.time}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyResultTile extends StatelessWidget {
  const _PharmacyResultTile({required this.pharmacy, required this.onCall, required this.onDirections});

  final RegisteredPharmacy pharmacy;
  final VoidCallback onCall;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 3)),
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
            child: const Icon(Icons.local_pharmacy_outlined, color: MColors.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pharmacy.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (pharmacy.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(pharmacy.address, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(onPressed: onDirections, icon: const Icon(Icons.directions_outlined, color: MColors.primaryColor)),
          IconButton(onPressed: onCall, icon: const Icon(Icons.call_outlined, color: MColors.primaryColor)),
        ],
      ),
    );
  }
}

class _HospitalResultTile extends StatelessWidget {
  const _HospitalResultTile({required this.hospital, required this.onCall});

  final HospitalContact hospital;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 3)),
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
                Text(hospital.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(hospital.area, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(onPressed: onCall, icon: const Icon(Icons.call_outlined, color: MColors.primaryColor)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ),
    );
  }
}
