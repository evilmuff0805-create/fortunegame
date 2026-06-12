import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../env.dart';

/// PostHog 래퍼. POSTHOG_API_KEY가 없으면 전체 no-op (개발·테스트 환경).
class AnalyticsService {
  AnalyticsService._();

  static final instance = AnalyticsService._();

  bool _enabled = false;

  Future<void> init() async {
    if (!Env.hasPosthog) {
      debugPrint('Analytics: POSTHOG_API_KEY 없음 — no-op 모드');
      return;
    }
    final config = PostHogConfig(Env.posthogApiKey)..host = Env.posthogHost;
    await Posthog().setup(config);
    _enabled = true;
  }

  /// Supabase user id로 식별 — 기기 변경·재설치에도 동일 사용자로 집계 (D1 보호 검증용)
  Future<void> identify(String userId) async {
    if (!_enabled) return;
    await Posthog().identify(userId: userId);
  }

  Future<void> capture(String event, {Map<String, Object>? properties}) async {
    if (!_enabled) {
      debugPrint('Analytics(no-op): $event $properties');
      return;
    }
    await Posthog().capture(eventName: event, properties: properties);
  }
}
