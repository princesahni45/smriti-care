// lib/services/sync/placeholder_sync_service.dart
//
// Placeholder implementation of SyncService.
//
// STATUS: Planned / Not yet connected to remote cloud backend.
// In offline mode, all mutations persist locally in SQLite / local file storage.

import 'sync_service.dart';

class PlaceholderSyncService implements SyncService {
  const PlaceholderSyncService();

  @override
  Future<bool> isRemoteReachable() async {
    // Planned / Not yet connected. Offline by default.
    return false;
  }

  @override
  Future<void> syncUpstream() async {
    // Planned / Not yet connected. Queued mutations remain in local storage.
  }

  @override
  Future<void> syncDownstream() async {
    // Planned / Not yet connected.
  }
}
