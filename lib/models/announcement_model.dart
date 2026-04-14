import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String iconName;
  final String colorHex;
  final String organizerId;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.iconName,
    required this.colorHex,
    required this.organizerId,
    required this.createdAt,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AnnouncementModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      iconName: data['iconName'] as String? ?? '',
      colorHex: data['colorHex'] as String? ?? '',
      organizerId: data['organizerId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'iconName': iconName,
      'colorHex': colorHex,
      'organizerId': organizerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
