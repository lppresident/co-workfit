import 'package:equatable/equatable.dart';

abstract class SocialEvent extends Equatable {
  const SocialEvent();

  @override
  List<Object?> get props => [];
}

// Friends Events
class LoadFriends extends SocialEvent {
  final String userId;

  const LoadFriends(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshFriends extends SocialEvent {
  final String userId;

  const RefreshFriends(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Friend Request Events
class LoadReceivedFriendRequests extends SocialEvent {
  final String userId;

  const LoadReceivedFriendRequests(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadSentFriendRequests extends SocialEvent {
  final String userId;

  const LoadSentFriendRequests(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SendFriendRequestEvent extends SocialEvent {
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String receiverId;

  const SendFriendRequestEvent({
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.receiverId,
  });

  @override
  List<Object?> get props => [senderId, senderName, senderPhotoUrl, receiverId];
}

class AcceptFriendRequestEvent extends SocialEvent {
  final String requestId;

  const AcceptFriendRequestEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class RejectFriendRequestEvent extends SocialEvent {
  final String requestId;

  const RejectFriendRequestEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class CancelFriendRequestEvent extends SocialEvent {
  final String requestId;

  const CancelFriendRequestEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

// User Search Events
class SearchUsersByEmailEvent extends SocialEvent {
  final String email;

  const SearchUsersByEmailEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class ClearSearchResults extends SocialEvent {
  const ClearSearchResults();
}
