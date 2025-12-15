import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_bloc.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_state.dart';
import 'package:co_workfit/features/social/presentation/bloc/social_event.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:co_workfit/features/auth/presentation/bloc/auth_state.dart';

class AddFriendTab extends StatefulWidget {
  const AddFriendTab({super.key});

  @override
  State<AddFriendTab> createState() => _AddFriendTabState();
}

class _AddFriendTabState extends State<AddFriendTab> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _searchUsers() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.read<SocialBloc>().add(SearchUsersByEmailEvent(email));
    }
  }

  void _sendFriendRequest(String receiverId) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<SocialBloc>().add(
        SendFriendRequestEvent(
          senderId: authState.user.id,
          senderName: authState.user.displayName,
          senderPhotoUrl: authState.user.photoUrl,
          receiverId: receiverId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialBloc, SocialState>(
      builder: (context, state) {
        final searchResults = state is SocialLoaded
            ? state.searchResults
            : state is SocialActionSuccess
                ? state.newState.searchResults
                : state is SocialActionInProgress
                    ? state.currentState.searchResults
                    : <dynamic>[];

        final isSearching = state is SocialActionInProgress &&
            state.actionType == 'search_users';

        final authState = context.read<AuthBloc>().state;
        final currentUserId = authState is Authenticated ? authState.user.id : null;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일로 검색',
                  hintText: 'example@email.com',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _emailController.clear();
                      context.read<SocialBloc>().add(const ClearSearchResults());
                    },
                  ),
                ),
                onSubmitted: (_) => _searchUsers(),
              ),
              const SizedBox(height: 16),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '이메일로 친구를 검색하세요',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final user = searchResults[index];
                      final isCurrentUser = user.id == currentUserId;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(user.displayName[0].toUpperCase())
                                : null,
                          ),
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          trailing: isCurrentUser
                              ? const Chip(
                                  label: Text('나'),
                                  backgroundColor: Colors.blue,
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _sendFriendRequest(user.id),
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('요청'),
                                ),
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
