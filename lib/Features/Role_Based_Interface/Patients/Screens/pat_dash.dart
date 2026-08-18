import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/home/patient_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/specialist_selection_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/pharmacies/pharmacy_locator_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/profile/patient_profile_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Services/appointment_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Services/prescription_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _PatientHomeShell(account: account));
  }
}

class _PatientHomeShell extends StatefulWidget {
  const _PatientHomeShell({required this.account});

  final AuthAccount account;

  @override
  State<_PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<_PatientHomeShell> {
  int _index = 0;
  List<BookedAppointment> _appointments = [];
  List<Prescription> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    List<BookedAppointment> appointments = const [];
    List<Prescription> prescriptions = const [];

    try {
      appointments = await AppointmentService.instance.getUpcomingAppointments(
        widget.account.userId,
      );
    } catch (error) {
      debugPrint('Failed to load appointments: $error');
    }

    try {
      prescriptions = await PrescriptionService.instance
          .getPrescriptionsForPatient(widget.account.userId);
    } catch (error) {
      debugPrint('Failed to load prescriptions: $error');
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _appointments = appointments;
      _prescriptions = prescriptions;
    });
  }

  final _items = const [
    LiquidNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    LiquidNavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Appointment',
    ),
    LiquidNavItem(
      icon: Icons.local_pharmacy_outlined,
      selectedIcon: Icons.local_pharmacy,
      label: 'Pharmacies',
    ),
    LiquidNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _addAppointment(BookedAppointment appointment) {
    setState(() => _appointments.add(appointment));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PatientHomeScreen(
        account: widget.account,
        appointments: _appointments,
        prescriptions: _prescriptions,
      ),
      SpecialistSelectionScreen(
        account: widget.account,
        appointments: _appointments,
        onBook: _addAppointment,
      ),
      PharmacyLocatorScreen(account: widget.account),
      PatientProfileScreen(
        account: widget.account,
        prescriptions: _prescriptions,
      ),
    ];

    return Scaffold(
      // extendBody lets page content flow behind the nav bar so the
      // BackdropFilter actually has something colorful to blur.
      extendBody: true,
      body: Stack(
        children: [
          pages[_index],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassNavBar(
              items: _items,
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}
