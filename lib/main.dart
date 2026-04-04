import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASHESI LIFE - Issue Reporting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IssueReportPage(),
    );
  }
}

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
const Color kMaroon = Color(0xFF8B2E3D);
const Color kMaroonLight = Color(0xFFA03347);
const Color kBackground = Color(0xFFF5F5F5);
const Color kCardBg = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFE0E0E0);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF9E9E9E);
const Color kTabActive = Color(0xFFFFFFFF);
const Color kTabInactive = Color(0x33FFFFFF);

// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
enum IssueCategory { facilities, it, residence, security, other }

extension IssueCategoryExt on IssueCategory {
  String get label {
    switch (this) {
      case IssueCategory.facilities:
        return 'Facilities Maintenance';
      case IssueCategory.it:
        return 'IT Problems';
      case IssueCategory.residence:
        return 'Residence Life';
      case IssueCategory.security:
        return 'Security & Safety';
      case IssueCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case IssueCategory.facilities:
        return Icons.build_outlined;
      case IssueCategory.it:
        return Icons.computer_outlined;
      case IssueCategory.residence:
        return Icons.home_outlined;
      case IssueCategory.security:
        return Icons.lock_outlined;
      case IssueCategory.other:
        return Icons.edit_note_outlined;
    }
  }
}

enum IssueStatus { submitted, underReview, inProgress, resolved }

extension IssueStatusExt on IssueStatus {
  String get label {
    switch (this) {
      case IssueStatus.submitted:
        return 'Submitted';
      case IssueStatus.underReview:
        return 'Under Review';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
    }
  }

  Color get color {
    switch (this) {
      case IssueStatus.submitted:
        return const Color(0xFF4F46E5);
      case IssueStatus.underReview:
        return const Color(0xFFD97706);
      case IssueStatus.inProgress:
        return const Color(0xFF3B82F6);
      case IssueStatus.resolved:
        return const Color(0xFF059669);
    }
  }
}

class IssueReport {
  final String id;
  final String category;
  final String location;
  final String description;
  final IssueStatus status;
  final DateTime submittedDate;
  final List<String> attachments;

  IssueReport({
    required this.id,
    required this.category,
    required this.location,
    required this.description,
    required this.status,
    required this.submittedDate,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'location': location,
      'description': description,
      'status': status.toString(),
      'submittedDate': submittedDate.toIso8601String(),
      'attachments': attachments,
    };
  }

  factory IssueReport.fromJson(Map<String, dynamic> json) {
    return IssueReport(
      id: json['id'] as String,
      category: json['category'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      status: IssueStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => IssueStatus.submitted,
      ),
      submittedDate: DateTime.parse(json['submittedDate'] as String),
      attachments: List<String>.from(json['attachments'] as List? ?? []),
    );
  }
}

// ─────────────────────────────────────────────
// MAIN PAGE
// ─────────────────────────────────────────────
class IssueReportPage extends StatefulWidget {
  const IssueReportPage({super.key});

  @override
  State<IssueReportPage> createState() => _IssueReportPageState();
}

