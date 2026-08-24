import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicus/Features/Authentication/Models/auth_account.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/pharmacy_registry_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/pharmacy_review_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/pharmacy_visit_service.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/pharmacies/pharmacy.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/pharmacies/pharmacy_review.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Widgets/pharmacies/pharmacy_card.dart';

// TODO: replace with the logged-in patient's AuthAccount once this screen
// receives it from PatientDashboardScreen (same mock pattern as
// patient_home_screen.dart).
const String _mockPatientId = '4821';
const String _mockPatientName = 'Tareq';

enum _LoadState { loading, success, permissionDenied, serviceDisabled, error }

class PharmacyLocatorScreen extends StatefulWidget {
  const PharmacyLocatorScreen({super.key, required this.account});

  final AuthAccount account;

  @override
  State<PharmacyLocatorScreen> createState() => _PharmacyLocatorScreenState();
}

class _PharmacyLocatorScreenState extends State<PharmacyLocatorScreen> {
  static const PharmacyRegistryService _registryService =
      PharmacyRegistryService();
  static const PharmacyReviewService _reviewService = PharmacyReviewService();
  static const PharmacyVisitService _visitService = PharmacyVisitService();

  _LoadState _state = _LoadState.loading;
  String? _errorMessage;
  Position? _position;
  List<NearbyPharmacy> _allPharmacies = [];
  Set<String> _visitedIds = {};
  Map<String, List<PharmacyReview>> _reviewsByPharmacy = {};
  GoogleMapController? _mapController;

