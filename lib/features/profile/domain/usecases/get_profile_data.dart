import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/auth/domain/entities/user_entity.dart';
import 'package:co_workfit/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class GetProfileData {
  final ProfileRepository repository;

  GetProfileData(this.repository);

  Future<Either<Failure, UserEntity>> call() async {
    return await repository.getProfileData();
  }
}
