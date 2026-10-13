import 'customer_local.dart';
import 'field_note_local.dart';
import 'note_status.dart';
import 'site_local.dart';

/// Customer + counts (JOIN/sub-query result, never stored).
class CustomerView {
  final CustomerLocal customer;
  final int siteCount;
  final int noteCount;
  const CustomerView(this.customer, {this.siteCount = 0, this.noteCount = 0});
}

/// Site + its customer name and note count.
class SiteView {
  final SiteLocal site;
  final String customerName;
  final int noteCount;
  const SiteView(this.site, {required this.customerName, this.noteCount = 0});
}

/// Note + its site and customer (loaded with JOINs, nothing is duplicated in the DB).
class NoteView {
  final FieldNoteLocal note;
  final String siteName;
  final String customerId;
  final String customerName;
  const NoteView(
    this.note, {
    required this.siteName,
    required this.customerId,
    required this.customerName,
  });
}

class DeleteImpact {
  final int sites;
  final int notes;
  const DeleteImpact({this.sites = 0, this.notes = 0});
}

/// Form drafts (what the user typed).
class CustomerDraft {
  final String name;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  const CustomerDraft({
    required this.name,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
  });
}

class SiteDraft {
  final String customerId;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  const SiteDraft({
    required this.customerId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
  });
}

class NoteDraft {
  final String siteId;
  final String title;
  final String? description;
  final NoteStatus status;
  final DateTime noteDatetime;
  final double? latitude;
  final double? longitude;

  /// Photo file on this device (null = no photo).
  final String? photoPath;

  /// true when the user picked a new photo or removed the old one.
  final bool photoChanged;

  const NoteDraft({
    required this.siteId,
    required this.title,
    this.description,
    required this.status,
    required this.noteDatetime,
    this.latitude,
    this.longitude,
    this.photoPath,
    this.photoChanged = false,
  });
}
