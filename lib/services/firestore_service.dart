import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/club_model.dart';
import '../models/issue_report_model.dart';
import '../models/event_model.dart';
import '../models/announcement_model.dart';
import '../models/directory_person_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── CLUBS ────────────────────────────────────────────────────────────────

  Future<List<ClubModel>> fetchClubs() async {
    final snapshot = await _db.collection('clubs').get();
    final clubs = snapshot.docs
        .map((doc) => ClubModel.fromFirestore(doc.id, doc.data()))
        .toList();
    for (final club in clubs) {
      if (_uid != null) {
        final followDoc = await _db
            .collection('users')
            .doc(_uid)
            .collection('followingClubs')
            .doc(club.id)
            .get();
        club.isFollowing = followDoc.exists;
      }
    }
    return clubs;
  }

  Future<void> toggleFollow(String clubId, bool currentlyFollowing) async {
    if (_uid == null) return;
    final ref = _db
        .collection('users')
        .doc(_uid)
        .collection('followingClubs')
        .doc(clubId);
    if (currentlyFollowing) {
      await ref.delete();
    } else {
      await ref.set({
        'clubId': clubId,
        'followedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── ISSUE REPORTS ────────────────────────────────────────────────────────

  Future<List<IssueReport>> fetchMyReports() async {
    if (_uid == null) return [];
    // Note: this query requires a composite index in Firestore.
    // If you see a runtime error with a URL, click the URL to create the index.
    final snapshot = await _db
        .collection('issueReports')
        .where('userId', isEqualTo: _uid)
        .orderBy('submittedDate', descending: true)
        .get();
    return snapshot.docs.map((doc) => IssueReport.fromFirestore(doc)).toList();
  }

  Future<void> submitReport(IssueReport report) async {
    await _db.collection('issueReports').add(report.toFirestore());
  }

  Future<void> updateReportStatus(
    String reportId,
    IssueStatus newStatus,
  ) async {
    await _db.collection('issueReports').doc(reportId).update({
      'status': newStatus.toString(),
    });
  }

  // ─── EVENTS ───────────────────────────────────────────────────────────────

  Future<List<EventModel>> fetchUpcomingEvents() async {
    final snapshot = await _db
        .collection('events')
        .orderBy('dateTime')
        .limit(10)
        .get();
    return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }

  Future<void> rsvpEvent(String eventId, bool currentlyRsvped) async {
    if (_uid == null) return;
    final ref = _db
        .collection('users')
        .doc(_uid)
        .collection('rsvpedEvents')
        .doc(eventId);
    if (currentlyRsvped) {
      await ref.delete();
      await _db.collection('events').doc(eventId).update({
        'attendeeCount': FieldValue.increment(-1),
      });
    } else {
      await ref.set({
        'eventId': eventId,
        'rsvpedAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('events').doc(eventId).update({
        'attendeeCount': FieldValue.increment(1),
      });
    }
  }

  Future<Set<String>> fetchMyRsvps() async {
    if (_uid == null) return {};
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('rsvpedEvents')
        .get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  // ─── ANNOUNCEMENTS ────────────────────────────────────────────────────────

  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    final snapshot = await _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromFirestore(doc))
        .toList();
  }

  // ─── DIRECTORY ────────────────────────────────────────────────────────────

  Future<void> saveDirectoryPerson(DirectoryPerson person) async {
    await _db.collection('directory').add(person.toMap());
  }

  // ─── USER PROFILE ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    if (_uid == null) return null;
    final doc = await _db.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<int> fetchFollowingCount() async {
    if (_uid == null) return 0;
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('followingClubs')
        .get();
    return snapshot.docs.length;
  }

  Future<int> fetchRsvpCount() async {
    if (_uid == null) return 0;
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('rsvpedEvents')
        .get();
    return snapshot.docs.length;
  }
}
