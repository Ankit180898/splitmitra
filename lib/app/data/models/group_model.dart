import 'user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final List<UserModel>? members;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.members,
  });

  // Create from JSON (database record)
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    List<UserModel>? membersList;
    if (json['members'] != null) {
      membersList =
          (json['members'] as List)
              .map((member) => UserModel.fromJson(member))
              .toList();
    }

    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['createdBy'] ?? json['created_by'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now()),
      members: membersList,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create an updated copy
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<UserModel>? members,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }
}
