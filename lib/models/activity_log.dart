import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.timestamp,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.description,
    this.metadata = const {},
  });

  final String id;
  final DateTime timestamp;
  final String userId;
  final String userName;
  final String userRole;
  final String action;
  final String targetType;
  final String targetId;
  final String title;
  final String description;
  final Map<String, dynamic> metadata;

  factory ActivityLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawTimestamp = data['timestamp'];
    return ActivityLog(
      id: doc.id,
      timestamp: rawTimestamp is Timestamp
          ? rawTimestamp.toDate()
          : DateTime.now(),
      userId: data['user_id']?.toString() ?? '-',
      userName: data['user_name']?.toString() ?? '-',
      userRole: data['user_role']?.toString() ?? '-',
      action: data['action']?.toString() ?? '-',
      targetType: data['target_type']?.toString() ?? '-',
      targetId: data['target_id']?.toString() ?? '-',
      title: data['title']?.toString() ?? '-',
      description: data['description']?.toString() ?? '-',
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
