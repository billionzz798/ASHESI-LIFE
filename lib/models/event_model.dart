import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String dateLabel;
  final String location;
  final String organizer;
  final String organizerId;
  final String category;
  final int attendeeCount;
  final DateTime dateTime;

  const EventModel({
    required this.id,
    required this.title,
    required this.dateLabel,
    required this.location,
    required this.organizer,
    required this.organizerId,
    required this.category,
    required this.attendeeCount,
    required this.dateTime,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      dateLabel: data['dateLabel'] as String? ?? '',
      location: data['location'] as String? ?? '',
      organizer: data['organizer'] as String? ?? '',
      organizerId: data['organizerId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      attendeeCount: (data['attendeeCount'] as num?)?.toInt() ?? 0,
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'dateLabel': dateLabel,
      'location': location,
      'organizer': organizer,
      'organizerId': organizerId,
      'category': category,
      'attendeeCount': attendeeCount,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }
}
