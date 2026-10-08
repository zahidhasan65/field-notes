class CustomerLocal {
  final String id;
  final String userId;
  final String name;
  final String? contactInformation;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const CustomerLocal({
    required this.id,
    required this.userId,
    required this.name,
    this.contactInformation,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'contact_information': contactInformation,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory CustomerLocal.fromMap(Map<String, dynamic> map) {
    return CustomerLocal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      contactInformation: map['contact_information'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: map['sync_status'] as String,
    );
  }
}
