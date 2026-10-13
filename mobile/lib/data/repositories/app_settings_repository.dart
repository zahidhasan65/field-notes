import '../local/data_sources/app_settings_local_data_source.dart';
import '../models/note_status.dart';

class AppSettingsRepository {
  AppSettingsRepository(this.local);

  final AppSettingsLocalDataSource local;

  static const _defaultStatusKey = 'default_note_status';

  Future<NoteStatus> getDefaultNoteStatus() async =>
      NoteStatusX.fromApi(await local.get(_defaultStatusKey));

  Future<void> setDefaultNoteStatus(NoteStatus status) =>
      local.set(_defaultStatusKey, status.apiValue);

  Future<bool> isRestoreDone(String userId) async =>
      (await local.get('restore_done:$userId')) == '1';

  Future<void> setRestoreDone(String userId) =>
      local.set('restore_done:$userId', '1');

  Future<DateTime?> getLastPull(String userId) async =>
      _date(await local.get('last_pull:$userId'));

  Future<void> setLastPull(String userId, DateTime value) =>
      local.set('last_pull:$userId', value.toUtc().toIso8601String());

  Future<DateTime?> getLastSynced(String userId) async =>
      _date(await local.get('last_synced:$userId'));

  Future<void> setLastSynced(String userId, DateTime value) =>
      local.set('last_synced:$userId', value.toUtc().toIso8601String());

  DateTime? _date(String? v) => v == null ? null : DateTime.tryParse(v)?.toLocal();
}
