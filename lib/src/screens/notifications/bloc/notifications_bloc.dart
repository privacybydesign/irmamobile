import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/irma_repository.dart';
import '../models/notification.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final IrmaRepository _repo; // Repository is hidden by design, because behaviour should be triggered via bloc events.

  NotificationsBloc({
    required IrmaRepository repo,
  })  : _repo = repo,
        super(NotificationsInitial());

  @override
  Stream<NotificationsState> mapEventToState(NotificationsEvent event) async* {
    print("NotificationsBloc - mapEventToState event: $event");

    if (event is LoadNotifications) {
      yield* _mapLoadNotificationsToState();
    } else {
      throw UnimplementedError();
    }
  }

  Stream<NotificationsState> _mapLoadNotificationsToState() async* {
    yield NotificationsLoading();

    // Load the credential notifications
    List<Notification> credentialNotifications = await _loadCredentialNotifications();

    // TODO: Load notifications from other sources here

    yield NotificationsLoaded([
      ...credentialNotifications,
    ]);
  }

  Future<List<Notification>> _loadCredentialNotifications() async {
    for (final cred in _repo.credentials.entries) {

    }

    return [];
  }
}