  String get _patientId =>
      widget.account.userId.isEmpty ? _mockPatientId : widget.account.userId;
  String get _patientName => widget.account.firstName.isEmpty
      ? _mockPatientName
      : widget.account.firstName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = _LoadState.loading;
      _errorMessage = null;
    });

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _state = _LoadState.serviceDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _state = _LoadState.permissionDenied);
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final List<RegisteredPharmacy> pharmacies = await _registryService
          .fetchAllPharmacies();
      final Set<String> visitedIds = await _visitService
          .fetchVisitedPharmacyIds(_patientId);

      final List<NearbyPharmacy> withDistance =
          pharmacies
              .map(
                (p) => NearbyPharmacy(
                  pharmacy: p,
                  distanceMeters: Geolocator.distanceBetween(
                    position.latitude,
                    position.longitude,
                    p.lat,
                    p.lng,
                  ),
                ),
              )
              .toList()
            ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

      final Map<String, List<PharmacyReview>> reviewsByPharmacy = {
        for (final id in visitedIds) id: await _reviewService.fetchReviews(id),
      };

      if (!mounted) return;
      setState(() {
        _position = position;
        _allPharmacies = withDistance;
        _visitedIds = visitedIds;
        _reviewsByPharmacy = reviewsByPharmacy;
        _state = _LoadState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _LoadState.error;
        _errorMessage = '$e';
      });
    }
  }

  Future<void> _refreshPharmacyReviews(String pharmacyId) async {
    final List<PharmacyReview> reviews = await _reviewService.fetchReviews(
      pharmacyId,
    );
    if (!mounted) return;
    setState(
      () => _reviewsByPharmacy = {..._reviewsByPharmacy, pharmacyId: reviews},
    );
  }

  Future<void> _visitAndGetDirections(RegisteredPharmacy pharmacy) async {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pharmacy.lat},${pharmacy.lng}',
    );
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't open Google Maps for directions."),
          ),
        );
      }
      return;
    }

    await _visitService.markVisited(
      patientId: _patientId,
      pharmacyId: pharmacy.id,
    );
    if (!mounted) return;
    if (!_visitedIds.contains(pharmacy.id)) {
      setState(() => _visitedIds = {..._visitedIds, pharmacy.id});
      await _refreshPharmacyReviews(pharmacy.id);
    }
  }

  void _showPharmacyPreview(RegisteredPharmacy pharmacy) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(pharmacy.lat, pharmacy.lng)),
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pharmacy.name,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              if (pharmacy.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pharmacy.address,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
              if (pharmacy.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pharmacy.phone,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _visitAndGetDirections(pharmacy);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: MColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Get Directions'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPharmacyDetail(RegisteredPharmacy pharmacy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PharmacyDetailSheet(
        pharmacy: pharmacy,
        reviews: _reviewsByPharmacy[pharmacy.id] ?? const [],
        patientId: _patientId,
        patientName: _patientName,
        reviewService: _reviewService,
        onReviewsChanged: () => _refreshPharmacyReviews(pharmacy.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);

    return Container(
      color: isDark ? const Color(0xFF181818) : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pharmacies',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, pad)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double pad) {
    switch (_state) {
      case _LoadState.loading:
        return const _CenteredMessage(
          icon: Icons.local_pharmacy_outlined,
          message: 'Loading pharmacies near you…',
          showSpinner: true,
        );
      case _LoadState.serviceDisabled:
        return _CenteredMessage(
          icon: Icons.location_off_outlined,
          message:
              'Location services are turned off. Enable them to find pharmacies.',
          actionLabel: 'Open Location Settings',
          onAction: Geolocator.openLocationSettings,
        );
      case _LoadState.permissionDenied:
        return _CenteredMessage(
          icon: Icons.pin_drop_outlined,
          message: 'Medicus needs location access to show nearby pharmacies.',
          actionLabel: 'Open App Settings',
          onAction: Geolocator.openAppSettings,
        );
      case _LoadState.error:
        return _CenteredMessage(
          icon: Icons.error_outline_rounded,
          message: _errorMessage ?? 'Something went wrong.',
          actionLabel: 'Try Again',
          onAction: _load,
        );
      case _LoadState.success:
        return _buildSuccess(context, pad);
    }
  }

  Widget _buildSuccess(BuildContext context, double pad) {
    final Position position = _position!;
    final List<NearbyPharmacy> visited = _allPharmacies
        .where((p) => _visitedIds.contains(p.pharmacy.id))
        .toList();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(position.latitude, position.longitude),
                  zoom: 13,
                ),
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                markers: {
                  for (final NearbyPharmacy item in _allPharmacies)
                    Marker(
                      markerId: MarkerId(item.pharmacy.id),
                      position: LatLng(item.pharmacy.lat, item.pharmacy.lng),
                      icon: _visitedIds.contains(item.pharmacy.id)
                          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
                          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(title: item.pharmacy.name),
                      onTap: () => _showPharmacyPreview(item.pharmacy),
                    ),
                },
              ),
            ),
          ),
        ),
        SizedBox(height: pad * 0.6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Row(
            children: [
              Text(
                'My Pharmacies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              if (visited.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: MColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${visited.length}',
                    style: const TextStyle(
                      color: MColors.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: visited.isEmpty
              ? const _CenteredMessage(
                  icon: Icons.explore_outlined,
                  message:
                      "You haven't visited any pharmacies yet.\nTap a pin on the map and get directions to add it here.",
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 120),
                    itemCount: visited.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final NearbyPharmacy item = visited[i];
                      final List<PharmacyReview> reviews =
                          _reviewsByPharmacy[item.pharmacy.id] ?? const [];
                      return PharmacyCard(
                        item: item,
                        averageRating: PharmacyReviewService.averageRating(
                          reviews,
                        ),
                        reviewCount: reviews.length,
                        onTap: () => _openPharmacyDetail(item.pharmacy),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showSpinner = false,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: MColors.primaryColor,
                ),
              )
            else
              Icon(
                icon,
                size: 38,
                color: MColors.primaryColor.withValues(alpha: 0.7),
              ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: MColors.primaryColor,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PharmacyDetailSheet extends StatefulWidget {
  const _PharmacyDetailSheet({
    required this.pharmacy,
    required this.reviews,
    required this.patientId,
    required this.patientName,
    required this.reviewService,
    required this.onReviewsChanged,
  });

  final RegisteredPharmacy pharmacy;
  final List<PharmacyReview> reviews;
  final String patientId;
  final String patientName;
  final PharmacyReviewService reviewService;
  final VoidCallback onReviewsChanged;

  @override
  State<_PharmacyDetailSheet> createState() => _PharmacyDetailSheetState();
}

class _PharmacyDetailSheetState extends State<_PharmacyDetailSheet> {
  late List<PharmacyReview> _reviews;
  final TextEditingController _commentController = TextEditingController();
  int _myRating = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _reviews = widget.reviews;
    final existing = _reviews.where((r) => r.patientId == widget.patientId);
    if (existing.isNotEmpty) {
      _myRating = existing.first.rating;
      _commentController.text = existing.first.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_myRating == 0) return;
    setState(() => _submitting = true);
    try {
      await widget.reviewService.submitReview(
        pharmacyId: widget.pharmacy.id,
        patientId: widget.patientId,
        patientName: widget.patientName,
        rating: _myRating,
        comment: _commentController.text.trim(),
      );
      widget.onReviewsChanged();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double avg = PharmacyReviewService.averageRating(_reviews);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181818) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.pharmacy.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.pharmacy.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.pharmacy.address,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_reviews.isNotEmpty) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: Color(0xFFF5A623),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      ' (${_reviews.length} review${_reviews.length == 1 ? '' : 's'})',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ] else
                    Text(
                      'No reviews yet',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Your rating',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      onPressed: () => setState(() => _myRating = i),
                      icon: Icon(
                        i <= _myRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFF5A623),
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_myRating == 0 || _submitting) ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: MColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_submitting ? 'Submitting…' : 'Submit Review'),
                ),
              ),
              const SizedBox(height: 24),
              Text('Reviews', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              if (_reviews.isEmpty)
                Text(
                  'Be the first to review this pharmacy.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                )
              else
                for (final PharmacyReview review in _reviews) ...[
                  _ReviewTile(review: review),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final PharmacyReview review;

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.patientName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: const Color(0xFFF5A623),
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
