/// 분석 이벤트 상수 (tasks/todo.md Slice 0).
///
/// v1 검증 지표 (점신PLAN.md §9):
/// - D1/D7/D30 리텐션, DAU 중 당일 개봉률, 공유율
abstract final class AnalyticsEvents {
  /// 온보딩 완료 = 생년월일 입력 → 동물 배정까지 마침
  static const onboardingComplete = 'onboarding_complete';

  /// 오늘의 운세 카드팩 개봉 (당일 개봉률의 분자)
  static const packOpened = 'pack_opened';

  /// 공유 카드 ① "넌 무슨 동물?" 공유
  static const sharedAssign = 'shared_assign';

  /// 공유 카드 ② "오늘의 행운" 공유
  static const sharedLucky = 'shared_lucky';
}
