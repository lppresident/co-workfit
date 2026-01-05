import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/domain/entities/friend_request_entity.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends_data.dart';
import 'package:co_workfit/features/social/domain/usecases/send_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/get_received_friend_requests.dart';
import 'package:co_workfit/features/social/domain/usecases/get_sent_friend_requests.dart';
import 'package:co_workfit/features/social/domain/usecases/accept_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/reject_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/search_users_by_nickname.dart';
import 'package:co_workfit/features/social/domain/usecases/remove_friend.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final GetFriends getFriends;
  final GetFriendsData getFriendsData;
  final SendFriendRequest sendFriendRequest;
  final GetReceivedFriendRequests getReceivedFriendRequests;
  final GetSentFriendRequests getSentFriendRequests;
  final AcceptFriendRequest acceptFriendRequest;
  final RejectFriendRequest rejectFriendRequest;
  final SearchUsersByNickname searchUsersByNickname;
  final RemoveFriend removeFriend;

  SocialBloc({
    required this.getFriends,
    required this.getFriendsData,
    required this.sendFriendRequest,
    required this.getReceivedFriendRequests,
    required this.getSentFriendRequests,
    required this.acceptFriendRequest,
    required this.rejectFriendRequest,
    required this.searchUsersByNickname,
    required this.removeFriend,
  }) : super(const SocialInitial()) {
    on<LoadFriendsData>(_onLoadFriendsData);
    on<LoadFriends>(_onLoadFriends);
    on<RefreshFriends>(_onRefreshFriends);
    on<LoadReceivedFriendRequests>(_onLoadReceivedFriendRequests);
    on<LoadSentFriendRequests>(_onLoadSentFriendRequests);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<RejectFriendRequestEvent>(_onRejectFriendRequest);
    on<SearchUsersByNicknameEvent>(
      _onSearchUsersByNickname,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<ClearSearchResults>(_onClearSearchResults);
    on<RemoveFriendEvent>(_onRemoveFriend);
  }

  Future<void> _onLoadFriendsData(
    LoadFriendsData event,
    Emitter<SocialState> emit,
  ) async {
    emit(const SocialLoading());

    final result = await getFriendsData(event.userId);

    result.fold(
      (failure) => emit(SocialError(failure.message)),
      (data) => emit(SocialLoaded(
            friends: data.friends,
            receivedRequests: data.pendingRequests,
            requestCount: data.requestCount,
          )),
    );
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<SocialState> emit,
  ) async {
    emit(const SocialLoading());

    final result = await getFriends(event.userId);

    result.fold(
      (failure) => emit(SocialError(failure.message)),
      (friends) => emit(SocialLoaded(friends: friends)),
    );
  }

  Future<void> _onRefreshFriends(
    RefreshFriends event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;
    if (currentState is SocialLoaded) {
      final result = await getFriends(event.userId);

      result.fold(
        (failure) => emit(SocialError(failure.message, previousState: currentState)),
        (friends) => emit(currentState.copyWith(friends: friends)),
      );
    }
  }

  Future<void> _onLoadReceivedFriendRequests(
    LoadReceivedFriendRequests event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    final result = await getReceivedFriendRequests(event.userId);

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (requests) {
        if (currentState is SocialLoaded) {
          emit(currentState.copyWith(receivedRequests: requests));
        } else {
          emit(SocialLoaded(receivedRequests: requests));
        }
      },
    );
  }

  Future<void> _onLoadSentFriendRequests(
    LoadSentFriendRequests event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    final result = await getSentFriendRequests(event.userId);

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (requests) {
        if (currentState is SocialLoaded) {
          emit(currentState.copyWith(sentRequests: requests));
        } else {
          emit(SocialLoaded(sentRequests: requests));
        }
      },
    );
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequestEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'send_request',
      ));
    }

    final result = await sendFriendRequest(
      senderId: event.senderId,
      receiverId: event.receiverId,
    );

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (_) {
        if (currentState is SocialLoaded) {
          // 새로 보낸 요청을 sentRequests에 추가
          final newRequest = FriendRequestEntity(
            id: '', // 서버에서 생성된 ID는 알 수 없음
            senderId: event.senderId,
            receiverId: event.receiverId,
            status: FriendRequestStatus.pending,
            createdAt: DateTime.now(),
          );
          final updatedSentRequests = [...currentState.sentRequests, newRequest];

          emit(SocialActionSuccess(
            newState: currentState.copyWith(
              searchResults: [],
              sentRequests: updatedSentRequests,
            ),
            message: '친구 요청을 보냈습니다',
          ));
        } else {
          emit(const SocialLoaded());
        }
      },
    );
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequestEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'accept_request',
      ));
    }

    final result = await acceptFriendRequest(event.requestId);

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (_) {
        if (currentState is SocialLoaded) {
          // 수락된 요청 찾기
          final acceptedRequest = currentState.receivedRequests
              .where((req) => req.id == event.requestId)
              .firstOrNull;

          // 요청 목록에서 제거
          final updatedRequests = currentState.receivedRequests
              .where((req) => req.id != event.requestId)
              .toList();

          // 새 친구를 목록에 추가 (요청자 정보 사용)
          final updatedFriends = [...currentState.friends];
          if (acceptedRequest != null) {
            final newFriend = FriendshipEntity(
              id: '', // Firestore에서 자동 생성된 ID는 알 수 없음
              userId: acceptedRequest.receiverId,
              friendId: acceptedRequest.senderId,
              createdAt: DateTime.now(),
              friendName: acceptedRequest.senderName,
              friendNickname: acceptedRequest.senderNickname,
              friendEmail: acceptedRequest.senderEmail,
              friendPhotoUrl: acceptedRequest.senderPhotoUrl,
            );
            updatedFriends.insert(0, newFriend); // 맨 앞에 추가
          }

          emit(SocialActionSuccess(
            newState: currentState.copyWith(
              friends: updatedFriends,
              receivedRequests: updatedRequests,
              requestCount: updatedRequests.length,
            ),
            message: '친구 요청을 수락했습니다',
          ));
        } else {
          emit(const SocialLoaded());
        }
      },
    );
  }

  Future<void> _onRejectFriendRequest(
    RejectFriendRequestEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'reject_request',
      ));
    }

    final result = await rejectFriendRequest(event.requestId);

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (_) {
        if (currentState is SocialLoaded) {
          final updatedRequests = currentState.receivedRequests
              .where((req) => req.id != event.requestId)
              .toList();

          emit(SocialActionSuccess(
            newState: currentState.copyWith(
              receivedRequests: updatedRequests,
              requestCount: updatedRequests.length,
            ),
            message: '친구 요청을 거절했습니다',
          ));
        } else {
          emit(const SocialLoaded());
        }
      },
    );
  }

  Future<void> _onSearchUsersByNickname(
    SearchUsersByNicknameEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'search_users',
      ));
    }

    final result = await searchUsersByNickname(event.nickname);

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (users) {
        if (currentState is SocialLoaded) {
          emit(currentState.copyWith(searchResults: users));
        } else {
          emit(SocialLoaded(searchResults: users));
        }
      },
    );
  }

  Future<void> _onClearSearchResults(
    ClearSearchResults event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(currentState.copyWith(searchResults: []));
    }
  }

  Future<void> _onRemoveFriend(
    RemoveFriendEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'remove_friend',
      ));
    }

    final result = await removeFriend(
      userId: event.userId,
      friendId: event.friendId,
    );

    result.fold(
      (failure) {
        if (currentState is SocialLoaded) {
          emit(SocialError(failure.message, previousState: currentState));
        } else {
          emit(SocialError(failure.message));
        }
      },
      (_) {
        if (currentState is SocialLoaded) {
          // 친구 목록에서 삭제된 친구 제거
          final updatedFriends = currentState.friends
              .where((f) => f.friendId != event.friendId)
              .toList();

          emit(SocialActionSuccess(
            newState: currentState.copyWith(friends: updatedFriends),
            message: '친구가 삭제되었습니다',
          ));
        } else {
          emit(const SocialLoaded());
        }
      },
    );
  }
}
