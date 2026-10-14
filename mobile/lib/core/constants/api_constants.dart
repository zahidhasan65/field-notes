class ApiConstants {
  ApiConstants._();


  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://field-notes-e1zv.onrender.com/api',
  );

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String googleLogin = '/auth/google';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String syncChanges = '/sync/changes';
  static const String me = '/users/me';
  static const String changePassword = '/users/me/change-password';

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

