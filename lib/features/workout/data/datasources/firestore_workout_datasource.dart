import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/workout/data/models/workout_model.dart';
import 'package:co_workfit/core/utils/logger.dart';

/// Firestore 운동 데이터 관리
class FirestoreWorkoutDataSource {
  final FirebaseFirestore firestore;
  static const String _workoutsCollection = 'workouts';
  static const String _usersCollection = 'users';

  FirestoreWorkoutDataSource({required this.firestore});

  /// Firestore에 운동 데이터 업로드 (단일)
  Future<void> uploadWorkout(String userId, WorkoutModel workout) async {
    try {
      final docId = '${userId}_${workout.id}';
      final docRef = firestore.collection(_workoutsCollection).doc(docId);

      // Firestore 저장용 데이터
      final data = workout.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

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
          final docId = '${userId}_${workout.id}';
          final docRef = firestore.collection(_workoutsCollection).doc(docId);
          final data = workout.toJson();
          data['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, data, SetOptions(merge: true));
        }

        await batch.commit();
        AppLogger.info('FirestoreWorkoutDS', 'Batch uploaded: ${batchWorkouts.length} workouts');
      }
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Batch upload failed', e);
      rethrow;
    }
  }

  /// Firestore에서 운동 데이터 조회
  Future<List<WorkoutModel>> getWorkouts({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await firestore
          .collection(_workoutsCollection)
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startTime', descending: true)
          .get();

      final workouts = query.docs.map((doc) {
        final data = doc.data();
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
      }).toList();

      AppLogger.info('FirestoreWorkoutDS', 'Fetched ${workouts.length} workouts');
      return workouts;
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Fetch failed', e);
      rethrow;
    }
  }

  /// 특정 운동 ID로 중복 체크
  Future<bool> workoutExists(String userId, String workoutId) async {
    try {
      final docId = '${userId}_$workoutId';
      final doc = await firestore.collection(_workoutsCollection).doc(docId).get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('FirestoreWorkoutDS', 'Exists check failed', e);
      return false;
    }
  }

  /// 운동 삭제
  Future<void> deleteWorkout(String userId, String workoutId) async {
    try {
      final docId = '${userId}_$workoutId';
      await firestore.collection(_workoutsCollection).doc(docId).delete();
      AppLogger.info('FirestoreWorkoutDS', 'Workout deleted: $workoutId');
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
}