class _IssueReportPageState extends State<IssueReportPage> {
  bool _showNewReport = true;
  IssueCategory? _selectedCategory;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  List<IssueReport> _reports = [];
  final List<String> _attachments = [];
  String _currentPage = 'Reports'; // Track which page is active

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
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getStringList('reports') ?? [];
    setState(() {
      _reports = reportsJson.map((json) => IssueReport.fromJson(jsonDecode(json))).toList();
      _reports.sort((a, b) => b.submittedDate.compareTo(a.submittedDate));
    });
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = _reports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('reports', reportsJson);
  }

  void _pickImage() async {
    setState(() {
      _attachments.add('photo_${_attachments.length + 1}.jpg');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo from gallery added')),
      );
    }
  }

  void _capturePhoto() async {
    setState(() {
      _attachments.add('camera_${_attachments.length + 1}.jpg');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo from camera added')),
      );
    }
  }

  void _recordVoiceNote() {
    setState(() {
      _attachments.add('audio_${_attachments.length + 1}.m4a');
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice note recorded')),
      );
    }
  }

  void _onSubmit() async {
    if (_selectedCategory == null) {
      _showError('Please select an issue category.');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter a location.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please provide a description.');
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final newReport = IssueReport(
      id: 'RPT-${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      category: _selectedCategory!.label,
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      status: IssueStatus.submitted,
      submittedDate: DateTime.now(),
      attachments: _attachments,
    );

    setState(() {
      _reports.insert(0, newReport);
      _isSubmitting = false;
      _selectedCategory = null;
      _locationController.clear();
      _descriptionController.clear();
      _attachments.clear();
    });

    await _saveReports();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report ${newReport.id} submitted successfully!'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _updateReportStatus(IssueReport report, IssueStatus newStatus) async {
    final index = _reports.indexOf(report);
    if (index != -1) {
      final updatedReport = IssueReport(
        id: report.id,
        category: report.category,
        location: report.location,
        description: report.description,
        status: newStatus,
        submittedDate: report.submittedDate,
        attachments: report.attachments,
      );
      setState(() {
        _reports[index] = updatedReport;
      });
      await _saveReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report status updated to ${newStatus.label}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: _currentPage == 'Reports'
          ? Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _showNewReport ? _buildNewReportForm() : _buildTrackReports(),
                ),
              ],
            )
          : _buildPageContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Page Content Builder ─────────────────────
  Widget _buildPageContent() {
    switch (_currentPage) {
      case 'Clubs':
        return _buildClubsPage();
      case 'Directory':
        return _buildDirectoryPage();
      case 'Profile':
        return _buildProfilePage();
      default:
        return _buildClubsPage();
    }
  }

  Widget _buildClubsPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: kMaroon,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Campus Clubs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildClubCard('ASHESI Business Club', 'Develop business acumen and entrepreneurial skills', 248),
                _buildClubCard('Investment Club', 'Learn investment strategies and financial markets', 167),
                _buildClubCard('Robotics Club', 'Build and innovate with robotics and automation', 189),
                _buildClubCard('Storytellers Club', 'Share stories and develop narrative skills', 134),
                _buildClubCard('Rotaract Club', 'Service and community development through Rotary', 256),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(String name, String description, int members) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: kTextMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$members members',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMaroon,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Joined $name!')),
                    );
                  },
                  child: const Text('Join', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: kMaroon,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Campus Directory',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDirectoryCard('Vice Principal, Student Affairs', 'Dr. Ama Owusu-Mensah', '+233 321 234 567'),
                _buildDirectoryCard('Facilities Management', 'Mr. Kofi Mensah', '+233 321 234 568'),
                _buildDirectoryCard('IT Support Center', 'Ms. Ama Boateng', '+233 321 234 569'),
                _buildDirectoryCard('Dean of Residence', 'Dr. Yaw Osei-Mensah', '+233 321 234 570'),
                _buildDirectoryCard('Campus Security', 'Mr. Emmanuel Addae', '+233 321 234 571'),
                _buildDirectoryCard('Health Center', 'Dr. Owusu Dankwa', '+233 321 234 572'),
                _buildDirectoryCard('Academic Affairs', 'Prof. Akosua Owusu', '+233 321 234 573'),
                _buildDirectoryCard('Student Services', 'Ms. Abena Asante', '+233 321 234 574'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryCard(String title, String name, String phone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: kMaroon),
                const SizedBox(width: 8),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kMaroon,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: kMaroon,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'My Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: kMaroon,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ernest Smart',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: kTextDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: ASH-2024-0896',
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextMuted,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileOption(Icons.book_outlined, 'Major', 'Computer Science'),
                _buildProfileOption(Icons.home_outlined, 'Residence', 'Manresa Hall, Room 305'),
                _buildProfileOption(Icons.email_outlined, 'Email', 'ernest.smart@ashesi.edu.gh'),
                _buildProfileOption(Icons.phone_outlined, 'Phone', '+233 501 234 567'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMaroon,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kMaroon),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: kTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: kTextDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: kMaroon,
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
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  _buildTabButton('New Report', _showNewReport, () {
                    setState(() => _showNewReport = true);
                  }),
                  const SizedBox(width: 10),
                  _buildTabButton('Track Reports (${_reports.length})', !_showNewReport, () {
                    setState(() => _showNewReport = false);
                  }),
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
          color: active ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? kMaroon : Colors.white,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── New Report Form ──────────────────────────
  Widget _buildNewReportForm() {
    return SingleChildScrollView(
      child: Padding(
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
              _buildAttachmentsList(),
              const SizedBox(height: 12),
            ],
            _buildEvidenceRow(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${_attachments.length})',
          style: const TextStyle(
            fontSize: 12,
            color: kTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(
            _attachments.length,
            (index) => Chip(
              label: Text('Attachment ${index + 1}'),
              onDeleted: () => _removeAttachment(index),
              backgroundColor: kMaroon.withOpacity(0.1),
              labelStyle: const TextStyle(color: kMaroon),
              deleteIconColor: kMaroon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: kTextDark,
      ),
    );
  }

  // ── Category Grid ──────────────────────────
  Widget _buildCategoryGrid() {
    final categories = IssueCategory.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, i) => _categoryCard(categories[i]),
    );
  }

  Widget _categoryCard(IssueCategory category) {
    final selected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? kMaroon.withOpacity(0.08) : kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? kMaroon : kBorder,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 28,
              color: selected ? kMaroon : kTextDark,
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: selected ? kMaroon : kTextDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text Field ─────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: kTextDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kTextMuted, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: kTextMuted, size: 20)
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

  // ── Evidence Row ──────────────────────────
  Widget _buildEvidenceRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: _evidenceButton(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: _capturePhoto,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: _evidenceButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: _pickImage,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: _evidenceButton(
              icon: Icons.mic_outlined,
              label: 'Voice Note',
              onTap: _recordVoiceNote,
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: kMaroon, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: kTextDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit Button ─────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kMaroon,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kMaroon.withOpacity(0.6),
          elevation: 0,
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
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ── Track Reports ─────────────────────────
  Widget _buildTrackReports() {
    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: kTextMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No reports yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kTextMuted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit your first issue report to get started',
              style: TextStyle(
                fontSize: 13,
                color: kTextMuted,
              ),
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
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.id,
                  style: const TextStyle(
                    fontSize: 12,
                    color: kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: report.status.color.withOpacity(0.12),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: kTextMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: const TextStyle(fontSize: 13, color: kTextMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy').format(report.submittedDate),
                  style: const TextStyle(fontSize: 12, color: kTextMuted),
                ),
              ],
            ),
            if (report.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attachment, size: 14, color: kMaroon),
                  const SizedBox(width: 4),
                  Text(
                    '${report.attachments.length} attachment${report.attachments.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kMaroon,
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
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: report.status.color.withOpacity(0.12),
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
                _detailRow('Category', report.category),
                const SizedBox(height: 12),
                _detailRow('Location', report.location),
                const SizedBox(height: 12),
                _detailRow('Submitted', DateFormat('MMM d, yyyy - hh:mm a').format(report.submittedDate)),
                const SizedBox(height: 20),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: kTextDark,
                      height: 1.5,
                    ),
                  ),
                ),
                if (report.attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      report.attachments.length,
                      (index) => Chip(
                        label: Text('File ${index + 1}'),
                        backgroundColor: kMaroon.withOpacity(0.1),
                        labelStyle: const TextStyle(color: kMaroon),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (report.status != IssueStatus.resolved)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kMaroon,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<IssueStatus>(
                      onSelected: (status) => _updateReportStatus(report, status),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<IssueStatus>>[
                        PopupMenuItem<IssueStatus>(
                          value: IssueStatus.underReview,
                          child: Text(IssueStatus.underReview.label),
                        ),
                        PopupMenuItem<IssueStatus>(
                          value: IssueStatus.inProgress,
                          child: Text(IssueStatus.inProgress.label),
                        ),
                        PopupMenuItem<IssueStatus>(
                          value: IssueStatus.resolved,
                          child: Text(IssueStatus.resolved.label),
                        ),
                      ],
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Update Status',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
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
              color: kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: kTextDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation ─────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.flag_outlined,
                label: 'Reports',
                active: _currentPage == 'Reports',
                onTap: () {
                  setState(() {
                    _currentPage = 'Reports';
                    _showNewReport = false;
                  });
                },
              ),
              _navItem(
                icon: Icons.groups_outlined,
                label: 'Clubs',
                active: _currentPage == 'Clubs',
                onTap: () {
                  setState(() => _currentPage = 'Clubs');
                },
              ),
              _navItem(
                icon: Icons.menu_book_outlined,
                label: 'Directory',
                active: _currentPage == 'Directory',
                onTap: () {
                  setState(() => _currentPage = 'Directory');
                },
              ),
              _navItem(
                icon: Icons.person_outline,
                label: 'Profile',
                active: _currentPage == 'Profile',
                onTap: () {
                  setState(() => _currentPage = 'Profile');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? kMaroon : kTextMuted,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? kMaroon : kTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}