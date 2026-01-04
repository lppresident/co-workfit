import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';
import 'package:co_workfit/core/utils/logger.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_challenge_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/log_run_contribution_entity.dart';
import 'package:co_workfit/features/log_run/domain/entities/workout_type.dart';
import 'package:co_workfit/features/log_run/domain/repositories/log_run_repository.dart';
import 'package:co_workfit/features/log_run/data/datasources/firestore_log_run_datasource.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

class LogRunRepositoryImpl implements LogRunRepository {
  final FirestoreLogRunDataSource dataSource;
  LogRunRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, LogRunChallengeEntity>> createChallenge({
    required String userId,
    required String userNickname,
    required double targetWeight,
    required DateTime challengeDate,
    int? maxParticipants,
    ChallengeType challengeType = ChallengeType.running,
  }) async {
    try {
      final challenge = await dataSource.createChallenge(
        userId: userId,
        userNickname: userNickname,
        targetWeight: targetWeight,
        challengeDate: challengeDate,
        maxParticipants: maxParticipants,
        challengeType: challengeType,
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
  Future<Either<Failure, LogRunContributionEntity>> submitWorkout({
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
  Future<Either<Failure, List<LogRunChallengeEntity>>> getAllChallenges(String userId) async {
    try {
      final challenges = await dataSource.getAllChallenges(userId);
      return Right(challenges);
    } catch (e, stackTrace) {
      AppLogger.error('LogRunRepository', 'getAllChallenges 에러: $e\n$stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LogRunChallengeEntity>> getChallengeById(String challengeId) async {
    try {
      final challenge = await dataSource.getChallengeById(challengeId);
      return Right(challenge);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, LogRunChallengeEntity>> getChallengeByInviteCode(String inviteCode) async {
    try {
      final challenge = await dataSource.getChallengeByInviteCode(inviteCode);
      return Right(challenge);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<LogRunContributionEntity>>> getChallengeContributions(String challengeId) async {
    try {
      final contributions = await dataSource.getChallengeContributions(challengeId);
      return Right(contributions);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Future<Either<Failure, List<LogRunContributionEntity>>> getUserContributions({required String challengeId, required String userId}) async {
    try {
      final allContributions = await dataSource.getChallengeContributions(challengeId);
      final userContributions = allContributions.where((c) => c.userId == userId).toList();
      return Right(userContributions);
    } catch (e) { return Left(ServerFailure(e.toString())); }
  }

  @override
  Stream<Either<Failure, LogRunChallengeEntity>> watchChallenge(String challengeId) {
    try {
      return dataSource.watchChallenge(challengeId).map((challenge) => Right(challenge));
    } catch (e) { return Stream.value(Left(ServerFailure(e.toString()))); }
  }

  @override
  Stream<Either<Failure, List<LogRunContributionEntity>>> watchContributions(String challengeId) {
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
}
