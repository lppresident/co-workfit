import 'package:co_workfit/core/errors/exceptions.dart';
import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:co_workfit/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> getProfileData() async {
    try {
      final userModel = await remoteDataSource.getProfileData();
      return Right(userModel); // UserModel extends UserEntity, so this is valid
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String newDisplayName) async {
    try {
      await remoteDataSource.updateDisplayName(newDisplayName);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }
}
