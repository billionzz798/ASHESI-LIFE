import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum IssueCategory { facilities, it, residence, security, other }

extension IssueCategoryExtension on IssueCategory {
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

extension IssueStatusExtension on IssueStatus {
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
  final String userId;

  const IssueReport({
    required this.id,
    required this.category,
    required this.location,
    required this.description,
    required this.status,
    required this.submittedDate,
    required this.userId,
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
      'userId': userId,
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
      userId: json['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'category': category,
      'location': location,
      'description': description,
      'status': status.toString(),
      'submittedDate': Timestamp.fromDate(submittedDate),
      'attachments': attachments,
      'userId': userId,
    };
  }

  factory IssueReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueReport(
      id: doc.id,
      category: data['category'] as String? ?? '',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: IssueStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => IssueStatus.submitted,
      ),
      submittedDate:
          (data['submittedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachments: List<String>.from(data['attachments'] as List? ?? []),
      userId: data['userId'] as String? ?? '',
    );
  }
}
