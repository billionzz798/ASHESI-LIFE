import 'package:flutter/material.dart';
import '../models/club_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final FirestoreService _service = FirestoreService();
  List<ClubModel> _allClubs = [];
  List<ClubModel> _filteredClubs = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    setState(() {
      _isLoading = true;
    });
    final clubs = await _service.fetchClubs();
    setState(() {
      _allClubs = clubs;
      _isLoading = false;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredClubs = _allClubs.where((club) {
        final matchesSearch = club.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesFilter =
            _selectedFilter == 'All' || club.category == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _toggleFollow(ClubModel club) async {
    final wasFollowing = club.isFollowing;
    setState(() {
      club.isFollowing = !club.isFollowing;
    });
    await _service.toggleFollow(club.id, wasFollowing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: AppColors.lightMaroon,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clubs & Committees',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (v) {
                    _searchQuery = v;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    hintText: 'Search clubs and committees...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.search_outlined,
                      color: Colors.white70,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['All', 'Committees', 'Clubs'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        _applyFilters();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.lightMaroon
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lightMaroon,
                    ),
                  )
                : _filteredClubs.isEmpty
                ? const Center(
                    child: Text(
                      'No clubs found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredClubs.length,
                    itemBuilder: (context, index) {
                      final club = _filteredClubs[index];
                      return _ClubCard(
                        club: club,
                        onFollowToggle: () => _toggleFollow(club),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final ClubModel club;
  final VoidCallback onFollowToggle;

  const _ClubCard({required this.club, required this.onFollowToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(
                    Icons.groups_outlined,
                    color: AppColors.lightMaroon,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          club.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onFollowToggle,
                  icon: Icon(
                    club.isFollowing
                        ? Icons.notifications
                        : Icons.notifications_none_outlined,
                    color: club.isFollowing
                        ? AppColors.lightMaroon
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              club.description,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${club.memberCount} members',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${club.upcomingEvents} upcoming events',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Resources for ${club.name} coming soon.',
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 16,
                    ),
                    label: const Text('Resources'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Details for ${club.name} coming soon.'),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightMaroon,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
