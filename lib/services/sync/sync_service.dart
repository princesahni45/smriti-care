// lib/services/sync/sync_service.dart
//
// Interface for synchronizing patient activities, caregiver alerts,
// and reminders with a remote healthcare/cloud repository.

abstract class SyncService {
  /// Whether the device is currently online and server is reachable.
  Future<bool> isRemoteReachable();

  /// Pushes queued local offline records (game scores, completed reminders) to the server.
  Future<void> syncUpstream();

  /// Pulls the latest caregiver reminders and configurations to local storage.
  Future<void> syncDownstream();
}
