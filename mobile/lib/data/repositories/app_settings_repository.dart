import 'package:flutter/material.dart' show ThemeMode;

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

  // ---- appearance ----
  Future<ThemeMode> getThemeMode() async => switch (await local.get('theme_mode')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  Future<void> setThemeMode(ThemeMode mode) => local.set('theme_mode', mode.name);

  // ---- notification switches (on by default) ----
  Future<bool> getNotifySync() async => (await local.get('notify_sync')) != '0';

  Future<void> setNotifySync(bool value) => local.set('notify_sync', value ? '1' : '0');

  Future<bool> getNotifyOffline() async => (await local.get('notify_offline')) != '0';

  Future<void> setNotifyOffline(bool value) => local.set('notify_offline', value ? '1' : '0');

  // ---- profile photo (stored on this device) ----
  Future<String?> getProfilePhoto(String userId) => local.get('profile_photo:$userId');

  Future<void> setProfilePhoto(String userId, String? path) => path == null
      ? local.remove('profile_photo:$userId')
      : local.set('profile_photo:$userId', path);

  // ---- per user sync bookkeeping ----
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
