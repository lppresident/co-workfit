import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_challenge_model.dart';
import 'package:co_workfit/features/log_run/data/models/log_run_contribution_model.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

class FirestoreLogRunDataSource {
  final FirebaseFirestore firestore;
  static const String _challengesCollection = 'log_run_challenges';
  static const String _contributionsSubcollection = 'contributions';
  static const String _workoutsCollection = 'workouts';

  FirestoreLogRunDataSource({required this.firestore});

  Future<LogRunChallengeModel> createChallenge({
    required String userId, required String userName, required double targetWeight,
    int? recordTimeLimit, bool? allowFutureRecordsOnly, DateTime? expiresAt,
  }) async {
    final now = DateTime.now();
    final challengeRef = firestore.collection(_challengesCollection).doc();
    await challengeRef.set({
      'createdBy': userId, 'creatorName': userName,
      'targetWeight': targetWeight, 'targetDistance': targetWeight,
      'currentDistance': 0.0, 'remainingWeight': targetWeight,
      'participants': [userId], 'participantNames': {userId: userName},
      'status': ChallengeStatus.active.toFirestore(),
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'recordTimeLimit': recordTimeLimit ?? 7,
      'allowFutureRecordsOnly': allowFutureRecordsOnly ?? false,
    });
    final doc = await challengeRef.get();
    return LogRunChallengeModel.fromFirestore(doc);
  }

  Future<void> joinChallenge({required String challengeId, required String userId, required String userName}) async {
    await firestore.collection(_challengesCollection).doc(challengeId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantNames.$userId': userName,
    });
  }

  Future<void> leaveChallenge({required String challengeId, required String userId}) async {
    await firestore.collection(_challengesCollection).doc(challengeId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'participantNames.$userId': FieldValue.delete(),
    });
  }

  Future<LogRunContributionModel> submitWorkout({
    required String challengeId, required String userId, required String userName,
    required String workoutId, required double distance, required String workoutType, required DateTime workoutDate
  }) async {
    return await firestore.runTransaction<LogRunContributionModel>((transaction) async {
      final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
      final challengeDoc = await transaction.get(challengeRef);
      if (!challengeDoc.exists) throw Exception('Challenge not found');
      
      final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);
      final newCurrentDistance = challenge.currentDistance + distance;
      final newRemainingWeight = (challenge.targetWeight - newCurrentDistance).clamp(0.0, challenge.targetWeight);
      final percentage = distance / challenge.targetDistance;

      transaction.update(challengeRef, {
        'currentDistance': newCurrentDistance, 'remainingWeight': newRemainingWeight,
        'status': newCurrentDistance >= challenge.targetDistance ? ChallengeStatus.completed.toFirestore() : ChallengeStatus.active.toFirestore(),
      });

      final contributionRef = challengeRef.collection(_contributionsSubcollection).doc();
      final now = DateTime.now();
      transaction.set(contributionRef, {
        'challengeId': challengeId, 'userId': userId, 'userName': userName,
        'workoutId': workoutId, 'distance': distance, 'workoutType': workoutType,
        'workoutDate': Timestamp.fromDate(workoutDate), 'submittedAt': Timestamp.fromDate(now),
        'percentage': percentage,
      });

      return LogRunContributionModel(
        id: contributionRef.id, challengeId: challengeId, userId: userId, userName: userName,
        workoutId: workoutId, distance: distance, workoutType: _parseWorkoutType(workoutType),
        workoutDate: workoutDate, submittedAt: now, percentage: percentage,
      );
    });
  }

  Future<List<LogRunChallengeModel>> getActiveChallenges(String userId) async {
    final query = await firestore.collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true).get();
    return query.docs.map((doc) => LogRunChallengeModel.fromFirestore(doc)).toList();
  }

  Future<List<LogRunChallengeModel>> getCompletedChallenges(String userId) async {
    final query = await firestore.collection(_challengesCollection)
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true).get();
    return query.docs.map((doc) => LogRunChallengeModel.fromFirestore(doc)).toList();
  }

  Future<LogRunChallengeModel> getChallengeById(String challengeId) async {
    final doc = await firestore.collection(_challengesCollection).doc(challengeId).get();
    if (!doc.exists) throw Exception('Challenge not found');
    return LogRunChallengeModel.fromFirestore(doc);
  }

  Future<List<LogRunContributionModel>> getChallengeContributions(String challengeId) async {
    final query = await firestore.collection(_challengesCollection).doc(challengeId)
        .collection(_contributionsSubcollection).orderBy('submittedAt', descending: true).get();
    return query.docs.map((doc) => LogRunContributionModel.fromFirestore(doc)).toList();
  }

  Stream<LogRunChallengeModel> watchChallenge(String challengeId) {
    return firestore.collection(_challengesCollection).doc(challengeId)
        .snapshots().map((doc) => LogRunChallengeModel.fromFirestore(doc));
  }

  Stream<List<LogRunContributionModel>> watchContributions(String challengeId) {
    return firestore.collection(_challengesCollection).doc(challengeId)
        .collection(_contributionsSubcollection).orderBy('submittedAt', descending: true)
        .snapshots().map((snapshot) => snapshot.docs.map((doc) => LogRunContributionModel.fromFirestore(doc)).toList());
  }

  Future<void> deleteChallenge({required String challengeId, required String userId}) async {
    final challengeRef = firestore.collection(_challengesCollection).doc(challengeId);
    final challengeDoc = await challengeRef.get();
    if (!challengeDoc.exists) throw Exception('Challenge not found');
    
    final challenge = LogRunChallengeModel.fromFirestore(challengeDoc);
    if (challenge.createdBy != userId) throw Exception('Only the creator can delete this challenge');
    
    final contributions = await challengeRef.collection(_contributionsSubcollection).get();
    for (final doc in contributions.docs) {
      await doc.reference.delete();
    }
    await challengeRef.delete();
  }

  WorkoutType _parseWorkoutType(String value) {
    switch (value) {
      case 'running': return WorkoutType.running;
      case 'cycling': return WorkoutType.cycling;
      case 'walking': return WorkoutType.walking;
      case 'swimming': return WorkoutType.swimming;
      case 'weightTraining': return WorkoutType.weightTraining;
      case 'yoga': return WorkoutType.yoga;
      case 'hiking': return WorkoutType.hiking;
      default: return WorkoutType.other;
    }
  }
}
