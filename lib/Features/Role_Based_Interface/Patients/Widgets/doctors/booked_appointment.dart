class BookedAppointment {
  const BookedAppointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.time,
    required this.fee,
    required this.status,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime date;
  final String time;
  final int fee;
  final String status;

  int get daysFromNow {
    final DateTime today = DateTime.now();
    final DateTime justDate = DateTime(date.year, date.month, date.day);
    final DateTime justToday = DateTime(today.year, today.month, today.day);
    return justDate.difference(justToday).inDays.clamp(0, 9999);
  }
}
