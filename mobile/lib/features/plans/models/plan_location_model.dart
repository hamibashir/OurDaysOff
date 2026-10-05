import '../../auth/models/user_model.dart';

class PlanLocationVoteModel {
  final int id;
  final int planLocationId;
  final int userId;
  final DateTime? createdAt;

  const PlanLocationVoteModel({
    required this.id,
    required this.planLocationId,
    required this.userId,
    this.createdAt,
  });

  factory PlanLocationVoteModel.fromJson(Map<String, dynamic> json) {
    return PlanLocationVoteModel(
      id: json['id'] as int? ?? 0,
      planLocationId: json['plan_location_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_location_id': planLocationId,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class PlanLocationModel {
  final int id;
  final int planId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final int? createdBy;
  final UserModel? creator;
  final List<PlanLocationVoteModel> votes;

  const PlanLocationModel({
    required this.id,
    required this.planId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.notes,
    this.createdBy,
    this.creator,
    this.votes = const [],
  });

  int get voteCount => votes.length;

  bool hasVoted(int userId) => votes.any((v) => v.userId == userId);

  factory PlanLocationModel.fromJson(Map<String, dynamic> json) {
    var rawVotes = json['votes'];
    List<PlanLocationVoteModel> parsedVotes = [];
    if (rawVotes is List) {
      parsedVotes = rawVotes
          .whereType<Map<String, dynamic>>()
          .map((v) => PlanLocationVoteModel.fromJson(v))
          .toList();
    }

    return PlanLocationModel(
      id: json['id'] as int? ?? 0,
      planId: json['plan_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as int?,
      creator: json['creator'] is Map<String, dynamic>
          ? UserModel.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      votes: parsedVotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'created_by': createdBy,
      if (creator != null) 'creator': creator!.toJson(),
      'votes': votes.map((v) => v.toJson()).toList(),
    };
  }

  PlanLocationModel copyWith({
    int? id,
    int? planId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    int? createdBy,
    UserModel? creator,
    List<PlanLocationVoteModel>? votes,
  }) {
    return PlanLocationModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      creator: creator ?? this.creator,
      votes: votes ?? this.votes,
    );
  }
}
