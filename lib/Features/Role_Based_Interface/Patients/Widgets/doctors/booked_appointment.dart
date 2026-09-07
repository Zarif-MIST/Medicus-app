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
    this.serialNumber = 0,
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

  /// This patient's first-come-first-served position within [windowId] —
  /// the "serial number" shown instead of an exact appointment time,
  /// matching how a real chamber's queue works. 0 for a legacy booking made
  /// before this field existed.
  final int serialNumber;

  int get daysFromNow {
    final DateTime today = DateTime.now();
    final DateTime justDate = DateTime(date.year, date.month, date.day);
    final DateTime justToday = DateTime(today.year, today.month, today.day);
    return justDate.difference(justToday).inDays.clamp(0, 9999);
  }

  /// [time] is a "start - end" clock-range label (e.g. "4:00 PM - 6:00 PM"),
  /// as produced by [DoctorAvailabilityWindow.label]. Returns the moment the
  /// window ends on [date], or null if [time] isn't in that shape.
  DateTime? get _windowEnd {
    final List<String> parts = time.split(' - ');
    if (parts.length != 2) return null;

    final Match? match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(parts.last.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String period = match.group(3)!;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// True once this appointment's booked time window has fully elapsed —
  /// e.g. a "9:00 AM - 11:00 AM" slot booked for today stops being "upcoming"
  /// once it's past 11 AM today, not only once the date itself is in the
  /// past. Falls back to a date-only check if [time] isn't a parseable
  /// range (defensive — every booking currently produces one).
  bool get hasEnded {
    final DateTime? windowEnd = _windowEnd;
    if (windowEnd != null) {
      return DateTime.now().isAfter(windowEnd);
    }

    final DateTime today = DateTime.now();
    final DateTime todayOnly = DateTime(today.year, today.month, today.day);
    return DateTime(date.year, date.month, date.day).isBefore(todayOnly);
  }
}
