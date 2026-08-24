class BookedAppointment {
  const BookedAppointment({
    this.id = '',
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.time,
    required this.fee,
    this.windowId = '',
  });

  /// Firestore document id once persisted; empty for a freshly-built booking
  /// that hasn't been written yet.
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime date;
  final String time;
  final int fee;

  /// The availability window this was booked against, if any — lets the
  /// backend count bookings per window to enforce its capacity.
  final String windowId;

  int get daysFromNow {
    final DateTime today = DateTime.now();
    final DateTime justDate = DateTime(date.year, date.month, date.day);
    final DateTime justToday = DateTime(today.year, today.month, today.day);
    return justDate.difference(justToday).inDays.clamp(0, 9999);
  }
}
