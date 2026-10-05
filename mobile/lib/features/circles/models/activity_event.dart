import '../../auth/models/user_model.dart';

class ActivityEvent {
  final int id;
  final int circleId;
  final int actorId;
  final String eventType;
  final String? entityType;
  final int? entityId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final UserModel? actor;

  const ActivityEvent({
    required this.id,
    required this.circleId,
    required this.actorId,
    required this.eventType,
    this.entityType,
    this.entityId,
    this.metadata,
    required this.createdAt,
    this.actor,
  });

  String get actorName => actor?.name ?? 'Someone';

  String get description {
    switch (eventType) {
      case 'member_joined':
        return '$actorName joined the circle';
      case 'member_left':
        return '$actorName left the circle';
      case 'member_removed':
        return '$actorName was removed from the circle';
      case 'role_updated':
        final newRole = metadata?['role'] ?? 'member';
        return '$actorName\'s role was changed to $newRole';
      case 'schedule_updated':
        return '$actorName updated their work schedule';
      case 'plan_created':
        final title = metadata?['title'] ?? 'a meetup';
        return '$actorName created plan "$title"';
      case 'plan_rsvp':
        final rsvp = metadata?['status'] ?? 'responded to';
        return '$actorName is $rsvp a plan';
      default:
        return '$actorName performed $eventType';
    }
  }

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as int? ?? 0,
      circleId: json['circle_id'] as int? ?? 0,
      actorId: json['actor_id'] as int? ?? 0,
      eventType: json['event_type'] as String? ?? 'activity',
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actor: json['actor'] is Map<String, dynamic>
          ? UserModel.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'actor_id': actorId,
      'event_type': eventType,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      if (actor != null) 'actor': actor!.toJson(),
    };
  }
}
