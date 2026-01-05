import 'package:equatable/equatable.dart';

/// 운동 관련 이벤트
abstract class WorkoutEvent extends Equatable {
  const WorkoutEvent();

  @override
  List<Object?> get props => [];
}

/// HealthKit 권한 요청 이벤트
class RequestHealthPermissionEvent extends WorkoutEvent {
  const RequestHealthPermissionEvent();
}

/// 오늘의 운동 가져오기 이벤트
class FetchTodayWorkoutsEvent extends WorkoutEvent {
  const FetchTodayWorkoutsEvent();
}

/// 최근 운동 가져오기 이벤트
class FetchRecentWorkoutsEvent extends WorkoutEvent {
  final int days;

  const FetchRecentWorkoutsEvent({this.days = 7});

  @override
  List<Object?> get props => [days];
}

/// 특정 기간 운동 가져오기 이벤트
class FetchWorkoutsEvent extends WorkoutEvent {
  final DateTime startDate;
  final DateTime endDate;

  const FetchWorkoutsEvent({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// 운동 데이터 새로고침 이벤트
class RefreshWorkoutsEvent extends WorkoutEvent {
  const RefreshWorkoutsEvent();
}

/// Health Connect 설치 유도 이벤트
class InstallHealthConnectEvent extends WorkoutEvent {
  const InstallHealthConnectEvent();
}

/// 운동 거리 수정 이벤트
class UpdateWorkoutDistanceEvent extends WorkoutEvent {
  final String workoutId;
  final double correctedDistance;

  const UpdateWorkoutDistanceEvent({
    required this.workoutId,
    required this.correctedDistance,
  });

  @override
  List<Object?> get props => [workoutId, correctedDistance];
}

/// 운동 거리 초기화 이벤트 (원래 값으로 되돌리기)
class ResetWorkoutDistanceEvent extends WorkoutEvent {
  final String workoutId;

  const ResetWorkoutDistanceEvent({
    required this.workoutId,
  });

  @override
  List<Object?> get props => [workoutId];
}

/// Firestore에서 데이터 가져오기 이벤트
class FetchWorkoutsFromFirestoreEvent extends WorkoutEvent {
  final int days;

  const FetchWorkoutsFromFirestoreEvent({this.days = 30});

  @override
  List<Object?> get props => [days];
}

/// 선택된 운동만 Firestore에 등록하는 이벤트
class RegisterSelectedWorkoutsEvent extends WorkoutEvent {
  final List<String> workoutIds;

  const RegisterSelectedWorkoutsEvent(this.workoutIds);

  @override
  List<Object?> get props => [workoutIds];
}

/// Firestore에 등록된 운동 ID 확인 이벤트
class CheckRegisteredWorkoutsEvent extends WorkoutEvent {
  final int days;

  const CheckRegisteredWorkoutsEvent({this.days = 30});

  @override
  List<Object?> get props => [days];
}
