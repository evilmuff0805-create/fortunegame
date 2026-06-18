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

  /// 장착 슬롯 (꾸미기). card 등은 장착 불가(null) — 앨범 수집물.
  String? get equipSlot => switch (type) {
        'hat' => 'hat',
        'charm' || 'hand' => 'hand_r', // 손소품
        'bg' => 'bg',
        'body' => 'body',
        _ => null,
      };

  /// 합성 레이어 비주얼 (부모가 크기 지정). 실제 아트 or 플레이스홀더 칩.
  Widget composeVisual() {
    if (hasArt) return Image.asset(assetPath, fit: BoxFit.contain);
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF0E6D2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8A6A48), width: 3),
        ),
        alignment: Alignment.center,
        child: Text(_emoji, style: const TextStyle(fontSize: 52)),
      ),
    );
  }

  /// 배경 슬롯 채움 (실제 아트 or 플레이스홀더 그라데이션).
  Widget bgFill() {
    if (hasArt) return Image.asset(assetPath, fit: BoxFit.cover);
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE0E6), Color(0xFFFFF3D6), Color(0xFFD6F5E3), Color(0xFFD6E8FF),
          ],
        ),
      ),
    );
  }

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
