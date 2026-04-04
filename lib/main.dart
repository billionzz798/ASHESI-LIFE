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
  bool _isLoading = true;
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
      _isLoading = false;
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
                _buildClubCard('Coding Club', 'Learn programming and build projects', 156),
                _buildClubCard('Debate Team', 'Engage in intellectual discussions', 89),
                _buildClubCard('Photography Club', 'Capture moments and share stories', 124),
                _buildClubCard('Music Society', 'Perform and enjoy live music', 203),
                _buildClubCard('Arts & Crafts', 'Creative expression through art', 76),
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
                _buildDirectoryCard('Dean of Students', 'Osei Kwame', '+233 24 123 4567'),
                _buildDirectoryCard('Head of IT', 'Ama Osei', '+233 24 234 5678'),
                _buildDirectoryCard('Residence Life Coordinator', 'Kofi Mensah', '+233 24 345 6789'),
                _buildDirectoryCard('Security Office', 'Yaw Boateng', '+233 24 456 7890'),
                _buildDirectoryCard('Health Services', 'Dr. Akosua Poku', '+233 24 567 8901'),
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

  // ── Profile Page ──────────────────────────────
  Widget _buildProfilePage() {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildProfileHero(),
          _buildProfileStats(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _profileSection('Personal Info', _buildPersonalInfoCard()),
                  _profileSection('My Clubs', _buildClubsCard()),
                  _profileSection('My Reports', _buildReportsSummaryCard()),
                  _profileSection('Account', _buildAccountActionsCard()),
                  const SizedBox(height: 4),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      color: kMaroon,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // Avatar + name
            Column(
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.30), width: 3),
                  ),
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF6B1A27),
                    child: Text(
                      'GK',
                      style: TextStyle(fontSize: 28, color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Georgina Kusi-Appiah',
                    style: TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Computer Science · Class of 2026',
                    style: TextStyle(color: Colors.white.withOpacity(0.72),
                        fontSize: 13)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.30)),
                  ),
                  child: const Text('STUDENT',
                      style: TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      color: kCardBg,
      child: Row(
        children: [
          _statCell(_isLoading ? '—' : _reports.length.toString(), 'Reports', rightBorder: true),
          _statCell('2', 'Clubs', rightBorder: true),
          _statCell('5', 'Events RSVPd'),
        ],
      ),
    );
  }

  Widget _statCell(String num, String label, {bool rightBorder = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            right: rightBorder
                ? BorderSide(color: kBorder, width: 0.5)
                : BorderSide.none,
          ),
        ),
        child: Column(
          children: [
            Text(num, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                color: kMaroon, height: 1)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
          ],
        ),
      ),
    );
  }

  Widget _profileSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: kTextMuted, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'Student ID', 'ASH/CS/2022/041'),
          _infoRow(Icons.email_outlined, 'Email', 'g.kusi-appiah@ashesi.edu.gh',
              actionLabel: 'Copy', onAction: () {}),
          _infoRow(Icons.home_outlined, 'Residence', 'Cobblestone — Room 14B'),
          _infoRow(Icons.school_outlined, 'Year & Major', 'Year 4 · Computer Science',
              isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {String? actionLabel, VoidCallback? onAction, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: kBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: kMaroon.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kMaroon, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500, color: kTextDark),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF185FA5),
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  Widget _buildClubsCard() {
    final execClubs = ['Korean Wave Club — President', 'Theatre Club — President'];
    final memberClubs = ['Coding Club', 'Photography Society'];
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: [
          ...execClubs.map((c) => _clubChip(c, isExec: true)),
          ...memberClubs.map((c) => _clubChip(c)),
        ],
      ),
    );
  }

  Widget _clubChip(String label, {bool isExec = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isExec ? kMaroon : kMaroon.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isExec ? kMaroon : kMaroon.withOpacity(0.18), width: 1),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: isExec ? Colors.white : kMaroon)),
    );
  }

  Widget _buildReportsSummaryCard() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kMaroon,
            ),
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Center(
          child: Column(
            children: const [
              Icon(Icons.inbox_outlined, size: 32, color: kTextMuted),
              SizedBox(height: 8),
              Text(
                'No reports submitted yet',
                style: TextStyle(fontSize: 13, color: kTextMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Show latest 3 only
    final recent = _reports.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        children: [
          ...recent.asMap().entries.map((e) {
            final isLast = e.key == recent.length - 1 && _reports.length <= 3;
            final r = e.value;

            Color sc;
            Color sbg;
            switch (r.status) {
              case IssueStatus.resolved:
                sc = const Color(0xFF059669);
                sbg = const Color(0xFFEAF3DE);
                break;
              case IssueStatus.underReview:
                sc = const Color(0xFFD97706);
                sbg = const Color(0xFFFAEEDA);
                break;
              case IssueStatus.inProgress:
                sc = const Color(0xFF3B82F6);
                sbg = const Color(0xFFE6F1FB);
                break;
              default:
                sc = const Color(0xFF4F46E5);
                sbg = const Color(0xFFEEEDFE);
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : BorderSide(color: kBorder, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.category,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kTextDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.location} · ${DateFormat('MMM d, yyyy').format(r.submittedDate)}',
                          style: const TextStyle(fontSize: 11, color: kTextMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: sbg,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      r.status.label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: sc),
                    ),
                  ),
                ],
              ),
            );
          }),

          // "View all" row if there are more than 3
          if (_reports.length > 3)
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentPage = 'Reports';
                  _showNewReport = false;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: kBorder, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View all ${_reports.length} reports',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kMaroon),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward,
                        size: 14, color: kMaroon),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsCard() {
    final actions = [
      {'icon': Icons.person_outline, 'label': 'Edit Profile', 'color': 0xFF185FA5},
      {'icon': Icons.notifications_outlined, 'label': 'Notification Preferences', 'color': 0xFFBA7517},
      {'icon': Icons.shield_outlined, 'label': 'Privacy & Security', 'color': 0xFF059669},
      {'icon': Icons.help_outline, 'label': 'Help & Support', 'color': 0xFF8B2E3D},
    ];
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        children: actions.asMap().entries.map((e) {
          final isLast = e.key == actions.length - 1;
          final a = e.value;
          final color = Color(a['color'] as int);
          return GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: isLast
                    ? BorderSide.none : BorderSide(color: kBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a['icon'] as IconData, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(a['label'] as String,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w500, color: kTextDark)),
                  ),
                  const Icon(Icons.chevron_right, color: kTextMuted, size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signed out successfully')),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: kMaroon.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kMaroon.withOpacity(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: kMaroon, size: 16),
              SizedBox(width: 8),
              Text('Sign Out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: kMaroon)),
            ],
          ),
        ),
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