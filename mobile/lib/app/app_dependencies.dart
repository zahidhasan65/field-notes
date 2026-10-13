import '../core/core.dart';
import '../data/data.dart';
import '../data/local/data_sources/app_settings_local_data_source.dart';
import '../data/local/data_sources/customer_local_data_source.dart';
import '../data/local/data_sources/field_note_local_data_source.dart';
import '../data/local/data_sources/site_local_data_source.dart';
import '../data/local/data_sources/sync_queue_local_data_source.dart';
import '../data/local/data_sources/user_local_data_source.dart';
import '../data/local/database/database_helper.dart';
import '../data/remote/http_sync_remote_data_source.dart';
import '../features/auth/data/auth_remote_data_source.dart';
import '../features/auth/data/auth_repository.dart';
import '../services/google_auth_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/photo_service.dart';
import '../services/photo_storage.dart';

class AppDependencies {
  AppDependencies() {
    final helper = DatabaseHelper.instance;

    final apiService = ApiService();
    session = SessionStorage();
    connectivity = ConnectivityService();
    photoStorage = PhotoStorage();

    final customerDs = CustomerLocalDataSource(helper);
    final siteDs = SiteLocalDataSource(helper);
    final noteDs = FieldNoteLocalDataSource(helper);
    queue = SyncQueueLocalDataSource(helper);
    final userDs = UserLocalDataSource(helper);

    settings = AppSettingsRepository(AppSettingsLocalDataSource(helper));

    customers = CustomerRepository(
      helper: helper,
      customers: customerDs,
      sites: siteDs,
      notes: noteDs,
      queue: queue,
      photos: photoStorage,
    );
    sites = SiteRepository(
      helper: helper,
      customers: customerDs,
      sites: siteDs,
      notes: noteDs,
      queue: queue,
      photos: photoStorage,
    );
    notes = FieldNoteRepository(
      helper: helper,
      notes: noteDs,
      queue: queue,
      photos: photoStorage,
    );
    localData = LocalDataRepository(
      helper: helper,
      notes: noteDs,
      photos: photoStorage,
    );

    engine = SyncEngine(
      helper: helper,
      remote: HttpSyncRemoteDataSource(apiService: apiService, sessionStorage: session),
      customers: customerDs,
      sites: siteDs,
      notes: noteDs,
      queue: queue,
      settings: settings,
      photos: photoStorage,
    );

    auth = AuthRepository(
      remote: AuthRemoteDataSourceImpl(apiService: apiService),
      session: session,
      users: userDs,
      settings: settings,
    );

    googleAuth = GoogleAuthService();
    permissions = PermissionService();
    location = LocationService(permissions);
    photoService = PhotoService(permissions, photoStorage);
  }

  late final SessionStorage session;
  late final ConnectivityService connectivity;
  late final PhotoStorage photoStorage;
  late final SyncQueueLocalDataSource queue;
  late final AppSettingsRepository settings;
  late final CustomerRepository customers;
  late final SiteRepository sites;
  late final FieldNoteRepository notes;
  late final LocalDataRepository localData;
  late final SyncEngine engine;
  late final AuthRepository auth;
  late final GoogleAuthService googleAuth;
  late final PermissionService permissions;
  late final LocationService location;
  late final PhotoService photoService;
}
