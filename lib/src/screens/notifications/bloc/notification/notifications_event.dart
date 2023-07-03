part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class LoadCachedNotifications extends NotificationsEvent {}

class LoadNewNotifications extends NotificationsEvent {}
