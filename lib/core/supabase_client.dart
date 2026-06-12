import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Supabase 초기화 + 익명 인증 부트스트랩.
///
/// 첫 실행 즉시 익명 user를 만들어 클라우드 백업의 기반을 깐다 (D1: 동물 손실 방지).
/// Slice 2에서 소셜 로그인으로 익명 계정을 승격한다.
abstract final class SupabaseBootstrap {
  static SupabaseClient get client => Supabase.instance.client;

  /// 초기화 성공 여부. 미설정(SUPABASE_URL 없음)이거나 오프라인이면 false.
  static Future<bool> init() async {
    if (!Env.hasSupabase) {
      debugPrint('Supabase: SUPABASE_URL/ANON_KEY 미설정 — 오프라인 골조 모드');
      return false;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseKey,
    );
    await _ensureSignedIn();
    return true;
  }

  static Future<void> _ensureSignedIn() async {
    final auth = client.auth;
    if (auth.currentSession != null) return;
    try {
      await auth.signInAnonymously();
    } on AuthException catch (e) {
      // 오프라인 등으로 실패해도 앱 시작은 막지 않는다 — 다음 실행에서 재시도
      debugPrint('Supabase: 익명 로그인 실패 — ${e.message}');
    }
  }

  static String? get currentUserId => client.auth.currentUser?.id;
}
