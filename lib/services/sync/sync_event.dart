// lib/services/sync/sync_event.dart
//
// Structured data model for offline synchronization events.
// Supports idempotency via unique dedupKey, retry counts, and sanitized payloads.

class SyncEvent {
  final String id;
  final String eventType;
  final String dedupKey;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool synced;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;

  const SyncEvent({
    required this.id,
    required this.eventType,
    required this.dedupKey,
    required this.payload,
    required this.createdAt,
    this.synced = false,
    this.syncedAt,
    this.retryCount = 0,
    this.lastError,
  });

  SyncEvent copyWith({
    String? id,
    String? eventType,
    String? dedupKey,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    bool? synced,
    DateTime? syncedAt,
    int? retryCount,
    String? lastError,
  }) {
    return SyncEvent(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      dedupKey: dedupKey ?? this.dedupKey,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventType': eventType,
      'dedupKey': dedupKey,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
      'syncedAt': syncedAt?.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }

  factory SyncEvent.fromMap(Map<String, dynamic> map) {
    return SyncEvent(
      id: map['id'] as String? ?? '',
      eventType: map['eventType'] as String? ?? 'unknown',
      dedupKey: map['dedupKey'] as String? ?? '',
      payload: map['payload'] is Map
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : <String, dynamic>{},
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      synced: map['synced'] as bool? ?? false,
      syncedAt: map['syncedAt'] is String
          ? DateTime.tryParse(map['syncedAt'] as String)
          : null,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastError: map['lastError'] as String?,
    );
  }
}
