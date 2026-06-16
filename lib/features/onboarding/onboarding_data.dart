/// 온보딩 입력값 — 배정 확인 단계와 calc-saju 호출에 전달.
class BirthInputData {
  const BirthInputData({
    required this.birthDate,
    required this.calendarType,
    this.isLeapMonth = false,
    this.birthTime,
    this.gender,
  });

  final String birthDate; // YYYY-MM-DD (입력 달력 기준)
  final String calendarType; // 'solar' | 'lunar'
  final bool isLeapMonth;
  final String? birthTime; // 'HH:MM' or null(모름)
  final String? gender; // 'female' | 'male' | null

  bool get isLunar => calendarType == 'lunar';

  String get calendarLabel => isLunar ? '음력' : '양력';

  String get displayDate {
    final base = '$birthDate ($calendarLabel${isLeapMonth ? ' 윤달' : ''})';
    return birthTime == null ? base : '$base · $birthTime';
  }
}
