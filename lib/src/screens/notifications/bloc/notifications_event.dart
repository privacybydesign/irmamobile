part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

// Initialize event; reads from cache, cleans up the notifications and loads new ones
// This event should be called right after the bloc is created (NotificationsBloc()..add(Initialize()))
class Initialize extends NotificationsEvent {}

// LoadNotifications event only loads new notifications
class LoadNotifications extends NotificationsEvent {}

class MarkAllNotificationsAsRead extends NotificationsEvent {}

class MarkNotificationAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);
}

class SoftDeleteNotification extends NotificationsEvent {
  final String notificationId;

  const SoftDeleteNotification(this.notificationId);
}
