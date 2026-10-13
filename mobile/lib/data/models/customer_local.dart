import '../../core/core.dart';

class CustomerLocal {
  final String id;
  final String userId;
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const CustomerLocal({
    required this.id,
    required this.userId,
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = SyncStatus.synced,
  });

  CustomerLocal copyWith({
    String? name,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) =>
      CustomerLocal(
        id: id,
        userId: userId,
        name: name ?? this.name,
        contactPerson: contactPerson ?? this.contactPerson,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'contact_person': contactPerson,
        'email': email,
        'phone': phone,
        'address': address,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
        'sync_status': syncStatus,
      };

  factory CustomerLocal.fromMap(Map<String, Object?> m) => CustomerLocal(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        name: m['name'] as String,
        contactPerson: m['contact_person'] as String?,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String,
        deletedAt: m['deleted_at'] as String?,
        syncStatus: (m['sync_status'] as String?) ?? SyncStatus.synced,
      );

  /// Server JSON -> local row (always "synced").
  factory CustomerLocal.fromServer(Map<String, dynamic> j, String userId) =>
      CustomerLocal(
        id: j['id'].toString(),
        userId: userId,
        name: (j['name'] ?? '').toString(),
        contactPerson: j['contactPerson'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        address: j['address'] as String?,
        createdAt: (j['createdAt'] ?? nowIso()).toString(),
        updatedAt: (j['updatedAt'] ?? nowIso()).toString(),
        syncStatus: SyncStatus.synced,
      );

  /// Body sent to POST/PUT /customers.
  Map<String, dynamic> toApiPayload() => {
        'id': id,
        'name': name,
        'contactPerson': contactPerson,
        'email': email,
        'phone': phone,
        'address': address,
      };
}
