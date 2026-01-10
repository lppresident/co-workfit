import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/domain/entities/friendship_entity.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';

/// 챌린지 친구 초대 BottomSheet (체크박스로 선택)
class InviteFriendsBottomSheet extends StatefulWidget {
  final String challengeId;
  final String challengeName;
  final Function(List<String> friendIds, List<FriendshipEntity> selectedFriends) onInvite;
  final List<String> alreadyInvitedUserIds; // 이미 초대된 사용자 ID 목록
  final List<String> participantUserIds; // 이미 참가 중인 사용자 ID 목록

  const InviteFriendsBottomSheet({
    super.key,
    required this.challengeId,
    required this.challengeName,
    required this.onInvite,
    this.alreadyInvitedUserIds = const [],
    this.participantUserIds = const [],
  });

  @override
  State<InviteFriendsBottomSheet> createState() => _InviteFriendsBottomSheetState();
}

class _InviteFriendsBottomSheetState extends State<InviteFriendsBottomSheet> {
  final Set<String> _selectedFriendIds = {};
  final Map<String, FriendshipEntity> _friendsMap = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '친구 초대하기',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.challengeName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<SocialBloc, SocialState>(
              builder: (context, state) {
                if (state is SocialLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SocialLoaded) {
                  final friends = state.friends;

                  if (friends.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '초대할 친구가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // friendsMap 업데이트
                  for (final friend in friends) {
                    _friendsMap[friend.friendId] = friend;
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isSelected = _selectedFriendIds.contains(friend.friendId);
                      final isAlreadyInvited = widget.alreadyInvitedUserIds.contains(friend.friendId);
                      final isParticipant = widget.participantUserIds.contains(friend.friendId);
                      final isDisabled = isAlreadyInvited || isParticipant;

                      String? disabledReason;
                      if (isParticipant) {
                        disabledReason = '이미 참가 중';
                      } else if (isAlreadyInvited) {
                        disabledReason = '이미 초대됨';
                      }

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: isDisabled ? null : (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedFriendIds.add(friend.friendId);
                            } else {
                              _selectedFriendIds.remove(friend.friendId);
                            }
                          });
                        },
                        title: Text(
                          friend.friendNickname ?? friend.friendName ?? '알 수 없음',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDisabled ? Colors.grey[400] : null,
                          ),
                        ),
                        subtitle: disabledReason != null
                            ? Text(
                                disabledReason,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                        secondary: Opacity(
                          opacity: isDisabled ? 0.5 : 1.0,
                          child: CircleAvatar(
                            backgroundImage: friend.friendPhotoUrl != null
                                ? NetworkImage(friend.friendPhotoUrl!)
                                : null,
                            child: friend.friendPhotoUrl == null
                                ? Text(
                                    (friend.friendNickname ?? friend.friendName ?? '?')[0],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text('친구 목록을 불러올 수 없습니다'));
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectedFriendIds.isEmpty
                ? null
                : () {
                    final selectedFriends = _selectedFriendIds
                        .map((id) => _friendsMap[id])
                        .whereType<FriendshipEntity>()
                        .toList();
                    widget.onInvite(_selectedFriendIds.toList(), selectedFriends);
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.send),
            label: Text(
              _selectedFriendIds.isEmpty
                  ? '친구를 선택하세요'
                  : '${_selectedFriendIds.length}명 초대하기',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
