import 'package:flutter/material.dart';

enum AuthRole { doctor, pharmacist, patient, labSpecialist }

extension AuthRoleX on AuthRole {
  String get label {
    switch (this) {
      case AuthRole.doctor:
        return 'Doctor';
      case AuthRole.pharmacist:
        return 'Pharmacist';
      case AuthRole.patient:
        return 'Patient';
      case AuthRole.labSpecialist:
        return 'Lab Specialist';
    }
  }

  String get shortLabel {
    switch (this) {
      case AuthRole.doctor:
        return 'Doctor';
      case AuthRole.pharmacist:
        return 'Pharmacist';
      case AuthRole.patient:
        return 'Patient';
      case AuthRole.labSpecialist:
        return 'Lab';
    }
  }

  IconData get icon {
    switch (this) {
      case AuthRole.doctor:
        return Icons.medical_services;
      case AuthRole.pharmacist:
        return Icons.local_pharmacy;
      case AuthRole.patient:
        return Icons.person;
      case AuthRole.labSpecialist:
        return Icons.science;
    }
  }
}
