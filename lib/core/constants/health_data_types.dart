import 'package:health/health.dart';

/// HealthKit에서 가져올 데이터 타입들
class HealthDataTypes {
  // 운동 관련 데이터 타입
  static const List<HealthDataType> workoutTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED, // 활동 칼로리
    HealthDataType.DISTANCE_WALKING_RUNNING, // 걷기/달리기 거리
    HealthDataType.DISTANCE_CYCLING, // 사이클링 거리
    HealthDataType.DISTANCE_SWIMMING, // 수영 거리
    HealthDataType.STEPS, // 걸음 수
    HealthDataType.HEART_RATE, // 심박수
    HealthDataType.FLIGHTS_CLIMBED, // 계단 오른 층수
  ];

  // 권한 요청시 사용할 타입 (읽기 전용)
  static const List<HealthDataType> readTypes = [
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.DISTANCE_CYCLING,
    HealthDataType.DISTANCE_SWIMMING,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.FLIGHTS_CLIMBED,
  ];

  // 쓰기 권한이 필요한 타입 (현재는 비어있음, 추후 확장 가능)
  static const List<HealthDataType> writeTypes = [];
}

/// HealthWorkoutActivityType을 우리 앱의 WorkoutType으로 매핑
class HealthWorkoutMapper {
  static String mapWorkoutType(HealthWorkoutActivityType healthType) {
    // health 패키지의 실제 enum 값에 따라 매핑
    final typeName = healthType.name.toLowerCase();

    if (typeName.contains('run')) return 'running';
    if (typeName.contains('cycl') || typeName.contains('bik')) return 'cycling';
    if (typeName.contains('walk')) return 'walking';
    if (typeName.contains('swim')) return 'swimming';
    if (typeName.contains('strength') || typeName.contains('weight')) return 'weightTraining';
    if (typeName.contains('yoga')) return 'yoga';
    if (typeName.contains('hik')) return 'hiking';

    return 'other';
  }
}
