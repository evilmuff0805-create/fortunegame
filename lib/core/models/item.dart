import 'package:flutter/material.dart';

/// 보상 아이템 (DB items 행의 클라이언트 뷰). v1은 hat_beret01만 실제 아트.
class Item {
  const Item({required this.id, required this.type, required this.assetKey});

  final String id;
  final String type; // hat/hand/body/bg/charm/card
  final String assetKey; // item_..._...

  factory Item.fromRow(Map<String, dynamic> row) => Item(
        id: row['id'] as String,
        type: row['type'] as String,
        assetKey: row['asset_key'] as String,
      );

  static const _withArt = {'hat_beret01'};
  bool get hasArt => _withArt.contains(id);
  String get assetPath => 'assets/items/$assetKey.png';

  /// 표시 이름 (아트 전 플레이스홀더용).
  String get displayName => switch (id) {
        'hat_beret01' => '베레모',
        'card_lucky01' => '행운 카드',
        'charm_comfort01' => '위로 인형',
        'charm_umbrella01' => '우산 부적',
        'bg_rainbow01' => '무지개 배경',
        _ => id,
      };

  String get _emoji => switch (type) {
        'hat' => '🎩',
        'card' => '🍀',
        'charm' => id == 'charm_umbrella01' ? '☂️' : '🧸',
        'bg' => '🌈',
        _ => '🎁',
      };

  /// 인벤토리/보상 표시용 작은 위젯.
  Widget thumbnail({double size = 96}) {
    if (hasArt) {
      return Image.asset(assetPath, width: size, height: size, fit: BoxFit.contain);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6D2),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(_emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
