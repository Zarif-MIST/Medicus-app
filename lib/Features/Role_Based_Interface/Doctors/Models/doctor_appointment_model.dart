class DoctorAppointmentModel {
  const DoctorAppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.specialty,
    required this.reason,
    required this.timeLabel,
    required this.status,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String specialty;
  final String reason;
  final String timeLabel;
  final String status;
}
