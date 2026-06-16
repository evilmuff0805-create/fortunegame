import 'package:flutter/material.dart';

import '../../../core/models/animal.dart';

/// 동물 플레이스홀더 — 실제 아트(카피바라 파일럿) 전까지 흐름 검증용.
/// 골격가이드 §2 2등신 라운드 실루엣을 단순 도형으로 흉내. 아트 완성 시 교체.
class AnimalPlaceholder extends StatelessWidget {
  const AnimalPlaceholder({super.key, required this.animal, this.size = 160});

  final Animal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: animal.placeholderColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: animal.placeholderColor.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        animal.placeholderEmoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
