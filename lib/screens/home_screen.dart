import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    final events = await _service.fetchUpcomingEvents();
    final rsvps = await _service.fetchMyRsvps();
    setState(() {
      _allEvents = events;
      _rsvpedEvents = rsvps;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_selectedFilter == 0) {
      _displayedEvents = List.from(_allEvents);
    } else {
      _displayedEvents = _allEvents
          .where((e) => _rsvpedEvents.contains(e.id))
          .toList();
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
                    onRefresh: _loadEvents,
                    child: _displayedEvents.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _displayedEvents.length,
                            itemBuilder: (context, index) =>
                                _buildEventCard(_displayedEvents[index]),
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

  Widget _buildEventCard(EventModel event) {
    final rsvped = _rsvpedEvents.contains(event.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + badge
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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
            _infoRow(Icons.group_outlined, '${event.attendeeCount} attending'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _handleRsvp(event),
                style: ElevatedButton.styleFrom(
                  backgroundColor: rsvped
                      ? Colors.white
                      : AppColors.lightMaroon,
                  foregroundColor: rsvped
                      ? AppColors.lightMaroon
                      : Colors.white,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
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

  Widget _buildEmptyState() {
    return ListView(
      children: const [
        SizedBox(height: 120),
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
