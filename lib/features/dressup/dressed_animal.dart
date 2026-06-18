import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/animal.dart';
import '../../core/models/item.dart';
import '../onboarding/widgets/animal_placeholder.dart';
import 'item_anchors.dart';

/// 동물 + 장착 아이템 합성 렌더 (골격가이드 §3 정규화 앵커). 코드 미세 idle 애니메이션.
/// equipped: slot('hat'/'hand_r'/'bg') → Item. null이면 미장착.
class DressedAnimal extends StatefulWidget {
  const DressedAnimal({
    super.key,
    required this.animal,
    this.equipped = const {},
    this.size = 200,
    this.useDeliverPose = false,
    this.idle = IdleAnim.enabled,
  });

  final Animal animal;
  final Map<String, Item?> equipped;
  final double size;
  final bool useDeliverPose;
  final bool idle;

  @override
  State<DressedAnimal> createState() => _DressedAnimalState();
}

class _DressedAnimalState extends State<DressedAnimal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: IdleAnim.period);
    if (widget.idle) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final stack = _buildStack(s);
    if (!widget.idle) return SizedBox(width: s, height: s, child: stack);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = math.sin(_c.value * 2 * math.pi);
        final dy = t * IdleAnim.bobFracH * s; // 미세 수직 호흡
        final scale = 1 + t * IdleAnim.scaleAmplitude;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: SizedBox(width: s, height: s, child: stack),
    );
  }

  Widget _buildStack(double s) {
    final hat = widget.equipped['hat'];
    final hand = widget.equipped['hand_r'];
    final bg = widget.equipped['bg'];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 배경 (풀캔버스)
        if (bg != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: bg.bgFill(),
            ),
          ),
        // 동물 본체
        Positioned.fill(
          child: AnimalPlaceholder(
            animal: widget.animal,
            size: s,
            deliver: widget.useDeliverPose,
          ),
        ),
        // 모자 (§3 HAT 앵커, 하단중앙 기준)
        if (hat != null) _anchored(s, 'hat', hat.composeVisual()),
        // 손소품 (§3 HAND_R 앵커, 중앙 기준)
        if (hand != null) _anchored(s, 'hand_r', hand.composeVisual()),
      ],
    );
  }

  /// 정규화 앵커에 아이템 스냅 (픽셀 하드코딩 없음).
  Widget _anchored(double s, String slot, Widget child) {
    final a = slotAnchors[slot]!;
    final w = a.widthFrac * s;
    final h = w * a.aspect;
    final ax = a.anchor.dx * s;
    // 모자는 동물별 겹침(뿔·귀 보정)을 base y에 더해 앵커 산출.
    final anchorY = slot == 'hat'
        ? (kHatBaseY + hatOverlapFor(widget.animal.id))
        : a.anchor.dy;
    final ay = anchorY * s;
    // 기준점(refPoint)을 앵커에 맞춰 좌상단 좌표 산출
    final left = ax - w * ((a.refPoint.x + 1) / 2);
    final top = ay - h * ((a.refPoint.y + 1) / 2);
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: child,
    );
  }
}
