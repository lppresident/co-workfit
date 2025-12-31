import 'package:flutter/material.dart';
import 'package:co_workfit/features/craft/domain/entities/equipped_items_entity.dart';
import 'package:co_workfit/features/craft/domain/entities/item_entity.dart';
import 'package:co_workfit/features/craft/domain/entities/item_recipes.dart';

/// 참가자 순위 정보
class ParticipantRank {
  final String odium;
  final String nickname;
  final double totalDistance;
  final EquippedItemsEntity? equippedItems;

  const ParticipantRank({
    required this.odium,
    required this.nickname,
    required this.totalDistance,
    this.equippedItems,
  });
}

/// 시상대 위젯 - 상위 3명의 참가자를 시상대에 표시
class PodiumWidget extends StatelessWidget {
  final List<ParticipantRank> rankings;

  const PodiumWidget({
    super.key,
    required this.rankings,
  });

  @override
  Widget build(BuildContext context) {
    if (rankings.isEmpty) {
      return const SizedBox.shrink();
    }

    // 최대 3명까지만 표시
    final topThree = rankings.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // 타이틀
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                '🏆 MVP 랭킹',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 시상대
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildPodiumOrder(context, topThree),
            ),
          ),
        ],
      ),
    );
  }

  /// 시상대 순서: 2등 - 1등 - 3등
  List<Widget> _buildPodiumOrder(BuildContext context, List<ParticipantRank> topThree) {
    final widgets = <Widget>[];

    // 2등 (왼쪽)
    if (topThree.length >= 2) {
      widgets.add(_buildPodiumPlace(context, topThree[1], 2));
    } else {
      widgets.add(const SizedBox(width: 100));
    }

    widgets.add(const SizedBox(width: 8));

    // 1등 (가운데)
    if (topThree.isNotEmpty) {
      widgets.add(_buildPodiumPlace(context, topThree[0], 1));
    }

    widgets.add(const SizedBox(width: 8));

    // 3등 (오른쪽)
    if (topThree.length >= 3) {
      widgets.add(_buildPodiumPlace(context, topThree[2], 3));
    } else {
      widgets.add(const SizedBox(width: 100));
    }

    return widgets;
  }

  Widget _buildPodiumPlace(BuildContext context, ParticipantRank participant, int place) {
    // 단상 높이 설정
    final podiumHeight = switch (place) {
      1 => 100.0,
      2 => 70.0,
      3 => 50.0,
      _ => 50.0,
    };

    // 단상 색상
    final podiumColor = switch (place) {
      1 => const Color(0xFFFFD700), // 금색
      2 => const Color(0xFFC0C0C0), // 은색
      3 => const Color(0xFFCD7F32), // 동색
      _ => Colors.grey,
    };

    // 메달 이모지
    final medal = switch (place) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 캐릭터
        _buildCharacter(context, participant, place),
        const SizedBox(height: 4),
        // 닉네임
        SizedBox(
          width: 90,
          child: Text(
            participant.nickname,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 2),
        // 거리
        Text(
          '${participant.totalDistance.toStringAsFixed(1)}km',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        // 단상
        Container(
          width: 100,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                podiumColor,
                podiumColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$medal $place',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacter(BuildContext context, ParticipantRank participant, int place) {
    final equipped = participant.equippedItems;

    // 장착 아이템 가져오기
    ItemEntity? headItem;
    ItemEntity? bodyItem;
    ItemEntity? legsItem;

    if (equipped != null) {
      if (equipped.headItemId != null) {
        headItem = ItemRecipes.allItems.firstWhere(
          (i) => i.id == equipped.headItemId,
          orElse: () => ItemRecipes.allItems.first,
        );
        if (headItem.id != equipped.headItemId) headItem = null;
      }
      if (equipped.bodyItemId != null) {
        bodyItem = ItemRecipes.allItems.firstWhere(
          (i) => i.id == equipped.bodyItemId,
          orElse: () => ItemRecipes.allItems.first,
        );
        if (bodyItem.id != equipped.bodyItemId) bodyItem = null;
      }
      if (equipped.legsItemId != null) {
        legsItem = ItemRecipes.allItems.firstWhere(
          (i) => i.id == equipped.legsItemId,
          orElse: () => ItemRecipes.allItems.first,
        );
        if (legsItem.id != equipped.legsItemId) legsItem = null;
      }
    }

    // 캐릭터 크기 (1등이 더 큼)
    final scale = place == 1 ? 1.0 : 0.8;
    final borderColor = switch (place) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => Colors.grey,
    };

    return Container(
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 머리 슬롯
          Container(
            width: 28 * scale,
            height: 20 * scale,
            decoration: BoxDecoration(
              color: headItem != null
                  ? Color(headItem.rarityColorValue).withValues(alpha: 0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14 * scale),
                topRight: Radius.circular(14 * scale),
              ),
            ),
            child: Center(
              child: Text(
                headItem?.iconEmoji ?? '🧢',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: headItem != null ? null : Colors.grey[400],
                ),
              ),
            ),
          ),
          // 상체 슬롯
          Container(
            width: 32 * scale,
            height: 22 * scale,
            color: bodyItem != null
                ? Color(bodyItem.rarityColorValue).withValues(alpha: 0.2)
                : Colors.grey[200],
            child: Center(
              child: Text(
                bodyItem?.iconEmoji ?? '👕',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: bodyItem != null ? null : Colors.grey[400],
                ),
              ),
            ),
          ),
          // 하체 슬롯
          Container(
            width: 28 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              color: legsItem != null
                  ? Color(legsItem.rarityColorValue).withValues(alpha: 0.2)
                  : Colors.grey[200],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4 * scale),
                bottomRight: Radius.circular(4 * scale),
              ),
            ),
            child: Center(
              child: Text(
                legsItem?.iconEmoji ?? '👖',
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: legsItem != null ? null : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

