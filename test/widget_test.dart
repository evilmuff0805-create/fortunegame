import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fortunegame/app.dart';
import 'package:fortunegame/core/analytics/events.dart';
import 'package:fortunegame/core/models/animal.dart';
import 'package:fortunegame/features/onboarding/onboarding_data.dart';
import 'package:fortunegame/features/onboarding/steps/birth_input_step.dart';
import 'package:fortunegame/features/onboarding/steps/confirm_step.dart';
import 'package:fortunegame/features/onboarding/widgets/animal_placeholder.dart';

void main() {
  testWidgets('Supabase 미설정 → 오프라인 안내 표시', (tester) async {
    await tester.pumpWidget(const FortuneApp(supabaseReady: false));
    expect(find.textContaining('오프라인 골조 모드'), findsOneWidget);
  });

  test('분석 이벤트 상수는 todo.md 정의와 일치', () {
    expect(AnalyticsEvents.onboardingComplete, 'onboarding_complete');
    expect(AnalyticsEvents.packOpened, 'pack_opened');
    expect(AnalyticsEvents.sharedAssign, 'shared_assign');
    expect(AnalyticsEvents.sharedLucky, 'shared_lucky');
  });

  testWidgets('생년월일 입력: 날짜 선택 전 "다음" 비활성', (tester) async {
    BirthInputData? submitted;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BirthInputStep(onSubmit: (d) => submitted = d),
      ),
    ));
    final next = tester.widget<FilledButton>(
      find.ancestor(of: find.text('다음'), matching: find.byType(FilledButton)),
    );
    expect(next.onPressed, isNull); // 날짜 미선택 → 비활성
    expect(submitted, isNull);
  });

  testWidgets('확인 단계: 동물 불변 안내 + 입력값 표시', (tester) async {
    const input = BirthInputData(
      birthDate: '1992-03-17',
      calendarType: 'lunar',
      isLeapMonth: true,
    );
    await tester.pumpWidget(MaterialApp(
      home: ConfirmStep(input: input, onConfirm: () {}, onEdit: () {}),
    ));
    expect(find.text('1992-03-17'), findsOneWidget);
    expect(find.textContaining('윤달'), findsWidgets);
    expect(find.textContaining('한 번 정해지면 바꿀 수 없어'), findsOneWidget);
  });

  testWidgets('동물 플레이스홀더는 이름 이모지를 렌더', (tester) async {
    const animal = Animal(
      id: 'imsu', // 아트 미양산 → 이모지 플레이스홀더
      name: '고래',
      element: '바다',
      personality: '깊은 지혜',
      populationPct: 10,
      assetKey: 'animal_imsu',
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: AnimalPlaceholder(animal: animal))),
    ));
    expect(find.text('🐳'), findsOneWidget);
  });
}
