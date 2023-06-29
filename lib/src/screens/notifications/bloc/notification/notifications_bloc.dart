import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../data/irma_repository.dart';
import '../../models/notification.dart';
import '../credential_status_notification/credential_status_notification_cubit.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

// BLoC containing the general notifications logic
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  Iterable<Notification> notifications = [];

  final CredentialStatusNotificationCubit _credentialNotificationsCubit;

  NotificationsBloc({
    required IrmaRepository repo,
  })  : _credentialNotificationsCubit = CredentialStatusNotificationCubit(repo: repo)..loadCache(),
        super((NotificationsInitial()));

  @override
  Stream<NotificationsState> mapEventToState(NotificationsEvent event) async* {
    print('NotificationsBloc - mapEventToState event: $event');

    if (event is LoadNotifications) {
      yield* _mapLoadNotificationsToState();
    } else {
      throw UnimplementedError();
    }
  }

  Stream<NotificationsState> _mapLoadNotificationsToState() async* {
    yield NotificationsLoading();

    final newCredentialNotifications = _loadCredentialStatusNotifications();

    // TODO: Load notifications from other sources here

    yield NotificationsLoaded([
      ...newCredentialNotifications,
      ...notifications,
    ]);
  }

  Iterable<Notification> _loadCredentialStatusNotifications() {
    // Load the credential notifications in the cubit
    _credentialNotificationsCubit.loadCredentialStatusNotifications();

    // Pull the credential notifications from the cubit
    final newCredentialNotifications =
        (_credentialNotificationsCubit.state as CredentialStatusNotificationsLoaded).credentialStatusNotifications;

    // Clear the credential notifications in the cubit
    _credentialNotificationsCubit.clear();

    // Return the credential notifications
    // These are new status notifications that the user has not seen yet.
    return newCredentialNotifications;
  }
}
