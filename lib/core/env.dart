/// 빌드 시 --dart-define으로 주입되는 환경 값. 시크릿은 레포에 커밋하지 않는다.
///
/// 예: flutter run --dart-define-from-file=dart_defines.json
/// (키 목록은 dart_defines.example.json 참조)
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// 신규 publishable key(sb_publishable_…) 또는 legacy anon key 둘 다 허용
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://us.i.posthog.com',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static bool get hasPosthog => posthogApiKey.isNotEmpty;
}
