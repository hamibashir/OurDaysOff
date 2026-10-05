import '../../auth/models/user_model.dart';
import '../../circles/models/circle_model.dart';
import 'plan_location_model.dart';
import 'plan_member_model.dart';
import 'plan_message_model.dart';
import 'plan_option_model.dart';

class PlanModel {
  final int id;
  final int circleId;
  final int createdBy;
  final String title;
  final String? description;
  final String eventType; // 'social' | 'meal' | 'travel' | 'other'
  final DateTime? startAt;
  final DateTime? endAt;
  final String timezone;
  final String status; // 'draft' | 'polling' | 'confirmed' | 'cancelled' | 'completed'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String myRsvp; // 'attending' | 'tentative' | 'declined' | 'pending'
  final CircleModel? circle;
  final UserModel? creator;
  final List<PlanMemberModel> members;
  final List<PlanOptionModel> options;
  final List<PlanLocationModel> locations;
  final List<PlanMessageModel> messages;

  const PlanModel({
    required this.id,
    required this.circleId,
    required this.createdBy,
    required this.title,
    this.description,
    this.eventType = 'social',
    this.startAt,
    this.endAt,
    this.timezone = 'UTC',
    this.status = 'confirmed',
    this.createdAt,
    this.updatedAt,
    this.myRsvp = 'pending',
    this.circle,
    this.creator,
    this.members = const [],
    this.options = const [],
    this.locations = const [],
    this.messages = const [],
  });

  bool get isConfirmed => status == 'confirmed';
  bool get isPolling => status == 'polling';
  bool get isDraft => status == 'draft';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  bool isCreator(int userId) => createdBy == userId;

  List<PlanMemberModel> get attendingMembers =>
      members.where((m) => m.isAttending).toList();
  List<PlanMemberModel> get tentativeMembers =>
      members.where((m) => m.isTentative).toList();
  List<PlanMemberModel> get declinedMembers =>
      members.where((m) => m.isDeclined).toList();
  List<PlanMemberModel> get pendingMembers =>
      members.where((m) => m.isPending).toList();

  int get attendingCount => attendingMembers.length;
  bool get hasLocation => locations.isNotEmpty;
  PlanLocationModel? get primaryLocation =>
      locations.isNotEmpty ? locations.first : null;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    // Members
    final rawMembers = json['members'];
    List<PlanMemberModel> parsedMembers = [];
    if (rawMembers is List) {
      parsedMembers = rawMembers
          .whereType<Map<String, dynamic>>()
          .map((m) => PlanMemberModel.fromJson(m))
          .toList();
    }

    // Options
    final rawOptions = json['options'];
    List<PlanOptionModel> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions
          .whereType<Map<String, dynamic>>()
          .map((o) => PlanOptionModel.fromJson(o))
          .toList();
    }

    // Locations
    final rawLocations = json['locations'];
    List<PlanLocationModel> parsedLocations = [];
    if (rawLocations is List) {
      parsedLocations = rawLocations
          .whereType<Map<String, dynamic>>()
          .map((l) => PlanLocationModel.fromJson(l))
          .toList();
    }

    // Messages
    final rawMessages = json['messages'];
    List<PlanMessageModel> parsedMessages = [];
    if (rawMessages is List) {
      parsedMessages = rawMessages
          .whereType<Map<String, dynamic>>()
          .map((m) => PlanMessageModel.fromJson(m))
          .toList();
    }

    return PlanModel(
      id: json['id'] as int? ?? 0,
      circleId: json['circle_id'] as int? ?? 0,
      createdBy: json['created_by'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      eventType: json['event_type'] as String? ?? 'social',
      startAt: json['start_at'] != null
          ? DateTime.tryParse(json['start_at'].toString())
          : null,
      endAt: json['end_at'] != null
          ? DateTime.tryParse(json['end_at'].toString())
          : null,
      timezone: json['timezone'] as String? ?? 'UTC',
      status: json['status'] as String? ?? 'confirmed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      myRsvp: json['my_rsvp'] as String? ?? 'pending',
      circle: json['circle'] is Map<String, dynamic>
          ? CircleModel.fromJson(json['circle'] as Map<String, dynamic>)
          : null,
      creator: json['creator'] is Map<String, dynamic>
          ? UserModel.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      members: parsedMembers,
      options: parsedOptions,
      locations: parsedLocations,
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'circle_id': circleId,
      'created_by': createdBy,
      'title': title,
      'description': description,
      'event_type': eventType,
      'start_at': startAt?.toIso8601String(),
      'end_at': endAt?.toIso8601String(),
      'timezone': timezone,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'my_rsvp': myRsvp,
      if (circle != null) 'circle': circle!.toJson(),
      if (creator != null) 'creator': creator!.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'options': options.map((o) => o.toJson()).toList(),
      'locations': locations.map((l) => l.toJson()).toList(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  PlanModel copyWith({
    int? id,
    int? circleId,
    int? createdBy,
    String? title,
    String? description,
    String? eventType,
    DateTime? startAt,
    DateTime? endAt,
    String? timezone,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? myRsvp,
    CircleModel? circle,
    UserModel? creator,
    List<PlanMemberModel>? members,
    List<PlanOptionModel>? options,
    List<PlanLocationModel>? locations,
    List<PlanMessageModel>? messages,
  }) {
    return PlanModel(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timezone: timezone ?? this.timezone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      myRsvp: myRsvp ?? this.myRsvp,
      circle: circle ?? this.circle,
      creator: creator ?? this.creator,
      members: members ?? this.members,
      options: options ?? this.options,
      locations: locations ?? this.locations,
      messages: messages ?? this.messages,
    );
  }
}
