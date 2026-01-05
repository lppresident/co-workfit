import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/workout/data/models/workout_model.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Firestore 운동 데이터 관리
/// 
/// 데이터 구조: /workouts/{workoutId}
/// - 최상위 컬렉션으로 관리
/// - 다른 사용자의 workout도 참조 가능 (챌린지 기여 상세 보기 등)
/// - userId 필드로 소유자 구분
/// - 복합 색인 필요: (userId, startTime)
class FirestoreWorkoutDataSource {
  final FirebaseFirestore firestore;
  static const String _workoutsCollection = 'workouts';
  static const String _usersCollection = 'users';

  FirestoreWorkoutDataSource({required this.firestore});

  /// workouts 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _workoutsRef =>
      firestore.collection(_workoutsCollection);

  /// Firestore에 운동 데이터 업로드 (단일)
  Future<void> uploadWorkout(String userId, WorkoutModel workout) async {
    try {
      final docRef = _workoutsRef.doc(workout.id);

      final data = workout.toJson();
      data['userId'] = userId; // userId 필드 포함
      
      // DateTime을 Timestamp로 변환 (Firestore 쿼리 호환성)
      data['startTime'] = Timestamp.fromDate(workout.startTime);
      data['endTime'] = Timestamp.fromDate(workout.endTime);
      data['createdAt'] = Timestamp.fromDate(workout.createdAt);
      if (workout.syncedAt != null) {
        data['syncedAt'] = Timestamp.fromDate(workout.syncedAt!);
      }
      data['updatedAt'] = FieldValue.serverTimestamp();

      AppLogger.info('FirestoreWorkoutDS', 'Uploading workout - userId: $userId, workoutId: ${workout.id}');
      
      await docRef.set(data, SetOptions(merge: true));
      AppLogger.info('FirestoreWorkoutDS', 'Workout uploaded: ${workout.id}');
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Upload failed', e);
      rethrow;
    }
  }

  /// Firestore에 운동 데이터 일괄 업로드 (배치)
  Future<void> uploadWorkouts(String userId, List<WorkoutModel> workouts) async {
    if (workouts.isEmpty) return;

    try {
      // Firestore는 한 번에 500개까지 배치 가능
      const batchSize = 500;
      for (var i = 0; i < workouts.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < workouts.length) ? i + batchSize : workouts.length;
        final batchWorkouts = workouts.sublist(i, end);

        for (final workout in batchWorkouts) {
          final docRef = _workoutsRef.doc(workout.id);
          final data = workout.toJson();
          data['userId'] = userId; // userId 필드 포함
          
          // DateTime을 Timestamp로 변환 (Firestore 쿼리 호환성)
          data['startTime'] = Timestamp.fromDate(workout.startTime);
          data['endTime'] = Timestamp.fromDate(workout.endTime);
          data['createdAt'] = Timestamp.fromDate(workout.createdAt);
          if (workout.syncedAt != null) {
            data['syncedAt'] = Timestamp.fromDate(workout.syncedAt!);
          }
          data['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, data, SetOptions(merge: true));
        }

        await batch.commit();
        AppLogger.info('FirestoreWorkoutDS', 'Batch uploaded: ${batchWorkouts.length} workouts for user: $userId');
      }
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Batch upload failed', e);
      rethrow;
    }
  }

  /// Firestore에서 운동 데이터 조회 (특정 사용자)
  Future<List<WorkoutModel>> getWorkouts({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      AppLogger.info('FirestoreWorkoutDS', 'Querying workouts for userId: $userId, startDate: $startDate, endDate: $endDate');
      
      // 복합 색인 필요: (userId, startTime)
      final query = await _workoutsRef
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startTime', descending: true)
          .get();
      
      AppLogger.info('FirestoreWorkoutDS', 'Query returned ${query.docs.length} documents');

      final workouts = query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _parseWorkoutModel(data);
      }).toList();

