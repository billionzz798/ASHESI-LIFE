import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../auth_service.dart';
import '../models/event_model.dart';
import '../models/issue_report_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _service = FirestoreService();
  Map<String, dynamic>? _profile;
  List<IssueReport> _activeReports = [];
  List<EventModel> _upcomingRsvps = [];
  int _eventsAttended = 0;
  int _followingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final profile = await _service.fetchUserProfile();
    final reports = await _service.fetchMyReports();
    final rsvps = await _service.fetchMyRsvps();
    final allEvents = await _service.fetchUpcomingEvents();
    final followingCount = await _service.fetchFollowingCount();
    final rsvpCount = await _service.fetchRsvpCount();

    // Active reports = not resolved
    final activeReports = reports
        .where((r) => r.status != IssueStatus.resolved)
        .toList();
    // Upcoming RSVPed events
    final rsvpedEvents = allEvents.where((e) => rsvps.contains(e.id)).toList();

    setState(() {
      _profile = profile;
      _activeReports = activeReports;
      _upcomingRsvps = rsvpedEvents;
      _eventsAttended = rsvpCount;
      _followingCount = followingCount;
      _isLoading = false;
    });
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.isEmpty) return 'AS';
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightMaroon,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final fullName = _profile?['fullName'] as String? ?? 'Ashesi Student';
    final email = _profile?['email'] as String? ?? '';
    final major = _profile?['major'] as String? ?? '';
    final studentId = _profile?['studentId'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Hero ──────────────────────────────────────────────────────────
          Container(
            color: AppColors.lightMaroon,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 3),
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF6B1A27),
                      child: Text(
                        _getInitials(fullName),
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Major + Year badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (major.isNotEmpty) _badge(major),
                      const SizedBox(width: 8),
                      _badge('Student'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // ── Stats row ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _statCell(
                  _eventsAttended.toString(),
                  'Events\nAttended',
                  rightBorder: true,
                ),
                _statCell(
                  _activeReports.length.toString(),
                  'Reports\nSubmitted',
                  rightBorder: true,
                ),
                _statCell(_followingCount.toString(), 'Following'),
              ],
            ),
          ),
          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.lightMaroon,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildUpcomingEventsSection(),
                    _buildActiveReportsSection(),
                    _buildSettingsSection(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                    const SizedBox(height: 24),
                    const Text(
                      'Ashesi Life v1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Text(
                      '© 2026 Ashesi University',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
                ? const BorderSide(color: Color(0xFFE0E0E0), width: 0.5)
                : BorderSide.none,
          ),
        ),
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.lightMaroon,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── My Upcoming Events ────────────────────────────────────────────────────

  Widget _buildUpcomingEventsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.lightMaroon,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Upcoming Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_upcomingRsvps.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_upcomingRsvps.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No upcoming events. RSVP to events from the Home screen.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            ...List.generate(_upcomingRsvps.length, (i) {
              final event = _upcomingRsvps[i];
              final isLast = i == _upcomingRsvps.length - 1;
              return GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 0.5,
                            ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('MMM d, yyyy').format(event.dateTime)} • ${_formatTime(event.dateTime)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Active Reports ────────────────────────────────────────────────────────

  Widget _buildActiveReportsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.lightMaroon,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Reports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_activeReports.length}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          if (_activeReports.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No active reports.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            ...List.generate(_activeReports.length, (i) {
              final report = _activeReports[i];
              final isLast = i == _activeReports.length - 1;
              return GestureDetector(
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/reports'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: isLast
                          ? BorderSide.none
                          : const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 0.5,
                            ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.description.isNotEmpty
                                  ? report.description
                                  : report.category,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
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
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Widget _buildSettingsSection() {
    final items = [
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notification Preferences',
        'color': const Color(0xFF8B2E3D),
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'App Settings',
        'color': const Color(0xFF555555),
      },
      {
        'icon': Icons.help_outline,
        'label': 'Help & Support',
        'color': const Color(0xFF185FA5),
      },
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          final color = item['color'] as Color;
          return GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item["label"]} coming soon.')),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast
                      ? BorderSide.none
                      : const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          await AuthService().signOut();
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/landing', (route) => false);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lightMaroon.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: AppColors.lightMaroon, size: 18),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightMaroon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}
