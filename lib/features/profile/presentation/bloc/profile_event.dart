import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class FetchProfileData extends ProfileEvent {}

class UpdateDisplayName extends ProfileEvent {
  final String newDisplayName;

  const UpdateDisplayName(this.newDisplayName);

  @override
  List<Object> get props => [newDisplayName];
}

class LogoutButtonPressed extends ProfileEvent {}
