import 'package:co_workfit/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming BlocProvider is provided above this widget in the tree.
    // For standalone testing, you might wrap this with BlocProvider.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ProfileBloc>().add(FetchProfileData());
            },
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileInitial || state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileLoadFailure) {
            return Center(
              child: Text(
                'Failed to load profile: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (state is ProfileLoadSuccess) {
            final user = state.user;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. User Information (Name, Email)
                  Text(
                    user.displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // 2. Summary Statistics (Total Score, Total Workouts, Friends)
                  const Text(
                    'Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatTile(title: 'Total Score', value: user.totalScore.toString()),
                      _StatTile(title: 'Workouts', value: user.workoutCount.toString()),
                      _StatTile(title: 'Friends', value: 'N/A'), // TODO: Add friend count to UserEntity
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Profile Editing (DisplayName Change)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Profile'),
                    onTap: () {
                      // TODO: Implement profile editing dialog/screen
                      // Example: context.read<ProfileBloc>().add(UpdateDisplayName('New Name'));
                    },
                  ),
                  const Divider(),

                  // 4. Logout Button
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      context.read<ProfileBloc>().add(LogoutButtonPressed());
                    },
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Something went wrong.'));
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
