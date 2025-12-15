import 'package:flutter/material.dart';
import 'package:co_workfit/features/social/domain/entities/leaderboard_entry_entity.dart';

class LeaderboardEntryWidget extends StatelessWidget {
  final LeaderboardEntryEntity entry;
  final bool isCurrentUser;

  const LeaderboardEntryWidget({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isCurrentUser ? 4 : 1,
      color: isCurrentUser ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRankBadge(entry.rank),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundImage: entry.photoUrl != null
                  ? NetworkImage(entry.photoUrl!)
                  : null,
              child: entry.photoUrl == null
                  ? Text(entry.displayName[0].toUpperCase())
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.displayName,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '나',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '운동 ${entry.workoutCount}회',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.totalScore}점',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.blue : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color backgroundColor;
    IconData? icon;
    Color iconColor = Colors.white;

    if (rank == 1) {
      backgroundColor = const Color(0xFFFFD700); // Gold
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      backgroundColor = const Color(0xFFC0C0C0); // Silver
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      backgroundColor = const Color(0xFFCD7F32); // Bronze
      icon = Icons.emoji_events;
    } else {
      backgroundColor = Colors.grey.shade300;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: iconColor, size: 20)
            : Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? iconColor : Colors.black87,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
