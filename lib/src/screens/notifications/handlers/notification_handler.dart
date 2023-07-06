import '../../../data/irma_repository.dart';
import '../models/notification.dart';

// This is the base class for all notification handlers
// It contains a method that takes in a list of notifications and returns a list of notifications with new notifications added
abstract class NotificationHandler {
  Future<List<Notification>> loadNotifications(IrmaRepository repo, List<Notification> notifications);
  List<Notification> cleanUp(IrmaRepository repo, List<Notification> notifications);
}
