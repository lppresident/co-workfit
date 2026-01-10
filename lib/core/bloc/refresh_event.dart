import 'package:equatable/equatable.dart';

/// 페이지 새로고침 이벤트
abstract class RefreshEvent extends Equatable {
  const RefreshEvent();

  @override
  List<Object?> get props => [];
}

/// 특정 페이지 새로고침 요청
class RefreshPageRequested extends RefreshEvent {
  final int pageIndex;

  const RefreshPageRequested(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}
