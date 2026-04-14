class ClubModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final int memberCount;
  final int upcomingEvents;
  bool isFollowing;

  ClubModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.memberCount,
    required this.upcomingEvents,
    required this.isFollowing,
  });

  // Converts a Firestore document snapshot into a ClubModel object
  factory ClubModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ClubModel(
      id: id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      memberCount: (data['memberCount'] ?? 0).toInt(),
      upcomingEvents: (data['upcomingEvents'] ?? 0).toInt(),
      isFollowing: false,
    );
  }
}
