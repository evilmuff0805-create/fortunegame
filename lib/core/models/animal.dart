import 'package:flutter/material.dart';

/// 동물 메타데이터 (DB `animals` 행). §12 일간→동물 매핑.
class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.element,
    required this.personality,
    required this.populationPct,
  });

  final String id;
  final String name; // 사슴, 토끼 …
  final String element; // 오행 서사 (큰 나무 등)
  final String personality;
  final double populationPct;

  factory Animal.fromRow(Map<String, dynamic> row) {
    return Animal(
      id: row['id'] as String,
      name: row['name'] as String,
      element: row['element'] as String,
      personality: row['personality'] as String,
      populationPct: (row['population_pct'] as num).toDouble(),
    );
  }

  /// 플레이스홀더 베이스 색 (실제 아트 전까지). 골격가이드 §6 파스텔 톤.
  Color get placeholderColor => _baseColors[id] ?? const Color(0xFFE8C9A0);

  /// 플레이스홀더 표정 이모지 (실제 아트 전까지).
  String get placeholderEmoji => _emojis[id] ?? '🐾';
}

const _baseColors = <String, Color>{
  'gapmok': Color(0xFFD7B89C), // 사슴
  'eulmok': Color(0xFFF2C6D0), // 토끼
  'byeonghwa': Color(0xFFF2D49B), // 사자
  'jeonghwa': Color(0xFFF0B48A), // 여우
  'muto': Color(0xFFC8A98A), // 곰
  'gito': Color(0xFFE8C9A0), // 카피바라
  'gyeonggeum': Color(0xFFF2B96B), // 호랑이
  'singeum': Color(0xFFD8C7E8), // 고양이
  'imsu': Color(0xFFA9CCE3), // 고래
  'gyesu': Color(0xFFA9D7C9), // 수달
};

const _emojis = <String, String>{
  'gapmok': '🦌',
  'eulmok': '🐰',
  'byeonghwa': '🦁',
  'jeonghwa': '🦊',
  'muto': '🐻',
  'gito': '🦫',
  'gyeonggeum': '🐯',
  'singeum': '🐱',
  'imsu': '🐳',
  'gyesu': '🦦',
};
