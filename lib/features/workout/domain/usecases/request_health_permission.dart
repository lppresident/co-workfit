import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/domain/repositories/workout_repository.dart';

/// HealthKit 권한 요청 UseCase
class RequestHealthPermission {
  final WorkoutRepository repository;

  RequestHealthPermission(this.repository);

  Future<Either<String, bool>> call() async {
    // 먼저 HealthKit 사용 가능 여부 확인
    final isAvailable = await repository.isHealthKitAvailable();

    if (!isAvailable) {
      return Left('이 기기에서는 HealthKit을 사용할 수 없습니다.');
    }

    // 권한 요청
    return await repository.requestHealthAuthorization();
  }
}
