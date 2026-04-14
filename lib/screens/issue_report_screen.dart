import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/issue_report_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({super.key});

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final FirestoreService _service = FirestoreService();
  bool _showNewReport = true;
  IssueCategory? _selectedCategory;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  List<IssueReport> _reports = [];
  final List<String> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    final reports = await _service.fetchMyReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedCategory == null) {
      _showSnack('Please select an issue category.', isError: true);
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showSnack('Please enter a location.', isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnack('Please provide a description.', isError: true);
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final report = IssueReport(
      id: '',
      category: _selectedCategory!.label,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      status: IssueStatus.submitted,
      submittedDate: DateTime.now(),
      userId: uid,
      attachments: List.from(_attachments),
    );
    await _service.submitReport(report);
    setState(() {
      _isSubmitting = false;
      _selectedCategory = null;
      _locationController.clear();
      _descriptionController.clear();
      _attachments.clear();
    });
    _showSnack('Report submitted successfully!');
    await _loadReports();
  }

  Future<void> _handleStatusUpdate(
    IssueReport report,
    IssueStatus newStatus,
  ) async {
    await _service.updateReportStatus(report.id, newStatus);
    _showSnack('Status updated to ${newStatus.label}');
    await _loadReports();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _showNewReport
                ? _buildNewReportForm()
                : _buildTrackReports(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: AppColors.lightMaroon,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Issue Reporting',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  _buildTabButton(
                    'New Report',
                    _showNewReport,
                    () => setState(() => _showNewReport = true),
                  ),
                  const SizedBox(width: 10),
                  _buildTabButton(
                    'Track Reports (${_reports.length})',
                    !_showNewReport,
                    () => setState(() => _showNewReport = false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.lightMaroon : Colors.white,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─── NEW REPORT FORM ──────────────────────────────────────────────────────

  Widget _buildNewReportForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Select Issue Category'),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
          const SizedBox(height: 24),
          _sectionLabel('Location'),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _locationController,
            hint: 'e.g., Main Library, Dorm 2, CS Lab',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 24),
          _sectionLabel('Description'),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _descriptionController,
            hint: 'Provide detailed information about the issue...',
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          _sectionLabel('Add Evidence (Optional)'),
          const SizedBox(height: 12),
          if (_attachments.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: List.generate(
                _attachments.length,
                (i) => Chip(
                  label: Text('Attachment ${i + 1}'),
                  onDeleted: () => setState(() => _attachments.removeAt(i)),
                  backgroundColor: AppColors.lightMaroon.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.lightMaroon),
                  deleteIconColor: AppColors.lightMaroon,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _evidenceButton(Icons.camera_alt_outlined, 'Camera', () {
                setState(
                  () =>
                      _attachments.add('camera_${_attachments.length + 1}.jpg'),
                );
                _showSnack('Photo from camera added');
              }),
              const SizedBox(width: 12),
              _evidenceButton(Icons.photo_library_outlined, 'Gallery', () {
                setState(
                  () =>
                      _attachments.add('photo_${_attachments.length + 1}.jpg'),
                );
                _showSnack('Photo from gallery added');
              }),
              const SizedBox(width: 12),
              _evidenceButton(Icons.mic_outlined, 'Voice Note', () {
                setState(
                  () =>
                      _attachments.add('audio_${_attachments.length + 1}.m4a'),
                );
                _showSnack('Voice note recorded');
              }),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightMaroon,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: IssueCategory.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) {
        final category = IssueCategory.values[i];
        final selected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.lightMaroon.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.lightMaroon
                    : const Color(0xFFE0E0E0),
                width: selected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 28,
                  color: selected
                      ? AppColors.lightMaroon
                      : const Color(0xFF1A1A1A),
                ),
                const SizedBox(height: 8),
                Text(
                  category.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.lightMaroon
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF9E9E9E), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: icon != null ? 4 : 14,
            vertical: maxLines > 1 ? 14 : 0,
          ),
        ),
      ),
    );
  }

  Widget _evidenceButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.lightMaroon, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1A1A),
    ),
  );

  // ─── TRACK REPORTS ────────────────────────────────────────────────────────

  Widget _buildTrackReports() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lightMaroon),
      );
    }
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No reports yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit your first issue report to get started',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _reportCard(_reports[i]),
    );
  }

  Widget _reportCard(IssueReport report) {
    return GestureDetector(
      onTap: () => _showReportDetails(report),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.id.isNotEmpty
                      ? report.id
                            .substring(
                              0,
                              report.id.length > 8 ? 8 : report.id.length,
                            )
                            .toUpperCase()
                      : 'NEW',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: report.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: report.status.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.category,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(report.submittedDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            if (report.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.attachment,
                    size: 14,
                    color: AppColors.lightMaroon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${report.attachments.length} attachment${report.attachments.length > 1 ? "s" : ""}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.lightMaroon,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReportDetails(IssueReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: report.status.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: report.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow('Location', report.location),
                const SizedBox(height: 8),
                _detailRow(
                  'Submitted',
                  DateFormat(
                    'MMM d, yyyy – hh:mm a',
                  ).format(report.submittedDate),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.description,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
                if (report.status != IssueStatus.resolved) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Update Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: IssueStatus.values
                        .where(
                          (s) =>
                              s != report.status && s != IssueStatus.submitted,
                        )
                        .map(
                          (s) => GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _handleStatusUpdate(report, s);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: s.color.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: s.color.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: s.color,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
