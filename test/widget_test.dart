import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fortunegame/app.dart';
import 'package:fortunegame/core/analytics/events.dart';
import 'package:fortunegame/core/korean.dart';
import 'package:fortunegame/core/models/animal.dart';
import 'package:fortunegame/core/models/item.dart';
import 'package:fortunegame/features/onboarding/onboarding_data.dart';
import 'package:fortunegame/features/onboarding/steps/birth_input_step.dart';
import 'package:fortunegame/features/onboarding/steps/confirm_step.dart';
import 'package:fortunegame/features/onboarding/widgets/animal_placeholder.dart';
import 'package:fortunegame/features/daily/envelope_tear.dart';
import 'package:fortunegame/features/daily/grade_style.dart';
import 'package:fortunegame/features/dressup/dressed_animal.dart';

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

  testWidgets('봉투 찢기: 탭하면 바로 열림(스킵)', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EnvelopeTear(leak: 'none', onOpened: () => opened = true),
      ),
    ));
    expect(find.text('봉투를 쭉 찢어봐'), findsOneWidget);
    await tester.tap(find.byType(EnvelopeTear));
    await tester.pump(const Duration(milliseconds: 300)); // 완료 딜레이
    expect(opened, isTrue);
  });

  test('등급 스타일: 맑음 이상만 공유 가능', () {
    expect(GradeStyle.of('rainbow').shareable, isTrue);
    expect(GradeStyle.of('sunny').shareable, isTrue);
    expect(GradeStyle.of('calm').shareable, isFalse);
    expect(GradeStyle.of('rainy').shareable, isFalse);
    expect(GradeStyle.of('rainy').label, '비');
  });

  test('한국어 조사: 받침 유무로 을/를 자동 선택', () {
    expect(josaEulReul('베레모'), '를'); // 받침 없음
    expect(josaEulReul('우산 부적'), '을'); // 적 = 받침
    expect(josaEulReul('위로 인형'), '을'); // 형 = 받침
    expect(josaEulReul('행운 카드'), '를'); // 드 = 받침 없음
    expect(josaIGa('고래'), '가');
    expect(josaIGa('곰'), '이');
  });

  testWidgets('꾸민 동물: 모자 장착 시 합성 렌더(앵커)에 모자 포함', (tester) async {
    const animal = Animal(
      id: 'gito', name: '카피바라', element: '밭·대지',
      personality: '보살핌', populationPct: 10, assetKey: 'animal_gito_base',
    );
    const hat = Item(id: 'hat_beret01', type: 'hat', assetKey: 'item_hat_beret01');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: DressedAnimal(
            animal: animal,
            equipped: {'hat': hat},
            size: 200,
            idle: false, // 테스트 결정성
          ),
        ),
      ),
    ));
    // 동물 베이스 + 모자 = Image 2장 이상 (앵커 합성됨)
    expect(find.byType(Image), findsWidgets);
    expect(tester.widgetList(find.byType(Image)).length, greaterThanOrEqualTo(2));
  });
}
