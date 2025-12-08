import 'package:equatable/equatable.dart';

/// 사용자 엔티티
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int totalScore;
  final int workoutCount;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.totalScore = 0,
    this.workoutCount = 0,
    required this.createdAt,
    this.lastActiveAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        totalScore,
        workoutCount,
        createdAt,
        lastActiveAt,
      ];

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    int? totalScore,
    int? workoutCount,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      totalScore: totalScore ?? this.totalScore,
      workoutCount: workoutCount ?? this.workoutCount,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
