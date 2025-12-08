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
