import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class LogoutUser {
  final ProfileRepository repository;

  LogoutUser(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