      AppLogger.info('FirestoreWorkoutDS', 'Fetched ${workouts.length} workouts');
      return workouts;
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Fetch failed', e);
      rethrow;
    }
  }

  /// 특정 workout ID로 조회 (다른 사용자의 workout도 조회 가능)
  Future<WorkoutModel?> getWorkoutById(String workoutId) async {
    try {
      final doc = await _workoutsRef.doc(workoutId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return _parseWorkoutModel(data);
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Get workout by ID failed', e);
      rethrow;
    }
  }

  /// 여러 workout ID로 일괄 조회
  Future<List<WorkoutModel>> getWorkoutsByIds(List<String> workoutIds) async {
    if (workoutIds.isEmpty) return [];

    try {
      // Firestore whereIn은 최대 10개까지만 지원
      final results = <WorkoutModel>[];
      for (var i = 0; i < workoutIds.length; i += 10) {
        final batchIds = workoutIds.sublist(
          i,
          (i + 10 < workoutIds.length) ? i + 10 : workoutIds.length,
        );
        
        final query = await _workoutsRef
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();

        for (final doc in query.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          results.add(_parseWorkoutModel(data));
        }
      }

      AppLogger.info('FirestoreWorkoutDS', 'Fetched ${results.length} workouts by IDs');
      return results;
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Get workouts by IDs failed', e);
      rethrow;
    }
  }

  /// 특정 운동 ID로 중복 체크
  Future<bool> workoutExists(String userId, String workoutId) async {
    try {
      final doc = await _workoutsRef.doc(workoutId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Exists check failed', e);
      return false;
    }
  }

  /// 운동 삭제
  Future<void> deleteWorkout(String userId, String workoutId) async {
    try {
      // 소유자 확인
      final doc = await _workoutsRef.doc(workoutId).get();
      if (doc.exists && doc.data()?['userId'] == userId) {
        await _workoutsRef.doc(workoutId).delete();
        AppLogger.info('FirestoreWorkoutDS', 'Workout deleted: $workoutId');
      } else {
        throw Exception('권한이 없거나 존재하지 않는 운동입니다');
      }
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Delete failed', e);
      rethrow;
    }
  }

  /// 마지막 동기화 시간 조회
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final doc = await firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['lastWorkoutSyncAt'] == null) return null;

      final timestamp = data['lastWorkoutSyncAt'] as Timestamp;
      return timestamp.toDate();
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Get last sync time failed', e);
      return null;
    }
  }

  /// 마지막 동기화 시간 업데이트
  Future<void> updateLastSyncTime(String userId, DateTime syncTime) async {
    try {
      await firestore.collection(_usersCollection).doc(userId).set({
        'lastWorkoutSyncAt': Timestamp.fromDate(syncTime),
      }, SetOptions(merge: true));
      AppLogger.info('FirestoreWorkoutDS', 'Last sync time updated');
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Update last sync time failed', e);
      rethrow;
    }
  }

  /// 특정 기간의 등록된 운동 ID 목록 조회
  Future<Set<String>> getRegisteredWorkoutIds({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _workoutsRef
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final workoutIds = query.docs.map((doc) => doc.id).toSet();

      AppLogger.info('FirestoreWorkoutDS', 'Fetched ${workoutIds.length} registered workout IDs');
      return workoutIds;
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Get registered workout IDs failed', e);
      rethrow;
    }
  }

  /// Firestore 데이터를 WorkoutModel로 파싱
  WorkoutModel _parseWorkoutModel(Map<String, dynamic> data) {
    // Timestamp를 DateTime으로 변환
    if (data['startTime'] is Timestamp) {
      data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
    }
    if (data['endTime'] is Timestamp) {
      data['endTime'] = (data['endTime'] as Timestamp).toDate().toIso8601String();
    }
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
    }
    if (data['syncedAt'] is Timestamp) {
      data['syncedAt'] = (data['syncedAt'] as Timestamp).toDate().toIso8601String();
    }
    return WorkoutModel.fromJson(data);
  }
}
