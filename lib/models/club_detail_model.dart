// ClubDetailModel — extended club data loaded from Firestore
// Goes in lib/models/club_detail_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Leadership Member ────────────────────────────────────────────────────────

class LeadershipMember {
  final String name;
  final String role;
  final String email;

  const LeadershipMember({
    required this.name,
    required this.role,
    required this.email,
  });

  factory LeadershipMember.fromMap(Map<String, dynamic> data) {
    return LeadershipMember(
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? '',
      email: data['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'role': role, 'email': email};
}

// ─── Club Event (for the detail screen events list) ───────────────────────────

class ClubEvent {
  final String title;
  final String dateLabel; // e.g. "Sat, Apr 18"
  final String timeLabel; // e.g. "5:00 PM"
  final String location;
  final String type; // e.g. "Meeting", "Discussion", "Event"

  const ClubEvent({
    required this.title,
    required this.dateLabel,
    required this.timeLabel,
    required this.location,
    required this.type,
  });

  factory ClubEvent.fromMap(Map<String, dynamic> data) {
    return ClubEvent(
      title: data['title'] as String? ?? '',
      dateLabel: data['dateLabel'] as String? ?? '',
      timeLabel: data['timeLabel'] as String? ?? '',
      location: data['location'] as String? ?? '',
      type: data['type'] as String? ?? 'Event',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'dateLabel': dateLabel,
    'timeLabel': timeLabel,
    'location': location,
    'type': type,
  };
}

// ─── Club Resource ────────────────────────────────────────────────────────────

class ClubResource {
  final String name;
  final String fileType; // e.g. "PDF"
  final String fileSize; // e.g. "2.4 MB"
  final String date; // e.g. "2026-01-15"
  final String url; // download URL (empty string if not set)

  const ClubResource({
    required this.name,
    required this.fileType,
    required this.fileSize,
    required this.date,
    required this.url,
  });

  factory ClubResource.fromMap(Map<String, dynamic> data) {
    return ClubResource(
      name: data['name'] as String? ?? '',
      fileType: data['fileType'] as String? ?? 'PDF',
      fileSize: data['fileSize'] as String? ?? '',
      date: data['date'] as String? ?? '',
      url: data['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'fileType': fileType,
    'fileSize': fileSize,
    'date': date,
    'url': url,
  };
}

// ─── Club Detail Model ────────────────────────────────────────────────────────

class ClubDetailModel {
  final String id;
  final String name;
  final String category; // "Clubs" or "Committees"
  final String categoryLabel; // "Academic", "Governance", etc.
  final String description;
  final int memberCount;
  final int upcomingEvents;
  final int establishedYear;
  final String meetingSchedule; // e.g. "Every Monday, 6:00 PM"
  final String meetingLocation; // e.g. "Student Center, Room 201"
  final String email;
  final String phone;
  final String instagram;
  final String twitter;
  final List<LeadershipMember> leadership;
  final List<ClubEvent> events;
  final List<ClubResource> resources;
  bool isFollowing;
  bool isMember;

  ClubDetailModel({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.description,
    required this.memberCount,
    required this.upcomingEvents,
    required this.establishedYear,
    required this.meetingSchedule,
    required this.meetingLocation,
    required this.email,
    required this.phone,
    required this.instagram,
    required this.twitter,
    required this.leadership,
    required this.events,
    required this.resources,
    required this.isFollowing,
    required this.isMember,
  });

  factory ClubDetailModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse leadership list
    final leadershipRaw = data['leadership'] as List<dynamic>? ?? [];
    final leadership = leadershipRaw
        .map((e) => LeadershipMember.fromMap(e as Map<String, dynamic>))
        .toList();

    // Parse events list
    final eventsRaw = data['events'] as List<dynamic>? ?? [];
    final events = eventsRaw
        .map((e) => ClubEvent.fromMap(e as Map<String, dynamic>))
        .toList();

    // Parse resources list
    final resourcesRaw = data['resources'] as List<dynamic>? ?? [];
    final resources = resourcesRaw
        .map((e) => ClubResource.fromMap(e as Map<String, dynamic>))
        .toList();

    return ClubDetailModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '',
      categoryLabel: data['categoryLabel'] as String? ?? '',
      description: data['description'] as String? ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      upcomingEvents: (data['upcomingEvents'] as num?)?.toInt() ?? 0,
      establishedYear: (data['establishedYear'] as num?)?.toInt() ?? 2000,
      meetingSchedule: data['meetingSchedule'] as String? ?? '',
      meetingLocation: data['meetingLocation'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      instagram: data['instagram'] as String? ?? '',
      twitter: data['twitter'] as String? ?? '',
      leadership: leadership,
      events: events,
      resources: resources,
      isFollowing: false,
      isMember: false,
    );
  }
}
