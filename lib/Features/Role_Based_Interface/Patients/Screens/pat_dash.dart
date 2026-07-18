import 'package:flutter/material.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidNavbar.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/home/patient_home_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/doctors/specialist_selection_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/pharmacies/pharmacy_locator_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Screens/profile/patient_profile_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/doctors/booked_appointment.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/records/prescription.dart';

// Mock data — replaced by a Firestore query (prescriptions collection for
// this patient, ordered by date) once the data layer is wired up. Each
// record mirrors what the doctor portal would save: an id, doctor, date,
// and its medicines — shared between the Home timeline and the Records
// screen so both reflect the same source of truth.
final List<Prescription> _initialPrescriptions = [
  Prescription(
    id: 'RX-1001',
    doctorName: 'Dr. Farhana Rahman',
    date: DateTime.now().subtract(const Duration(days: 12)),
    medicines: const [
      PrescriptionMedicine(name: 'Metformin 500mg', dosage: '1 tablet, twice daily', durationDays: 30),
    ],
  ),
  Prescription(
    id: 'RX-1002',
    doctorName: 'Dr. Kamrul Islam',
    date: DateTime.now().subtract(const Duration(days: 5)),
    medicines: const [
      PrescriptionMedicine(name: 'Amoxicillin 250mg', dosage: '1 capsule, three times daily', durationDays: 7),
    ],
  ),
  Prescription(
    id: 'RX-1003',
    doctorName: 'Dr. Nusrat Jahan',
    date: DateTime.now().subtract(const Duration(days: 20)),
    medicines: const [
      PrescriptionMedicine(name: 'Cetirizine 10mg', dosage: '1 tablet, once daily', durationDays: 5),
    ],
  ),
  Prescription(
    id: 'RX-1004',
    doctorName: 'Dr. Shafiul Alam',
    date: DateTime.now().subtract(const Duration(days: 45)),
    medicines: const [
      PrescriptionMedicine(name: 'Ibuprofen 400mg', dosage: '1 tablet, as needed', durationDays: 3),
    ],
  ),
];

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: _PatientHomeShell(),
    );
  }
}

class _PatientHomeShell extends StatefulWidget {
  const _PatientHomeShell();

  @override
  State<_PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<_PatientHomeShell> {
  int _index = 0;
  final List<BookedAppointment> _appointments = [];
  final List<Prescription> _prescriptions = List.of(_initialPrescriptions);

  final _items = const [
    LiquidNavItem(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    LiquidNavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Appointment'),
    LiquidNavItem(icon: Icons.local_pharmacy_outlined, selectedIcon: Icons.local_pharmacy, label: 'Pharmacies'),
    LiquidNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  void _addAppointment(BookedAppointment appointment) {
    setState(() => _appointments.add(appointment));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PatientHomeScreen(appointments: _appointments, prescriptions: _prescriptions),
      SpecialistSelectionScreen(appointments: _appointments, onBook: _addAppointment),
      const PharmacyLocatorScreen(),
      PatientProfileScreen(prescriptions: _prescriptions),
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
