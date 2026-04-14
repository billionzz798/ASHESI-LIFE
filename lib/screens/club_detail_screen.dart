import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/club_detail_model.dart';
import '../models/club_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class ClubDetailScreen extends StatefulWidget {
  final ClubModel club;

  const ClubDetailScreen({super.key, required this.club});

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final FirestoreService _service = FirestoreService();
  ClubDetailModel? _detail;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.club.isFollowing;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    // Step 1: Fetch the club detail document.
    // Any authenticated user can read this — no membership required.
    final detail = await _service.fetchClubDetail(widget.club.id);

    // Step 2: Check membership separately, wrapped in try/catch so that
    // a Firestore permissions error never prevents the screen from loading.
    bool memberStatus = false;
    try {
      memberStatus = await _service.checkMembership(widget.club.id);
    } catch (_) {
      // If the membership check fails for any reason (permissions, network),
      // default to not a member and continue rendering the screen normally.
      memberStatus = false;
    }

    if (detail != null) {
      detail.isFollowing = _isFollowing;
      detail.isMember = memberStatus;
      setState(() {
        _detail = detail;
        _isMember = memberStatus;
        _isLoading = false;
      });
    } else {
      // Club document exists but has no extended fields yet —
      // build a minimal model from the basic ClubModel data so the
      // screen still renders with whatever information is available.
      setState(() {
        _detail = ClubDetailModel(
          id: widget.club.id,
          name: widget.club.name,
          category: widget.club.category,
          categoryLabel: widget.club.category == 'Committees'
              ? 'Governance'
              : 'Academic',
          description: widget.club.description,
          memberCount: widget.club.memberCount,
          upcomingEvents: widget.club.upcomingEvents,
          establishedYear: 0,
          meetingSchedule: '',
          meetingLocation: '',
          email: '',
          phone: '',
          instagram: '',
          twitter: '',
          leadership: [],
          events: [],
          resources: [],
          isFollowing: _isFollowing,
          isMember: memberStatus,
        );
        _isMember = memberStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      if (_detail != null) _detail!.isFollowing = _isFollowing;
      widget.club.isFollowing = _isFollowing;
    });
    await _service.toggleFollow(widget.club.id, wasFollowing);
  }

  Future<void> _toggleMembership() async {
    final wasMember = _isMember;
    setState(() {
      _isMember = !_isMember;
      if (_detail != null) _detail!.isMember = _isMember;
    });
    await _service.toggleMembership(widget.club.id, wasMember);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasMember
              ? 'You have left ${widget.club.name}.'
              : 'You have joined ${widget.club.name}!',
        ),
        backgroundColor: AppColors.lightMaroon,
      ),
    );
  }

  Future<void> _launchUrl(String scheme, String value) async {
    if (value.isEmpty) return;
    final uri = Uri(scheme: scheme, path: value);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSocial(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.lightMaroon),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAboutSection(),
                      const SizedBox(height: 16),
                      if (_detail!.meetingSchedule.isNotEmpty ||
                          _detail!.meetingLocation.isNotEmpty) ...[
                        _buildMeetingSection(),
                        const SizedBox(height: 16),
                      ],
                      if (_detail!.leadership.isNotEmpty) ...[
                        _buildLeadershipSection(),
                        const SizedBox(height: 16),
                      ],
                      if (_detail!.events.isNotEmpty) ...[
                        _buildEventsSection(),
                        const SizedBox(height: 16),
                      ],
                      if (_detail!.resources.isNotEmpty) ...[
                        _buildResourcesSection(),
                        const SizedBox(height: 16),
                      ],
                      if (_detail!.email.isNotEmpty ||
                          _detail!.phone.isNotEmpty ||
                          _detail!.instagram.isNotEmpty ||
                          _detail!.twitter.isNotEmpty)
                        _buildContactSection(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }

  // ─── SLIVER HEADER ─────────────────────────────────────────────────────────

  Widget _buildSliverHeader() {
    final d = _detail!;
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.lightMaroon,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Back to Clubs',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Avatar + name + badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.groups_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (d.categoryLabel.isNotEmpty)
                                _headerBadge(d.categoryLabel),
                              if (d.categoryLabel.isNotEmpty)
                                const SizedBox(width: 6),
                              _headerBadge(d.category),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${d.memberCount} members',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              if (d.establishedYear > 0) ...[
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Est. ${d.establishedYear}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Join + Follow buttons — visible to ALL authenticated users
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleMembership,
                        icon: Icon(
                          _isMember ? Icons.check : Icons.person_add_outlined,
                          size: 16,
                        ),
                        label: Text(
                          _isMember
                              ? 'Joined'
                              : (d.category == 'Committees'
                                    ? 'Join Committee'
                                    : 'Join Club'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMember
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white,
                          foregroundColor: _isMember
                              ? Colors.white
                              : AppColors.lightMaroon,
                          minimumSize: const Size(0, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Follow/unfollow bell button
                    GestureDetector(
                      onTap: _toggleFollow,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Icon(
                          _isFollowing
                              ? Icons.notifications
                              : Icons.notifications_none_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── ABOUT ─────────────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return _sectionCard(
      title: 'About',
      child: Text(
        _detail!.description,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }

  // ─── MEETING INFORMATION ───────────────────────────────────────────────────

  Widget _buildMeetingSection() {
    return _sectionCard(
      title: 'Meeting Information',
      child: Column(
        children: [
          if (_detail!.meetingSchedule.isNotEmpty)
            _meetingRow(
              Icons.access_time_outlined,
              'Schedule',
              _detail!.meetingSchedule,
            ),
          if (_detail!.meetingSchedule.isNotEmpty &&
              _detail!.meetingLocation.isNotEmpty)
            const SizedBox(height: 12),
          if (_detail!.meetingLocation.isNotEmpty)
            _meetingRow(
              Icons.location_on_outlined,
              'Location',
              _detail!.meetingLocation,
            ),
        ],
      ),
    );
  }

  Widget _meetingRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.lightMaroon),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  // ─── LEADERSHIP ────────────────────────────────────────────────────────────

  Widget _buildLeadershipSection() {
    return _sectionCard(
      title: 'Leadership Team',
      child: Column(
        children: List.generate(_detail!.leadership.length, (i) {
          final member = _detail!.leadership[i];
          final isLast = i == _detail!.leadership.length - 1;
          return Column(
            children: [
              _leadershipRow(member),
              if (!isLast) const Divider(height: 16, color: Color(0xFFEEEEEE)),
            ],
          );
        }),
      ),
    );
  }

  Widget _leadershipRow(LeadershipMember member) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E8EA),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.lightMaroon,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                member.role,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (member.email.isNotEmpty)
          GestureDetector(
            onTap: () => _launchUrl('mailto', member.email),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.email_outlined,
                color: AppColors.lightMaroon,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  // ─── EVENTS ────────────────────────────────────────────────────────────────

  Widget _buildEventsSection() {
    return _sectionCard(
      title: 'Upcoming Events',
      child: Column(
        children: List.generate(_detail!.events.length, (i) {
          final event = _detail!.events[i];
          final isLast = i == _detail!.events.length - 1;
          return Column(
            children: [
              _eventRow(event),
              if (!isLast) const SizedBox(height: 12),
            ],
          );
        }),
      ),
    );
  }

  Widget _eventRow(ClubEvent event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E8EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.lightMaroon,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      event.dateLabel,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.access_time_outlined,
                      size: 11,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      event.timeLabel,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      event.location,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E8EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.type,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.lightMaroon,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── RESOURCES ─────────────────────────────────────────────────────────────

  Widget _buildResourcesSection() {
    return _sectionCard(
      title: 'Resources & Documents',
      child: Column(
        children: List.generate(_detail!.resources.length, (i) {
          final resource = _detail!.resources[i];
          final isLast = i == _detail!.resources.length - 1;
          return Column(
            children: [
              _resourceRow(resource),
              if (!isLast) const SizedBox(height: 10),
            ],
          );
        }),
      ),
    );
  }

  Widget _resourceRow(ClubResource resource) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E8EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.insert_drive_file_outlined,
              color: AppColors.lightMaroon,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${resource.fileType} • ${resource.fileSize} • ${resource.date}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _launchSocial(resource.url),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E8EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.download_outlined,
                color: AppColors.lightMaroon,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CONTACT ───────────────────────────────────────────────────────────────

  Widget _buildContactSection() {
    final d = _detail!;
    return _sectionCard(
      title: 'Contact',
      child: Column(
        children: [
          if (d.email.isNotEmpty) ...[
            _contactRow(
              Icons.email_outlined,
              d.email,
              () => _launchUrl('mailto', d.email),
            ),
            const SizedBox(height: 10),
          ],
          if (d.phone.isNotEmpty) ...[
            _contactRow(
              Icons.phone_outlined,
              d.phone,
              () => _launchUrl('tel', d.phone),
            ),
            const SizedBox(height: 14),
          ],
          if (d.instagram.isNotEmpty || d.twitter.isNotEmpty)
            Row(
              children: [
                if (d.instagram.isNotEmpty)
                  _socialButton(
                    Icons.camera_alt_outlined,
                    'Instagram',
                    () => _launchSocial(d.instagram),
                  ),
                if (d.instagram.isNotEmpty && d.twitter.isNotEmpty)
                  const SizedBox(width: 10),
                if (d.twitter.isNotEmpty)
                  _socialButton(
                    Icons.alternate_email,
                    'Twitter',
                    () => _launchSocial(d.twitter),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.lightMaroon),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: AppColors.lightMaroon),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SHARED SECTION CARD ───────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
