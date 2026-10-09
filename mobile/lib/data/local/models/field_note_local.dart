class FieldNoteLocal {
  final String id;
  final String siteId;
  final String? title;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? noteDatetime;
  final String? status;
  final String? photoUrl;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const FieldNoteLocal({
    required this.id,
    required this.siteId,
    this.title,
    this.description,
    this.latitude,
    this.longitude,
    this.noteDatetime,
    this.status,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'note_datetime': noteDatetime,
      'status': status,
      'photo_url': photoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory FieldNoteLocal.fromMap(Map<String, dynamic> map) {
    return FieldNoteLocal(
      id: map['id'] as String,
      siteId: map['site_id'] as String,
      title: map['title'] as String?,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      noteDatetime: map['note_datetime'] as String?,
      status: map['status'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String,
    );
  }
}
