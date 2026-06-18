import 'package:flutter/material.dart';

/// 골격가이드 §3 앵커 좌표 (전 동물 공통, 절대 불변). 전부 정규화(박스 비율) — 하드코딩 픽셀 금지.
/// 아이템은 표준 골격 1종 기준 제작 → 앵커 스냅으로 전 동물 자동 공용.
class SlotAnchor {
  const SlotAnchor({
    required this.anchor,
    required this.refPoint,
    required this.widthFrac,
    required this.aspect, // 아이템 높이/너비 (실제 아트 기준; 플레이스홀더는 1.0)
  });

  final Offset anchor; // 박스 내 정규화 위치 (0~1)
  final Alignment refPoint; // 아이템 기준점 (하단중앙/중앙 등)
  final double widthFrac; // 아이템 너비 = 박스너비 × widthFrac
  final double aspect;
}

/// 카피바라 파일럿에서 검증한 모자 겹침: HAT 앵커(0.50,0.12)에서 머리 쪽으로 살짝 내려 자연스럽게 안착.
/// 기기에서 미세조정 가능한 상수 (정규화 H 비율).
const double kHatOverlapH = 0.05;

/// item_hat_beret01 캔버스 비율(512×384). 실제 아트 교체 시만 갱신.
const double kHatAspect = 384 / 512;

const slotAnchors = <String, SlotAnchor>{
  'hat': SlotAnchor(
    anchor: Offset(0.50, 0.12 + kHatOverlapH),
    refPoint: Alignment.bottomCenter,
    widthFrac: 0.52,
    aspect: kHatAspect,
  ),
  'hand_r': SlotAnchor(
    anchor: Offset(0.78, 0.55),
    refPoint: Alignment.center,
    widthFrac: 0.26,
    aspect: 1.0,
  ),
  // bg는 풀캔버스 — 앵커 합성이 아니라 박스 전체 채움(별도 처리)
};

/// 동물 미세 idle 애니메이션 강도 (살아있나 싶을 만큼만 — 100일째 배려).
/// 폰에서 보고 조정: 과하면 줄이고, 안 보이면 키운다.
class IdleAnim {
  const IdleAnim._();
  static const bool enabled = true;
  static const Duration period = Duration(milliseconds: 2800);
  static const double bobFracH = 0.010; // 박스 높이의 1.0% 수직 호흡
  static const double scaleAmplitude = 0.008; // ±0.8% 스케일
}
