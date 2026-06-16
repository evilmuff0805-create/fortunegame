import 'package:flutter/material.dart';

import '../../../core/models/animal.dart';
import '../widgets/animal_placeholder.dart';

/// 배정 연출 v1 (커스텀, 플레이스홀더) — 봉투가 열리며 동물이 등장.
/// 2.4초 + 화면 탭으로 스킵. 실제 아트/Rive 전까지 "흐름만" 검증.
class RevealStep extends StatefulWidget {
  const RevealStep({super.key, required this.animal, required this.onDone});

  final Animal animal;
  final VoidCallback onDone;

  @override
  State<RevealStep> createState() => _RevealStepState();
}

class _RevealStepState extends State<RevealStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() => _c.animateTo(1, duration: const Duration(milliseconds: 250));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // 봉투는 초반에 흔들리다 사라지고, 동물은 후반에 커지며 등장.
    final envelope = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    final animal = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    );
    final label = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
    );

    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final showAnimal = _c.value >= 0.5;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  showAnimal ? '두근두근… 너의 동물은!' : '봉투를 여는 중…',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 200,
                  child: Center(
                    child: showAnimal
                        ? Transform.scale(
                            scale: animal.value.clamp(0.0, 1.2),
                            child: AnimalPlaceholder(animal: widget.animal),
                          )
                        : Opacity(
                            opacity: (1 - envelope.value).clamp(0.0, 1.0),
                            child: Transform.rotate(
                              angle: (envelope.value * 6) % 0.4 - 0.2,
                              child: const Icon(Icons.mail, size: 120),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Opacity(
                  opacity: label.value,
                  child: Text(
                    widget.animal.name,
                    style: text.displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                if (_c.isCompleted)
                  FilledButton(
                    onPressed: widget.onDone,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('만나러 가기'),
                    ),
                  )
                else
                  Text('탭하면 바로 보기', style: text.bodySmall),
              ],
            ),
          );
        },
      ),
    );
  }
}
