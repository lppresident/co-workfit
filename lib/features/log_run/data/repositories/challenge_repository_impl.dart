import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/log_run/domain/entities/challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/repositories/challenge_repository.dart';
import 'package:co_workfit/features/log_run/data/datasources/firestore_challenge_datasource.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final FirestoreChallengeDataSource dataSource;
  ChallengeRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, ChallengeEntity>> createChallenge({
    required String userId,
    required String userNickname,
    required double targetWeight,
    required DateTime challengeDate,
    int? maxParticipants,
  }) async {
    try {
      final challenge = await dataSource.createChallenge(
        userId: userId,
        userNickname: userNickname,
        targetWeight: targetWeight,
        challengeDate: challengeDate,
        maxParticipants: maxParticipants,
      );
      return Right(challenge);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinChallenge({required String challengeId, required String userId, required String userNickname}) async {
    try {
      await dataSource.joinChallenge(challengeId: challengeId, userId: userId, userNickname: userNickname);
      return const Right(null);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> leaveChallenge({required String challengeId, required String userId}) async {
    try {
      await dataSource.leaveChallenge(challengeId: challengeId, userId: userId);
      return const Right(null);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, ContributionEntity>> submitWorkout({
    required String challengeId,
    required String userId,
    required String userNickname,
    required WorkoutEntity workout,
  }) async {
    try {
      final contribution = await dataSource.submitWorkout(
        challengeId: challengeId,
        userId: userId,
        userNickname: userNickname,
        workout: workout,
      );
      return Right(contribution);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChallengeEntity>>> getAllChallenges(String userId) async {
    try {
      final challenges = await dataSource.getAllChallenges(userId);
      return Right(challenges);
    } catch (e, stackTrace) {
      AppLogger.error('ChallengeRepository', 'getAllChallenges 에러: $e\n$stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChallengeEntity>> getChallengeById(String challengeId) async {
    try {
      final challenge = await dataSource.getChallengeById(challengeId);
      return Right(challenge);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, ChallengeEntity>> getChallengeByInviteCode(String inviteCode) async {
    try {
      final challenge = await dataSource.getChallengeByInviteCode(inviteCode);
      return Right(challenge);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<ContributionEntity>>> getChallengeContributions(String challengeId) async {
    try {
      final contributions = await dataSource.getChallengeContributions(challengeId);
      return Right(contributions);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<ContributionEntity>>> getUserContributions({required String challengeId, required String userId}) async {
    try {
      final allContributions = await dataSource.getChallengeContributions(challengeId);
      final userContributions = allContributions.where((c) => c.userId == userId).toList();
      return Right(userContributions);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Stream<Either<Failure, ChallengeEntity>> watchChallenge(String challengeId) {
    try {
      return dataSource.watchChallenge(challengeId).map((challenge) => Right(challenge));
    } catch (e) { return Stream.value(Left(ServerFailure(e.toString()))); }
  }

  @override
  Stream<Either<Failure, List<ContributionEntity>>> watchContributions(String challengeId) {
    try {
      return dataSource.watchContributions(challengeId).map((contributions) => Right(contributions));
    } catch (e) { return Stream.value(Left(ServerFailure(e.toString()))); }
  }

  @override
  Future<Either<Failure, void>> deleteChallenge({required String challengeId, required String userId}) async {
    try {
      await dataSource.deleteChallenge(challengeId: challengeId, userId: userId);
      return const Right(null);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, void>> deleteContribution({
    required String challengeId,
    required String contributionId,
    required String userId,
  }) async {
    try {
      await dataSource.deleteContribution(
        challengeId: challengeId,
        contributionId: contributionId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getChallengesByWorkoutId(
    String workoutId,
  ) async {
    try {
      final challengeIds = await dataSource.getChallengesByWorkoutId(workoutId);
      return Right(challengeIds);
    } catch (e) {
      AppLogger.error('ChallengeRepository', 'getChallengesByWorkoutId 에러: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
