import 'package:flutter/material.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/doctor_appointment_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Models/patient_record_model.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Screens/patient_detail_screen.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Services/doctor_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/LiquidSearchBar.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/customShapes.dart';
import 'package:medicus/Features/Role_Based_Interface/Doctors/Widgets/empty_appointments.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({
    super.key,
    required this.account,
    required this.onOpenScanner,
    required this.onOpenAppointments,
  });

  final AuthAccount account;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenAppointments;

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeData {
  const _DoctorHomeData({
    required this.appointments,
    required this.seenPatientIds,
  });

  final List<DoctorAppointmentModel> appointments;
  final Set<String> seenPatientIds;
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  late Future<_DoctorHomeData> _homeDataFuture;
  String _searchQuery = '';
  bool _isSearchingPatients = false;
  List<PatientRecordModel> _searchedPatients = const <PatientRecordModel>[];

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _loadHomeData();
  }

  Future<_DoctorHomeData> _loadHomeData() async {
    final results = await (
      DoctorService.instance.getTodayAppointments(widget.account),
      DoctorService.instance.getPatientsSeenTodayIds(widget.account.userId),
    ).wait;

    return _DoctorHomeData(appointments: results.$1, seenPatientIds: results.$2);
  }

  String get _todayLabel {
    final DateTime now = DateTime.now();
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
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
      body: FutureBuilder<_DoctorHomeData>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          final bool isDark = MHelperFunctions.isDarkMode(context);
          final List<DoctorAppointmentModel> appointments =
              snapshot.data?.appointments ?? <DoctorAppointmentModel>[];
          final Set<String> seenPatientIds =
              snapshot.data?.seenPatientIds ?? <String>{};
          final List<DoctorAppointmentModel> pendingAppointments = appointments
              .where((appointment) => !seenPatientIds.contains(appointment.patientId))
              .toList();
          final DoctorAppointmentModel? nextAppointment =
              pendingAppointments.isNotEmpty
              ? pendingAppointments.first
              : (appointments.isNotEmpty ? appointments.first : null);
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
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if ((widget.account.specialty ?? '')
                                            .isNotEmpty)
                                          _HeaderChip(
                                            icon: Icons.medical_services_outlined,
                                            label: widget.account.specialty!,
                                          ),
                                        const _HeaderChip(
                                          icon: Icons.schedule_outlined,
                                          label: '8:00 AM – 2:00 PM',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),
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
                      _ResponsiveStatGrid(
                        tiles: [
                          _DoctorStatTile(
                            icon: Icons.calendar_today_outlined,
                            label: "Today's Queue",
                            value: appointments.length,
                            isDark: isDark,
                            onTap: widget.onOpenAppointments,
                            actionLabel: 'View queue',
                          ),
                          _DoctorStatTile(
                            icon: Icons.groups_outlined,
                            label: 'Patients Seen',
                            value: seenPatientIds.length,
                            isDark: isDark,
                            subtitle: _todayLabel,
                          ),
                          _DoctorStatTile(
                            icon: Icons.pending_actions_outlined,
                            label: 'Pending Cases',
                            value: pendingAppointments.length,
                            isDark: isDark,
                          ),
                          _DoctorStatTile(
                            icon: Icons.timer_outlined,
                            label: 'Avg. Consult Time',
                            value: widget.account.consultationMinutes,
                            suffix: ' min',
                            isDark: isDark,
                          ),
                        ],
                      ),
                      if (nextAppointment != null) ...[
                        const SizedBox(height: 16),
                        _NextUpCard(
                          account: widget.account,
                          appointment: nextAppointment,
                          isDark: isDark,
                        ),
                      ],
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
                      else if (appointments.isEmpty)
                        const EmptyAppointmentsPlaceholder(
                          subtitle:
                              'Your queue is clear — new bookings will show up here.',
                        )
                      else if (visibleAppointments.isEmpty)
                        Text(
                          'No patients matched the current search.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        )
                      else
                        for (final (index, appointment)
                            in visibleAppointments.indexed) ...[
                          _FadeSlideIn(
                            delay: Duration(milliseconds: 60 * index),
                            child: _DoctorQueueTile(
                              account: widget.account,
                              appointment: appointment,
                            ),
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

class _DoctorStatTile extends StatelessWidget {
  const _DoctorStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
    this.subtitle,
    this.actionLabel,
    this.suffix = '',
  });

  final IconData icon;
  final String label;
  final int value;
  final bool isDark;
  final VoidCallback? onTap;

  /// Small grey line under the label — used to show today's date.
  final String? subtitle;
  final String? actionLabel;

  /// Appended after the animated number, e.g. ' min'.
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MColors.primaryColor.withValues(
                    alpha: isDark ? 0.18 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: MColors.primaryColor, size: 16),
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return Text(
                      '${animatedValue.round()}$suffix',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel ?? 'View',
                      style: const TextStyle(
                        color: MColors.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: MColors.primaryColor,
                      size: 12,
                    ),
                  ],
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays the given stat tiles out in a grid that adapts its column count to
/// the available width, so cards never overflow on narrow phones and use
/// the extra room on wider screens instead of staying cramped at 3-across.
class _ResponsiveStatGrid extends StatelessWidget {
  const _ResponsiveStatGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    const double spacing = 10;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = maxWidth >= 560
            ? 4
            : maxWidth >= 420
            ? 3
            : 2;
        final double tileWidth =
            (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}

/// A small translucent pill shown in the header — used for the doctor's
/// specialty and their fixed clinic hours.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Highlights the patient the doctor should see next — the first
/// not-yet-prescribed appointment in today's queue — with a gently
/// pulsing "Up next" badge.
class _NextUpCard extends StatefulWidget {
  const _NextUpCard({
    required this.account,
    required this.appointment,
    required this.isDark,
  });

  final AuthAccount account;
  final DoctorAppointmentModel appointment;
  final bool isDark;

  @override
  State<_NextUpCard> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<_NextUpCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(
    begin: 0.4,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openPatient(BuildContext context) async {
    final record = await DoctorService.instance.getPatientRecordById(
      widget.appointment.patientId,
    );
    if (!context.mounted || record == null) {
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PatientDetailScreen(record: record)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openPatient(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MColors.primaryColor.withValues(
              alpha: widget.isDark ? 0.18 : 0.08,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: MColors.primaryColor.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: MColors.primaryColor.withValues(alpha: 0.16),
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
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, child) => Opacity(
                            opacity: _pulse.value,
                            child: child,
                          ),
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: MColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'UP NEXT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: MColors.primaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.appointment.patientName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.appointment.timeLabel} • ${widget.appointment.reason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: MColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and slides a child in on first build — used to stagger the queue
/// list's entrance by giving each tile an increasing [delay].
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        child: widget.child,
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
