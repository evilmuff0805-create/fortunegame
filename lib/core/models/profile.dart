/// 사용자 프로필 (DB `users` 행의 클라이언트 뷰).
class Profile {
  const Profile({
    required this.animalId,
    required this.sajuPillars,
    required this.birthDate,
    required this.calendarType,
  });

  final String animalId; // 불변 (D1)
  final Map<String, dynamic> sajuPillars;
  final String birthDate;
  final String calendarType;

  String? get dayPillar => sajuPillars['day'] as String?;

  factory Profile.fromRow(Map<String, dynamic> row) {
    return Profile(
      animalId: row['animal_id'] as String,
      sajuPillars: Map<String, dynamic>.from(row['saju_pillars'] as Map),
      birthDate: row['birth_date'] as String,
      calendarType: row['calendar_type'] as String,
    );
  }
}
