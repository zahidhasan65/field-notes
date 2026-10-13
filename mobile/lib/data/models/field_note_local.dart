import '../../core/core.dart';
import 'note_status.dart';

class FieldNoteLocal {
  final String id;
  final String siteId;
  final String title;
  final String? description;
  final NoteStatus status;
  final String noteDatetime; // ISO-8601 UTC
  final double? latitude;
  final double? longitude;

  final String? photoUrl;

  final String? photoPath;

  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const FieldNoteLocal({
    required this.id,
    required this.siteId,
    required this.title,
    this.description,
    this.status = NoteStatus.pending,
    required this.noteDatetime,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String? get coordsLabel => hasLocation
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : null;

  DateTime get noteDate =>
      DateTime.tryParse(noteDatetime)?.toLocal() ?? DateTime.now();

  Map<String, Object?> toMap() => {
        'id': id,
        'site_id': siteId,
        'title': title,
        'description': description,
        'status': status.apiValue,
        'note_datetime': noteDatetime,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'photo_path': photoPath,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'sync_status': syncStatus,
      };

  factory FieldNoteLocal.fromMap(Map<String, Object?> m) => FieldNoteLocal(
        id: m['id'] as String,
        siteId: m['site_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        status: NoteStatusX.fromApi(m['status'] as String?),
        noteDatetime: m['note_datetime'] as String,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        photoUrl: m['photo_url'] as String?,
        photoPath: m['photo_path'] as String?,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
        deletedAt: m['deleted_at'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? SyncStatus.synced,
      );


  factory FieldNoteLocal.fromServer(
    Map<String, dynamic> j, {
    FieldNoteLocal? existing,
  }) {
    final photoUrl = j['photoUrl'] as String?;
    final keepFile = existing != null && existing.photoUrl == photoUrl;
    return FieldNoteLocal(
      id: j['id'].toString(),
      siteId: j['siteId'].toString(),
      title: (j['title'] ?? '').toString(),
      description: j['description'] as String?,
      status: NoteStatusX.fromApi(j['status'] as String?),
      noteDatetime: (j['noteDatetime'] ?? nowIso()).toString(),
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      photoUrl: photoUrl,
      photoPath: keepFile ? existing.photoPath : null,
      createdAt: (j['createdAt'] ?? nowIso()).toString(),
      updatedAt: (j['updatedAt'] ?? nowIso()).toString(),
      syncStatus: SyncStatus.synced,
    );
  }

  Map<String, dynamic> toApiPayload() => {
        'id': id,
        'siteId': siteId,
        'title': title,
        'description': description,
        'status': status.apiValue,
        'noteDatetime': noteDatetime,
        'latitude': latitude,
        'longitude': longitude,
      };
}
