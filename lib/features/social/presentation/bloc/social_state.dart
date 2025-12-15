import 'package:equatable/equatable.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';

abstract class SocialState extends Equatable {
  const SocialState();

  @override
  List<Object?> get props => [];
}

class SocialInitial extends SocialState {
  const SocialInitial();
}

class SocialLoading extends SocialState {
  const SocialLoading();
}

class SocialLoaded extends SocialState {
  final List<FriendshipEntity> friends;
  final List<FriendRequestEntity> receivedRequests;
  final List<FriendRequestEntity> sentRequests;
  final List<UserEntity> searchResults;

  const SocialLoaded({
    this.friends = const [],
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.searchResults = const [],
  });

  @override
  List<Object?> get props => [friends, receivedRequests, sentRequests, searchResults];

  SocialLoaded copyWith({
    List<FriendshipEntity>? friends,
    List<FriendRequestEntity>? receivedRequests,
    List<FriendRequestEntity>? sentRequests,
    List<UserEntity>? searchResults,
  }) {
    return SocialLoaded(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

class SocialActionInProgress extends SocialState {
  final SocialLoaded currentState;
  final String actionType;

  const SocialActionInProgress({
    required this.currentState,
    required this.actionType,
  });

  @override
  List<Object?> get props => [currentState, actionType];
}

class SocialActionSuccess extends SocialState {
  final SocialLoaded newState;
  final String message;

  const SocialActionSuccess({
    required this.newState,
    required this.message,
  });

  @override
  List<Object?> get props => [newState, message];
}

class SocialError extends SocialState {
  final String message;
  final SocialLoaded? previousState;

  const SocialError(this.message, {this.previousState});

  @override
  List<Object?> get props => [message, previousState];
}
