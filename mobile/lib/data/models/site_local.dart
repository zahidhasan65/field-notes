import '../../core/core.dart';

class SiteLocal {
  final String id;
  final String customerId;
  final String siteName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const SiteLocal({
    required this.id,
    required this.customerId,
    required this.siteName,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String? get coordsLabel => hasLocation
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : null;

  Map<String, Object?> toMap() => {
        'id': id,
        'customer_id': customerId,
        'site_name': siteName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'sync_status': syncStatus,
      };

  factory SiteLocal.fromMap(Map<String, Object?> m) => SiteLocal(
        id: m['id'] as String,
        customerId: m['customer_id'] as String,
        siteName: m['site_name'] as String,
        address: m['address'] as String?,
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
        deletedAt: m['deleted_at'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? SyncStatus.synced,
      );

  factory SiteLocal.fromServer(Map<String, dynamic> j) => SiteLocal(
        id: j['id'].toString(),
        customerId: j['customerId'].toString(),
        siteName: (j['name'] ?? '').toString(),
        address: j['address'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        createdAt: (j['createdAt'] ?? nowIso()).toString(),
        updatedAt: (j['updatedAt'] ?? nowIso()).toString(),
        syncStatus: SyncStatus.synced,
      );

  Map<String, dynamic> toApiPayload() => {
        'id': id,
        'customerId': customerId,
        'name': siteName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}
