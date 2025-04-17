import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
  });

  // Create from Supabase user
  factory UserModel.fromSupabaseUser(dynamic user) {
    if (user == null) {
      throw ArgumentError('User cannot be null');
    }

    // Handle both User and UserResponse types
    final userId = user is User ? user.id : user.user?.id;
    final userEmail = user is User ? user.email : user.user?.email;
    final metadata = user is User ? user.userMetadata : user.user?.userMetadata;
    final createdAt = user is User ? user.createdAt : user.user?.createdAt;

    if (userId == null) {
      throw ArgumentError('User ID cannot be null');
    }

    return UserModel(
      id: userId,
      email: userEmail ?? '',
      displayName: metadata?['display_name'] ?? metadata?['name'],
      avatarUrl: metadata?['avatar_url'],
      createdAt: DateTime.parse(createdAt.toString()),
    );
  }

  // Create from JSON (database record)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['display_name'],
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : (json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now()),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create an updated copy
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
