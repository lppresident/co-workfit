import 'package:co_workfit/core/errors/failure.dart';
import 'package:co_workfit/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateDisplayName {
  final ProfileRepository repository;

  UpdateDisplayName(this.repository);

  Future<Either<Failure, void>> call(String newDisplayName) async {
    return await repository.updateDisplayName(newDisplayName);
  }
}
