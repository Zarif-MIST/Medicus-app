import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/patient_detail_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/home/stat_card_row.dart';
import 'package:medicus/Utilities/colors.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({
    super.key,
    required this.account,
    required this.onOpenScanner,
  });

  final AuthAccount account;
  final VoidCallback onOpenScanner;

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  late Future<List<DoctorAppointmentModel>> _appointmentsFuture;
  String _searchQuery = '';
  bool _isSearchingPatients = false;
  List<PatientRecordModel> _searchedPatients = const <PatientRecordModel>[];

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = DoctorService.instance.getTodayAppointments(
      widget.account,
    );
  }

  Future<void> _runPatientSearch(String value) async {
    final String query = value.trim();

    setState(() {
      _searchQuery = value;
      if (query.isEmpty) {
        _searchedPatients = const <PatientRecordModel>[];
      } else {
        _isSearchingPatients = true;
      }
    });

    if (query.isEmpty) {
      return;
    }

    final List<PatientRecordModel> results = await DoctorService.instance
        .searchPatients(query);

    if (!mounted || _searchQuery.trim() != query) {
      return;
    }

    setState(() {
      _searchedPatients = results;
      _isSearchingPatients = false;
    });
  }

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DoctorAppointmentModel>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          final List<DoctorAppointmentModel> appointments =
              snapshot.data ?? <DoctorAppointmentModel>[];
          final visibleAppointments = appointments.where((appointment) {
            final String query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) {
              return true;
            }
            return appointment.patientId.toLowerCase().contains(query) ||
                appointment.patientName.toLowerCase().contains(query);
          }).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                ClipPath(
                  clipper: MCurvedEdges(),
                  child: Container(
                    color: MColors.primaryColor,
                    child: SizedBox(
                      height: 390,
                      child: Stack(
                        children: [
                          const Positioned(
                            top: -150,
                            right: -250,
                            child: MCircularPath(),
                          ),
                          const Positioned(
                            top: 100,
                            right: -300,
                            child: MCircularPath(),
                          ),
                          Positioned.fill(
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 50),
                                    Text(
                                      _greeting(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.account.fullName.isEmpty
                                          ? 'Doctor'
                                          : widget.account.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const SizedBox(height: 28),
                                    LiquidGlassSearchBar(
                                      hintText: 'Search patient ID',
                                      onChanged: _runPatientSearch,
                                      onSubmitted: _runPatientSearch,
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.center,
                                      child: IconButton(
                                        onPressed: widget.onOpenScanner,
                                        icon: const Icon(Icons.qr_code_scanner),
                                        color: Colors.white,
                                        iconSize: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatCardRow(
                        stats: [
                          StatCardData(
                            label: 'Patients Seen',
                            value: 18,
                            icon: Icons.groups_outlined,
                          ),
                          StatCardData(
                            label: 'Pending Cases',
                            value: 5,
                            icon: Icons.pending_actions_outlined,
                          ),
                          StatCardData(
                            label: 'Today Queue',
                            value: appointments.length,
                            icon: Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Today\'s Queue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (!snapshot.hasData)
                        const Center(
                          child: CircularProgressIndicator(
                            color: MColors.primaryColor,
                          ),
                        )
                      else if (visibleAppointments.isEmpty)
                        Text(
                          'No patients matched the current search.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        )
                      else
                        for (final appointment in visibleAppointments) ...[
                          _DoctorQueueTile(
                            account: widget.account,
                            appointment: appointment,
                          ),
                          const SizedBox(height: 12),
                        ],
                      if (_searchQuery.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Patient Search Results',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        if (_isSearchingPatients)
                          const Center(
                            child: CircularProgressIndicator(
                              color: MColors.primaryColor,
                            ),
                          )
                        else if (_searchedPatients.isEmpty)
                          Text(
                            'No patient records matched your search.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          )
                        else
                          for (final patient in _searchedPatients) ...[
                            _PatientSearchTile(record: patient),
                            const SizedBox(height: 10),
                          ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PatientSearchTile extends StatelessWidget {
  const _PatientSearchTile({required this.record});

  final PatientRecordModel record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.26
                  : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: MColors.primaryColor.withValues(alpha: 0.12),
            child: const Icon(Icons.person_outline, color: MColors.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.account.fullName, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Patient ID: ${record.account.userId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PatientDetailScreen(record: record),
                ),
              );
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _DoctorQueueTile extends StatelessWidget {
  const _DoctorQueueTile({required this.account, required this.appointment});

  final AuthAccount account;
  final DoctorAppointmentModel appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.26
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: MColors.primaryColor.withValues(alpha: 0.14),
            child: const Icon(
              Icons.person_outline,
              color: MColors.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.timeLabel} • ${appointment.reason}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final record = await DoctorService.instance.getPatientRecordById(
                appointment.patientId,
              );
              if (!context.mounted || record == null) {
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PatientDetailScreen(record: record),
                ),
              );
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class MCircularPath extends StatelessWidget {
  const MCircularPath({
    super.key,
    this.radius = 400,
    this.width = 400,
    this.height = 400,
    this.backgroundColor = Colors.white,
  });

  final double radius;
  final double width;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: backgroundColor.withValues(alpha: 0.1),
      ),
    );
  }
}
