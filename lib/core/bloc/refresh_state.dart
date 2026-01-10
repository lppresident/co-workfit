import 'package:equatable/equatable.dart';

/// 페이지 새로고침 상태
abstract class RefreshState extends Equatable {
  const RefreshState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class RefreshInitial extends RefreshState {
  const RefreshInitial();
}

/// 새로고침 트리거됨
class RefreshTriggered extends RefreshState {
  final int pageIndex;
  final DateTime timestamp;

  const RefreshTriggered(this.pageIndex, this.timestamp);

  @override
  List<Object?> get props => [pageIndex, timestamp];
}
