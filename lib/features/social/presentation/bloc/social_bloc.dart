import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/domain/usecases/get_friends.dart';
import 'package:co_workfit/features/social/domain/usecases/send_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/get_received_friend_requests.dart';
import 'package:co_workfit/features/social/domain/usecases/get_sent_friend_requests.dart';
import 'package:co_workfit/features/social/domain/usecases/accept_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/reject_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/cancel_friend_request.dart';
import 'package:co_workfit/features/social/domain/usecases/search_users_by_email.dart';

class SocialBloc extends Bloc<SocialEvent, SocialState> {
  final GetFriends getFriends;
  final SendFriendRequest sendFriendRequest;
  final GetReceivedFriendRequests getReceivedFriendRequests;
  final GetSentFriendRequests getSentFriendRequests;
  final AcceptFriendRequest acceptFriendRequest;
  final RejectFriendRequest rejectFriendRequest;
  final CancelFriendRequest cancelFriendRequest;
  final SearchUsersByEmail searchUsersByEmail;

  SocialBloc({
    required this.getFriends,
    required this.sendFriendRequest,
    required this.getReceivedFriendRequests,
    required this.getSentFriendRequests,
    required this.acceptFriendRequest,
    required this.rejectFriendRequest,
    required this.cancelFriendRequest,
    required this.searchUsersByEmail,
  }) : super(const SocialInitial()) {
    on<LoadFriends>(_onLoadFriends);
    on<RefreshFriends>(_onRefreshFriends);
    on<LoadReceivedFriendRequests>(_onLoadReceivedFriendRequests);
    on<LoadSentFriendRequests>(_onLoadSentFriendRequests);
    on<SendFriendRequestEvent>(_onSendFriendRequest);
    on<AcceptFriendRequestEvent>(_onAcceptFriendRequest);
    on<RejectFriendRequestEvent>(_onRejectFriendRequest);
    on<CancelFriendRequestEvent>(_onCancelFriendRequest);
    on<SearchUsersByEmailEvent>(_onSearchUsersByEmail);
    on<ClearSearchResults>(_onClearSearchResults);
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
      senderName: event.senderName,
      senderPhotoUrl: event.senderPhotoUrl,
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
          emit(SocialActionSuccess(
            newState: currentState.copyWith(searchResults: []),
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
          final updatedRequests = currentState.receivedRequests
              .where((req) => req.id != event.requestId)
              .toList();

          emit(SocialActionSuccess(
            newState: currentState.copyWith(receivedRequests: updatedRequests),
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
            newState: currentState.copyWith(receivedRequests: updatedRequests),
            message: '친구 요청을 거절했습니다',
          ));
        } else {
          emit(const SocialLoaded());
        }
      },
    );
  }

  Future<void> _onCancelFriendRequest(
    CancelFriendRequestEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'cancel_request',
      ));
    }

    final result = await cancelFriendRequest(event.requestId);

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
          final updatedRequests = currentState.sentRequests
              .where((req) => req.id != event.requestId)
              .toList();

          emit(SocialActionSuccess(
            newState: currentState.copyWith(sentRequests: updatedRequests),
            message: '친구 요청을 취소했습니다',
          ));
        } else {
          emit(const SocialLoaded());
        }
      },
    );
  }

  Future<void> _onSearchUsersByEmail(
    SearchUsersByEmailEvent event,
    Emitter<SocialState> emit,
  ) async {
    final currentState = state;

    if (currentState is SocialLoaded) {
      emit(SocialActionInProgress(
        currentState: currentState,
        actionType: 'search_users',
      ));
    }

    final result = await searchUsersByEmail(event.email);

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
}
