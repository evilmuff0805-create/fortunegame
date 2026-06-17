import 'package:flutter/material.dart';

import '../../core/models/animal.dart';
import '../daily/grade_style.dart';
import '../onboarding/widgets/animal_placeholder.dart';

/// 공유 카드 ② "오늘의 행운" — 맑음 이상에서 노출. 캡처 대상 비주얼.
class LuckyShareCard extends StatelessWidget {
  const LuckyShareCard({
    super.key,
    required this.animal,
    required this.grade,
    required this.boundaryKey,
  });

  final Animal animal;
  final GradeStyle grade;
  final GlobalKey boundaryKey;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [grade.color.withValues(alpha: 0.45), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${grade.emoji} 오늘의 행운',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AnimalPlaceholder(animal: animal, size: 120),
            const SizedBox(height: 12),
            Text('${animal.name}의 오늘은 「${grade.label}」',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(grade.headline,
                style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('나도 내 동물의 운세 받기 🐾',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
