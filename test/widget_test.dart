import 'package:flutter_test/flutter_test.dart';

import 'package:fortunegame/app.dart';
import 'package:fortunegame/core/analytics/events.dart';

void main() {
  testWidgets('Slice 0: 디버그 홈이 미설정 상태를 표시한다', (tester) async {
    // 테스트 환경은 --dart-define 미주입 → Supabase/PostHog 모두 비활성으로 렌더
    await tester.pumpWidget(const FortuneApp(supabaseReady: false));

    expect(find.text('운세 동물 컴패니언 — Slice 0'), findsOneWidget);
    expect(find.text('익명 인증'), findsOneWidget);
    expect(find.text('no-op 모드'), findsOneWidget);
  });

  test('분석 이벤트 상수는 todo.md Slice 0 정의와 일치한다', () {
    expect(AnalyticsEvents.onboardingComplete, 'onboarding_complete');
    expect(AnalyticsEvents.packOpened, 'pack_opened');
    expect(AnalyticsEvents.sharedAssign, 'shared_assign');
    expect(AnalyticsEvents.sharedLucky, 'shared_lucky');
  });
}
