import 'package:flutter/material.dart';

/// 날씨 6등급 비주얼·카피 (§4.1, D8). 비/흐림도 "조심 + 위로" 프레임(D6).
class GradeStyle {
  const GradeStyle({
    required this.grade,
    required this.label,
    required this.emoji,
    required this.color,
    required this.headline,
    required this.shareable,
    required this.rank,
  });

  final String grade;
  final String label; // 무지개/쾌청/맑음/갬/흐림/비
  final String emoji;
  final Color color;
  final String headline; // 카드 상단 한 줄 톤
  final bool shareable; // 맑음 이상 = 행운 공유 카드 노출
  final int rank; // 높을수록 좋은 등급 (정렬용)

  static const _map = <String, GradeStyle>{
    'rainbow': GradeStyle(
      grade: 'rainbow', label: '무지개', emoji: '🌈', color: Color(0xFFB388FF),
      headline: '일 년에 몇 번 없는 최고의 날!', shareable: true, rank: 6),
    'radiant': GradeStyle(
      grade: 'radiant', label: '쾌청', emoji: '☀️', color: Color(0xFFFFB300),
      headline: '운이 활짝 열린 날', shareable: true, rank: 5),
    'sunny': GradeStyle(
      grade: 'sunny', label: '맑음', emoji: '🌤️', color: Color(0xFF4FC3F7),
      headline: '기분 좋은 행운의 날', shareable: true, rank: 4),
    'calm': GradeStyle(
      grade: 'calm', label: '갬', emoji: '⛅', color: Color(0xFF90A4AE),
      headline: '평온한 하루 — 마음 편히 쉬어가도 좋아', shareable: false, rank: 3),
    'cloudy': GradeStyle(
      grade: 'cloudy', label: '흐림', emoji: '☁️', color: Color(0xFF78909C),
      headline: '조금 흐려도 괜찮아, 작은 위로를 챙겼어', shareable: false, rank: 2),
    'rainy': GradeStyle(
      grade: 'rainy', label: '비', emoji: '🌧️', color: Color(0xFF5C6BC0),
      headline: '비 오는 날엔 우산을 챙겼어 ☂️', shareable: false, rank: 1),
  };

  static GradeStyle of(String grade) =>
      _map[grade] ?? _map['calm']!;
}
