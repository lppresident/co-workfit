import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/core/presentation/base_page.dart';
import 'package:co_workfit/core/presentation/widgets/standard_app_bar.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';
import 'package:co_workfit/core/widgets/common_empty_widget.dart';
import 'package:co_workfit/core/constants/app_constants.dart';

class AddFriendPage extends BasePage {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends BasePageState<AddFriendPage> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  void loadInitialData() {
    // 보낸 친구 요청 목록 로드
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<SocialBloc>().add(LoadSentFriendRequests(authState.user.id));
    }
  }

  void _searchUsers() {
    final nickname = _nicknameController.text.trim();
    if (nickname.isNotEmpty) {
      context.read<SocialBloc>().add(SearchUsersByNicknameEvent(nickname));
    }
  }

  void _sendFriendRequest(String receiverId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<SocialBloc>().add(
        SendFriendRequestEvent(
          senderId: authState.user.id,
          receiverId: receiverId,
        ),
      );
    }
  }

  @override
  PreferredSizeWidget buildAppBar(BuildContext context) {
    return const StandardAppBar(
      title: '친구 추가',
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        // 현재 상태에서 데이터 추출
        SocialLoaded? loadedState;
        if (state is SocialLoaded) {
          loadedState = state;
        } else if (state is SocialActionSuccess) {
          loadedState = state.newState;
        } else if (state is SocialActionInProgress) {
          loadedState = state.currentState;
        } else if (state is SocialError && state.previousState != null) {
          loadedState = state.previousState;
        }

        final searchResults = loadedState?.searchResults ?? <dynamic>[];
        final sentRequests = loadedState?.sentRequests ?? [];
        final friends = loadedState?.friends ?? [];

        final isSearching = state is SocialActionInProgress &&
            state.actionType == 'search_users';

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is Authenticated ? authState.user.id : null;

        // 이미 요청을 보냈는지 확인하는 헬퍼 함수
        bool hasSentRequestTo(String userId) {
          return sentRequests.any((req) => req.receiverId == userId);
        }

        // 이미 친구인지 확인하는 헬퍼 함수
        bool isFriend(String userId) {
          return friends.any((f) => f.friendId == userId);
        }

        return Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: '닉네임으로 검색',
                  hintText: '닉네임을 입력하세요',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _nicknameController.clear();
                      context.read<SocialBloc>().add(const ClearSearchResults());
                    },
                  ),
                ),
                onChanged: (value) {
                  // Trigger search on every change for autocomplete
                  if (value.isNotEmpty) {
                    context.read<SocialBloc>().add(SearchUsersByNicknameEvent(value));
                  } else {
                    context.read<SocialBloc>().add(const ClearSearchResults());
                  }
                },
                onSubmitted: (_) => _searchUsers(),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              ElevatedButton(
                onPressed: isSearching ? null : _searchUsers,
                child: isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('검색'),
              ),
              const SizedBox(height: 24),
              if (searchResults.isEmpty && !isSearching)
                const Expanded(
                  child: CommonEmptyWidget(
                    icon: Icons.person_search,
                    message: '닉네임으로 친구를 검색하세요',
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final user = searchResults[index];
                      final isCurrentUser = user.id == currentUserId;

                      // 버튼 상태 결정
                      final bool alreadySent = hasSentRequestTo(user.id);
                      final bool alreadyFriend = isFriend(user.id);

                      Widget trailingWidget;
                      if (isCurrentUser) {
                        trailingWidget = const Chip(
                          label: Text('나'),
                          backgroundColor: Colors.blue,
                        );
                      } else if (alreadyFriend) {
                        trailingWidget = const Chip(
                          label: Text('친구'),
                          backgroundColor: Colors.green,
                        );
                      } else if (alreadySent) {
                        trailingWidget = OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('요청됨'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        );
                      } else {
                        trailingWidget = ElevatedButton.icon(
                          onPressed: () => _sendFriendRequest(user.id),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('요청'),
                        );
                      }

                      // nickname 우선, 없으면 displayName 사용
                      final displayName = user.nickname ?? user.displayName;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
                                : null,
                          ),
                          title: Text(displayName),
                          trailing: trailingWidget,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
