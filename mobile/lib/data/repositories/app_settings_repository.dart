import '../local/data_sources/app_settings_local_data_source.dart';

class AppSettingsRepository {
  final AppSettingsLocalDataSource localDataSource;

  AppSettingsRepository({AppSettingsLocalDataSource? localDataSource})
    : localDataSource = localDataSource ?? AppSettingsLocalDataSource();

  Future<void> saveSetting(String key, String value) async {
    await localDataSource.saveSetting(key, value);
  }

  Future<String?> getSetting(String key) async {
    return localDataSource.getSetting(key);
  }

  Future<void> deleteSetting(String key) async {
    await localDataSource.deleteSetting(key);
  }
}
