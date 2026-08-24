import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicus/Utilities/colors.dart';
import 'package:medicus/Utilities/helperFunctions.dart';
import 'package:medicus/Utilities/sizes.dart';
import 'package:medicus/Features/Role_Based_Interface/Patients/Utilities/lab_report_service.dart';

/// The digital replacement for bringing in a handwritten report on paper:
/// snap or pick a photo of it here and it's saved against the patient's
/// record, where the doctor's Patient Detail screen can see it.
class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key, required this.patientId, required this.patientName});

  final String patientId;
  final String patientName;

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  static const LabReportService _service = LabReportService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _labelController = TextEditingController();

  Uint8List? _pickedBytes;
  bool _uploading = false;
  late Future<List<LabReport>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _service.fetchForPatient(widget.patientId);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _reportsFuture = _service.fetchForPatient(widget.patientId));
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    setState(() => _pickedBytes = bytes);
  }

  Future<void> _showSourceSheet() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _upload() async {
    final Uint8List? bytes = _pickedBytes;
    if (bytes == null) return;

    setState(() => _uploading = true);
    try {
      await _service.upload(
        patientId: widget.patientId,
        patientName: widget.patientName,
        label: _labelController.text,
        imageBytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _pickedBytes = null;
        _labelController.clear();
      });
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report uploaded — your doctor can now see it.')),
      );
    } on LabReportTooLargeException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This image is too large even after compression — try a clearer, closer photo.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _viewFull(LabReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReportViewerScreen(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);
    final double pad = Sizes.responsivePadding(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181818) : Colors.white,
      appBar: AppBar(title: const Text('Upload Report')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.6, pad, pad * 2),
          children: [
            Text(
              'Take a photo of a handwritten or printed report so your doctor can view it — no more carrying the paper copy in.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            SizedBox(height: pad),
            if (_pickedBytes == null)
              InkWell(
                onTap: _showSourceSheet,
                borderRadius: BorderRadius.circular(16),
                child: DottedFrame(
                  isDark: isDark,
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: MColors.primaryColor, size: 32),
                        const SizedBox(height: 8),
                        Text('Tap to take or choose a photo', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(_pickedBytes!, height: 220, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _showSourceSheet,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retake / choose another'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'e.g. Blood test — 12 Mar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_outlined),
                  label: Text(_uploading ? 'Uploading…' : 'Upload report'),
                ),
              ),
            ],
            SizedBox(height: pad * 1.4),
            Text('Previously uploaded', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FutureBuilder<List<LabReport>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: MColors.primaryColor)),
                  );
                }
                if (snapshot.hasError) {
                  return Text('Could not load reports: ${snapshot.error}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey));
                }
                final List<LabReport> reports = snapshot.data ?? const [];
                if (reports.isEmpty) {
                  return Text('No reports uploaded yet.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey));
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) => _ReportThumbnail(report: reports[index], onTap: () => _viewFull(reports[index])),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DottedFrame extends StatelessWidget {
  const DottedFrame({super.key, required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MColors.primaryColor.withValues(alpha: 0.4), width: 1.4),
        borderRadius: BorderRadius.circular(16),
        color: MColors.primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
      ),
      child: child,
    );
  }
}

class _ReportThumbnail extends StatelessWidget {
  const _ReportThumbnail({required this.report, required this.onTap});

  final LabReport report;
  final VoidCallback onTap;

  String get _formattedDate =>
      '${report.uploadedAt.day.toString().padLeft(2, '0')}/${report.uploadedAt.month.toString().padLeft(2, '0')}/${report.uploadedAt.year}';

  @override
  Widget build(BuildContext context) {
    final bool isDark = MHelperFunctions.isDarkMode(context);

    return Material(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Image.memory(report.imageBytes, width: double.infinity, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_formattedDate, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportViewerScreen extends StatelessWidget {
  const _ReportViewerScreen({required this.report});

  final LabReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(report.label),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(report.imageBytes),
        ),
      ),
    );
  }
}
