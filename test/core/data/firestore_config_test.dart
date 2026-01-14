import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Firestore 설정 파일 일관성 테스트
///
/// 이 테스트는 다음을 검증합니다:
/// 1. firestore.indexes.json - 복합 쿼리에 필요한 색인 정의
/// 2. firestore.rules - 보안 규칙 구문 및 컬렉션 일관성
///
/// develop 브랜치 커밋 시 GitHub Action에서 자동 실행됩니다.
void main() {
  group('Firestore 설정 파일 존재 확인', () {
    test('firestore.indexes.json 파일이 존재해야 함', () {
      final file = File('firestore.indexes.json');
      expect(file.existsSync(), true,
          reason: 'firestore.indexes.json 파일이 프로젝트 루트에 존재해야 합니다');
    });

    test('firestore.rules 파일이 존재해야 함', () {
      final file = File('firestore.rules');
      expect(file.existsSync(), true,
          reason: 'firestore.rules 파일이 프로젝트 루트에 존재해야 합니다');
    });
  });

  group('firestore.indexes.json 검증', () {
    late Map<String, dynamic> indexConfig;
    late List<Map<String, dynamic>> definedIndexes;

    setUpAll(() {
      final file = File('firestore.indexes.json');
      final content = file.readAsStringSync();
      indexConfig = json.decode(content) as Map<String, dynamic>;
      definedIndexes =
          (indexConfig['indexes'] as List).cast<Map<String, dynamic>>();
    });

    test('indexes 배열이 존재해야 함', () {
      expect(indexConfig.containsKey('indexes'), true);
      expect(indexConfig['indexes'], isA<List>());
    });

    test('각 색인은 필수 필드를 가져야 함', () {
      for (final index in definedIndexes) {
        expect(index.containsKey('collectionGroup'), true,
            reason: 'collectionGroup 필드 필요: $index');
        expect(index.containsKey('queryScope'), true,
            reason: 'queryScope 필드 필요: $index');
        expect(index.containsKey('fields'), true,
            reason: 'fields 필드 필요: $index');
      }
    });

    test('queryScope는 COLLECTION 또는 COLLECTION_GROUP이어야 함', () {
      for (final index in definedIndexes) {
        final scope = index['queryScope'] as String;
        expect(
          ['COLLECTION', 'COLLECTION_GROUP'].contains(scope),
          true,
          reason: '잘못된 queryScope: $scope in $index',
        );
      }
    });

    test('중복된 색인이 없어야 함', () {
      final seen = <String>{};
      final duplicates = <String>[];

      for (final index in definedIndexes) {
        final key = _indexKey(index);
        if (seen.contains(key)) {
          duplicates.add(key);
        }
        seen.add(key);
      }

      expect(duplicates, isEmpty, reason: '중복된 색인 발견: $duplicates');
    });

    group('필수 색인 존재 확인', () {
      test('friend_requests: receiverId + status + createdAt DESC', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'friend_requests',
              fields: [
                {'fieldPath': 'receiverId', 'order': 'ASCENDING'},
                {'fieldPath': 'status', 'order': 'ASCENDING'},
                {'fieldPath': 'createdAt', 'order': 'DESCENDING'},
              ]),
          true,
        );
      });

      test('friend_requests: senderId + status + createdAt DESC', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'friend_requests',
              fields: [
                {'fieldPath': 'senderId', 'order': 'ASCENDING'},
                {'fieldPath': 'status', 'order': 'ASCENDING'},
                {'fieldPath': 'createdAt', 'order': 'DESCENDING'},
              ]),
          true,
        );
      });

      test('friends: users (arrayContains) + createdAt DESC', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'friends',
              fields: [
                {'fieldPath': 'users', 'arrayConfig': 'CONTAINS'},
                {'fieldPath': 'createdAt', 'order': 'DESCENDING'},
              ]),
          true,
        );
      });

      test('challenges: participants + status', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'challenges',
              fields: [
                {'fieldPath': 'participants', 'arrayConfig': 'CONTAINS'},
                {'fieldPath': 'status', 'order': 'ASCENDING'},
              ]),
          true,
        );
      });

      test('challenges: participants + endDate', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'challenges',
              fields: [
                {'fieldPath': 'participants', 'arrayConfig': 'CONTAINS'},
                {'fieldPath': 'endDate', 'order': 'ASCENDING'},
              ]),
          true,
        );
      });

      test('invites: inviteeId + status (COLLECTION_GROUP)', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'invites',
              queryScope: 'COLLECTION_GROUP',
              fields: [
                {'fieldPath': 'inviteeId', 'order': 'ASCENDING'},
                {'fieldPath': 'status', 'order': 'ASCENDING'},
              ]),
          true,
        );
      });

      test('workouts: userId + startTime ASC', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'workouts',
              fields: [
                {'fieldPath': 'userId', 'order': 'ASCENDING'},
                {'fieldPath': 'startTime', 'order': 'ASCENDING'},
              ]),
          true,
        );
      });

      test('workouts: userId + startTime DESC', () {
        expect(
          _hasIndex(definedIndexes,
              collection: 'workouts',
              fields: [
                {'fieldPath': 'userId', 'order': 'ASCENDING'},
                {'fieldPath': 'startTime', 'order': 'DESCENDING'},
              ]),
          true,
        );
      });

      test('contributions: workoutId (fieldOverride for COLLECTION_GROUP)', () {
        // 단일 필드 collection group 색인은 fieldOverrides에서 설정
        final fieldOverrides =
            (indexConfig['fieldOverrides'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        final hasContributionsOverride = fieldOverrides.any((override) {
          if (override['collectionGroup'] != 'contributions') return false;
          if (override['fieldPath'] != 'workoutId') return false;
          final indexes = (override['indexes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          return indexes.any((idx) =>
              idx['queryScope'] == 'COLLECTION_GROUP' && idx['order'] == 'ASCENDING');
        });

        expect(hasContributionsOverride, true,
            reason: 'contributions.workoutId COLLECTION_GROUP 색인이 fieldOverrides에 필요합니다');
      });
    });
  });

  group('firestore.rules 검증', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      rulesContent = file.readAsStringSync();
    });

    test('rules_version이 2여야 함', () {
      expect(rulesContent.contains("rules_version = '2'"), true,
          reason: 'Firestore rules version 2가 필요합니다');
    });

    test('service cloud.firestore 블록이 존재해야 함', () {
      expect(rulesContent.contains('service cloud.firestore'), true,
          reason: 'service cloud.firestore 블록이 필요합니다');
    });

    group('필수 컬렉션 규칙 존재 확인', () {
      test('users 컬렉션 규칙', () {
        expect(rulesContent.contains('match /users/{userId}'), true);
      });

      test('friends 컬렉션 규칙', () {
        expect(rulesContent.contains('match /friends/{friendshipId}'), true);
      });

      test('friend_requests 컬렉션 규칙', () {
        expect(rulesContent.contains('match /friend_requests/{requestId}'), true);
      });

      test('workouts 컬렉션 규칙', () {
        expect(rulesContent.contains('match /workouts/{workoutId}'), true);
      });

      test('challenges 컬렉션 규칙', () {
        expect(rulesContent.contains('match /challenges/{challengeId}'), true);
      });

      test('nicknames 컬렉션 규칙', () {
        expect(rulesContent.contains('match /nicknames/{nickname}'), true);
      });
    });

    group('서브컬렉션 규칙 존재 확인', () {
      test('settlements 서브컬렉션 규칙', () {
        expect(rulesContent.contains('match /settlements/{settlementId}'), true);
      });

      test('inventory 서브컬렉션 규칙', () {
        expect(rulesContent.contains('match /inventory/{itemId}'), true);
      });

      test('contributions 서브컬렉션 규칙', () {
        expect(rulesContent.contains('match /contributions/{contributionId}'), true);
      });

      test('invites 서브컬렉션 규칙', () {
        expect(rulesContent.contains('match /invites/{inviteId}'), true);
      });

      test('challenge_archives 서브컬렉션 규칙', () {
        expect(rulesContent.contains('match /challenge_archives/{'), true);
      });
    });

    group('Collection Group Query 규칙 존재 확인', () {
      test('contributions collection group 규칙', () {
        expect(
            rulesContent.contains('match /{path=**}/contributions/{contributionId}'),
            true,
            reason: 'contributions collection group 규칙이 필요합니다');
      });

      test('invites collection group 규칙', () {
        expect(
            rulesContent.contains('match /{path=**}/invites/{inviteId}'),
            true,
            reason: 'invites collection group 규칙이 필요합니다');
      });

      test('challenge_archives collection group 규칙', () {
        expect(
            rulesContent.contains('match /{path=**}/challenge_archives/{'),
            true,
            reason: 'challenge_archives collection group 규칙이 필요합니다');
      });
    });

    group('보안 규칙 패턴 확인', () {
      test('인증 체크가 포함되어야 함', () {
        expect(rulesContent.contains('request.auth != null'), true,
            reason: '인증 체크(request.auth != null)가 필요합니다');
      });

      test('소유자 확인 패턴이 포함되어야 함', () {
        expect(rulesContent.contains('request.auth.uid =='), true,
            reason: '소유자 확인 패턴이 필요합니다');
      });
    });

    test('rules 구문 오류 체크 - 중괄호 균형', () {
      final openBraces = '{'.allMatches(rulesContent).length;
      final closeBraces = '}'.allMatches(rulesContent).length;
      expect(openBraces, closeBraces,
          reason: '중괄호 개수가 일치해야 합니다 (열림: $openBraces, 닫힘: $closeBraces)');
    });
  });

  group('색인-규칙 일관성 검증', () {
    late List<Map<String, dynamic>> definedIndexes;
    late String rulesContent;

    setUpAll(() {
      final indexFile = File('firestore.indexes.json');
      final indexConfig =
          json.decode(indexFile.readAsStringSync()) as Map<String, dynamic>;
      definedIndexes =
          (indexConfig['indexes'] as List).cast<Map<String, dynamic>>();

      final rulesFile = File('firestore.rules');
      rulesContent = rulesFile.readAsStringSync();
    });

    test('색인에 정의된 컬렉션은 규칙에도 정의되어야 함', () {
      final indexedCollections = definedIndexes
          .map((i) => i['collectionGroup'] as String)
          .toSet();

      // Collection group query 대상은 별도 패턴으로 확인
      final collectionGroupIndexes = definedIndexes
          .where((i) => i['queryScope'] == 'COLLECTION_GROUP')
          .map((i) => i['collectionGroup'] as String)
          .toSet();

      for (final collection in indexedCollections) {
        if (collectionGroupIndexes.contains(collection)) {
          // Collection group query 대상은 /{path=**}/ 패턴 확인
          expect(
            rulesContent.contains('/{path=**}/$collection/'),
            true,
            reason: 'Collection group "$collection"에 대한 규칙이 필요합니다',
          );
        } else {
          // 일반 컬렉션은 match /<collection>/ 패턴 확인
          expect(
            rulesContent.contains('match /$collection/'),
            true,
            reason: '컬렉션 "$collection"에 대한 규칙이 필요합니다',
          );
        }
      }
    });
  });
}

