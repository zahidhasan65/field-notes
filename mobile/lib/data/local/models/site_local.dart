class SiteLocal {
  final String id;
  final String customerId;
  final String siteName;
  final String address;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const SiteLocal({
    required this.id,
    required this.customerId,
    required this.siteName,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'site_name': siteName,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory SiteLocal.fromMap(Map<String, dynamic> map) {
    return SiteLocal(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      siteName: map['site_name'] as String,
      address: map['address'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String,
    );
  }
}
