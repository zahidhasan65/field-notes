class ApiConstants {
  ApiConstants._();


  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String syncChanges = '/sync/changes';

  static const Duration timeout = Duration(seconds: 20);

  static String customers() => '/customers';
  static String customer(String id) => '/customers/$id';
  static String sites(String customerId) => '/customers/$customerId/sites';
  static String site(String customerId, String id) =>
      '/customers/$customerId/sites/$id';
  static String notes(String siteId) => '/sites/$siteId/field-notes';
  static String note(String siteId, String id) =>
      '/sites/$siteId/field-notes/$id';
  static String notePhoto(String noteId) => '/field-notes/$noteId/photo';
}
