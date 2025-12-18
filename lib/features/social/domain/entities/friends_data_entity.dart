import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';

/// 친구 데이터 통합 엔티티 (친구 목록 + 받은 요청)
class FriendsDataEntity extends Equatable {
  final List<FriendshipEntity> friends;
  final List<FriendRequestEntity> pendingRequests;
  final int requestCount;

  const FriendsDataEntity({
    required this.friends,
    required this.pendingRequests,
    required this.requestCount,
  });

  @override
  List<Object?> get props => [friends, pendingRequests, requestCount];

  FriendsDataEntity copyWith({
    List<FriendshipEntity>? friends,
    List<FriendRequestEntity>? pendingRequests,
    int? requestCount,
  }) {
    return FriendsDataEntity(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      requestCount: requestCount ?? this.requestCount,
    );
  }
}
