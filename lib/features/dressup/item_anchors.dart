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

/// 모자 HAT 앵커(§3): x=0.50, 하단중앙 기준점. y = kHatBaseY + 동물별 겹침.
const double kHatAnchorX = 0.50;
const double kHatBaseY = 0.12;

/// 모자 겹침(머리에 얹히는 정도, 정규화 H). 기본=카피바라 검증값.
/// 동물별 오버라이드: 뿔·귀 등 머리 위 부착물 때문에 정수리(=bbox 상단)가 실제 머리보다
/// 위에 잡히는 동물은 더 많이 내려야 모자가 머리에 얹힌다.
const double kHatOverlapDefault = 0.05; // gito(카피바라) 등 부착물 작은 동물
const Map<String, double> kHatOverlapByAnimal = {
  'gapmok': 0.18, // 사슴: 뿔이 머리 위로 솟음 → 더 내려 머리에 얹고 뿔은 위·옆 노출
};
double hatOverlapFor(String animalId) =>
    kHatOverlapByAnimal[animalId] ?? kHatOverlapDefault;

/// 모자 너비(박스 비율). 동물별 오버라이드: 뿔 있는 동물은 작게 해야 뿔이 안 가려짐.
const double kHatWidthDefault = 0.44;
const Map<String, double> kHatWidthByAnimal = {
  'gapmok': 0.34, // 사슴: 작은 베레모라야 뿔이 양옆으로 노출(0.52는 뿔 덮음)
};
double hatWidthFor(String animalId) =>
    kHatWidthByAnimal[animalId] ?? kHatWidthDefault;

/// item_hat_beret01 캔버스 비율(512×384). 실제 아트 교체 시만 갱신.
const double kHatAspect = 384 / 512;

const slotAnchors = <String, SlotAnchor>{
  'hat': SlotAnchor(
    anchor: Offset(kHatAnchorX, kHatBaseY), // y·width는 DressedAnimal이 동물별로 보정
    refPoint: Alignment.bottomCenter,
    widthFrac: kHatWidthDefault,
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
