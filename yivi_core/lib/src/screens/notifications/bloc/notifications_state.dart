part of "notifications_bloc.dart";

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<Notification> notifications;

  bool get hasUnreadNotifications =>
      notifications.any((notification) => !notification.read);

  /// How many notifications are not read yet.
  int get unreadCount => notifications.where((n) => !n.read).length;

  const NotificationsLoaded(this.notifications);
}

class NotificationsInitialized extends NotificationsLoaded {
  const NotificationsInitialized(super.notifications);
}
