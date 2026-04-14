import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _service = FirestoreService();
  List<EventModel> _allEvents = [];
  List<EventModel> _displayedEvents = [];
  Set<String> _rsvpedEvents = {};
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _service.fetchUpcomingEvents(),
      _service.fetchMyRsvps(),
      _service.fetchAnnouncements(),
    ]);
    setState(() {
      _allEvents = results[0] as List<EventModel>;
      _rsvpedEvents = results[1] as Set<String>;
      _announcements = results[2] as List<AnnouncementModel>;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_selectedFilter == 0) {
      _displayedEvents = List.from(_allEvents);
    } else {
      _displayedEvents =
          _allEvents.where((e) => _rsvpedEvents.contains(e.id)).toList();
    }
  }

  Future<void> _handleRsvp(EventModel event) async {
    final currentlyRsvped = _rsvpedEvents.contains(event.id);
    setState(() {
      if (currentlyRsvped) {
        _rsvpedEvents.remove(event.id);
      } else {
        _rsvpedEvents.add(event.id);
      }
      final index = _allEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _allEvents[index] = EventModel(
          id: event.id,
          title: event.title,
          dateLabel: event.dateLabel,
          location: event.location,
          organizer: event.organizer,
          organizerId: event.organizerId,
          category: event.category,
          dateTime: event.dateTime,
          attendeeCount: currentlyRsvped
              ? event.attendeeCount - 1
              : event.attendeeCount + 1,
        );
      }
      _applyFilter();
    });
    await _service.rsvpEvent(event.id, currentlyRsvped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lightMaroon,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.lightMaroon,
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        if (_announcements.isNotEmpty)
                          _buildAnnouncementsSection(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            'Upcoming Events',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (_displayedEvents.isEmpty)
                          _buildEmptyState()
                        else
                          ...(_displayedEvents.map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: _buildEventCard(e),
                            ),
                          )),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.lightMaroon,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ashesi Life',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Campus Events & Engagement',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFilterTab('All Events', 0),
                  const SizedBox(width: 10),
                  _buildFilterTab('Following', 1),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, int tabIndex) {
    final isSelected = _selectedFilter == tabIndex;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = tabIndex;
        _applyFilter();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.lightMaroon : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Announcements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _announcements.length,
            itemBuilder: (context, index) =>
                _buildAnnouncementCard(_announcements[index]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final color = _parseColor(announcement.colorHex);
    final icon = _resolveIcon(announcement.iconName);
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              announcement.body,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.lightMaroon;
    }
  }

  IconData _resolveIcon(String name) {
    const iconMap = {
      'campaign': Icons.campaign_outlined,
      'info': Icons.info_outline,
      'warning': Icons.warning_amber_outlined,
      'event': Icons.event_outlined,
      'announcement': Icons.announcement_outlined,
      'school': Icons.school_outlined,
      'star': Icons.star_outline,
    };
    return iconMap[name] ?? Icons.campaign_outlined;
  }

  Widget _buildEventCard(EventModel event) {
    final rsvped = _rsvpedEvents.contains(event.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.category,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'by ${event.organizer}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _infoRow(
              Icons.calendar_today_outlined,
              DateFormat('MMM d, yyyy').format(event.dateTime),
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time_outlined, _formatTime(event.dateTime)),
            const SizedBox(height: 8),
            _infoRow(Icons.location_on_outlined, event.location),
            const SizedBox(height: 8),
            _infoRow(
                Icons.group_outlined, '${event.attendeeCount} attending'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleRsvp(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      rsvped ? Colors.white : AppColors.lightMaroon,
                  foregroundColor:
                      rsvped ? AppColors.lightMaroon : Colors.white,
                  side: rsvped
                      ? const BorderSide(color: AppColors.lightMaroon)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(
                  rsvped ? 'Cancel RSVP' : 'RSVP to Event',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.lightMaroon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
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

  Widget _buildEmptyState() {
    return const Column(
      children: [
        SizedBox(height: 80),
        Center(
          child: Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey),
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No events here',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'RSVP to events to see them in Following',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
