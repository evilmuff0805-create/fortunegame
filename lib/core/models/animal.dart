import 'package:flutter/material.dart';

/// 동물 메타데이터 (DB `animals` 행). §12 일간→동물 매핑.
class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.element,
    required this.personality,
    required this.populationPct,
    required this.assetKey,
  });

  final String id;
  final String name; // 사슴, 토끼 …
  final String element; // 오행 서사 (큰 나무 등)
  final String personality;
  final double populationPct;
  final String assetKey; // §9 기본 컷 파일 stem (예: animal_gito_base)

  factory Animal.fromRow(Map<String, dynamic> row) {
    return Animal(
      id: row['id'] as String,
      name: row['name'] as String,
      element: row['element'] as String,
      personality: row['personality'] as String,
      populationPct: (row['population_pct'] as num).toDouble(),
      assetKey: row['asset_key'] as String,
    );
  }

  /// 실제 아트가 번들된 동물(카피바라 파일럿). 9종 양산 시 여기에 추가.
  static const _withArt = {'gito'};
  bool get hasArt => _withArt.contains(id);

  /// 기본 컷 에셋 경로 (hasArt일 때만 유효).
  String get baseAsset => 'assets/animals/$assetKey.png';

  /// 봉투 전달 포즈 (hasArt일 때만; gito = animal_gito_deliver).
  String? get deliverAsset => hasArt ? 'assets/animals/animal_${id}_deliver.png' : null;

  /// 플레이스홀더 베이스 색 (아트 없는 9종). 골격가이드 §6 파스텔 톤.
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