/// 색인 존재 여부 확인
bool _hasIndex(
  List<Map<String, dynamic>> indexes, {
  required String collection,
  required List<Map<String, dynamic>> fields,
  String queryScope = 'COLLECTION',
}) {
  for (final index in indexes) {
    if (index['collectionGroup'] != collection) continue;
    if (index['queryScope'] != queryScope) continue;

    final indexFields = (index['fields'] as List).cast<Map<String, dynamic>>();
    if (indexFields.length != fields.length) continue;

    bool allMatch = true;
    for (int i = 0; i < fields.length; i++) {
      final expected = fields[i];
      final actual = indexFields[i];

      if (expected['fieldPath'] != actual['fieldPath']) {
        allMatch = false;
        break;
      }

      if (expected.containsKey('arrayConfig')) {
        if (actual['arrayConfig'] != expected['arrayConfig']) {
          allMatch = false;
          break;
        }
      } else if (expected.containsKey('order')) {
        if (actual['order'] != expected['order']) {
          allMatch = false;
          break;
        }
      }
    }

    if (allMatch) return true;
  }
  return false;
}

/// 색인 고유 키 생성 (중복 검사용)
String _indexKey(Map<String, dynamic> index) {
  final collection = index['collectionGroup'];
  final scope = index['queryScope'];
  final fields = (index['fields'] as List).map((f) {
    final m = f as Map<String, dynamic>;
    if (m.containsKey('arrayConfig')) {
      return '${m['fieldPath']}:${m['arrayConfig']}';
    }
    return '${m['fieldPath']}:${m['order']}';
  }).join(',');
  return '$collection:$scope:$fields';
}
