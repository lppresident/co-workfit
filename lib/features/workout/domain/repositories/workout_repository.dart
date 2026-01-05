import 'package:dartz/dartz.dart';
import 'package:co_workfit/features/workout/domain/entities/workout_entity.dart';

/// 운동 데이터 저장소 인터페이스
abstract class WorkoutRepository {
  /// HealthKit 권한 요청
  Future<Either<String, bool>> requestHealthAuthorization();

  /// HealthKit 사용 가능 여부
  Future<bool> isHealthKitAvailable();

  /// Health Connect 설치 유도
  Future<void> installHealthConnect();

  /// Health Connect 설정 화면 열기
  Future<void> openHealthConnectSettings();

  /// 특정 기간의 운동 데이터 가져오기
  Future<Either<String, List<WorkoutEntity>>> getWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 오늘의 운동 데이터
  Future<Either<String, List<WorkoutEntity>>> getTodayWorkouts();

  /// 최근 N일간의 운동 데이터
  Future<Either<String, List<WorkoutEntity>>> getRecentWorkouts({int days = 7});

  /// 운동 데이터 저장 (로컬)
  Future<Either<String, bool>> saveWorkout(WorkoutEntity workout);

  /// 운동 데이터 삭제
  Future<Either<String, bool>> deleteWorkout(String workoutId);

  /// 운동 거리 수정
  Future<Either<String, WorkoutEntity>> updateWorkoutDistance({
    required String workoutId,
    required double correctedDistance,
  });

  /// 운동 거리 수정 초기화 (원래 값으로 되돌리기)
  Future<Either<String, WorkoutEntity>> resetWorkoutDistance({
    required String workoutId,
  });

  /// 로컬에 저장된 모든 운동 데이터
  Future<Either<String, List<WorkoutEntity>>> getLocalWorkouts();

  /// 서버와 동기화
  Future<Either<String, bool>> syncWithServer();

  /// Firestore에 운동 데이터 동기화 (업로드)
  Future<Either<String, int>> syncWorkoutsToFirestore({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Firestore에서 운동 데이터 가져오기
  Future<Either<String, List<WorkoutEntity>>> getWorkoutsFromFirestore({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 통합 운동 데이터 조회 (Health + Firestore 병합)
  Future<Either<String, List<WorkoutEntity>>> getMergedWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 마지막 동기화 시간 조회
  Future<DateTime?> getLastSyncTime();
}
