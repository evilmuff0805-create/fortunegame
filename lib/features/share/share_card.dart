import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/animal.dart';
import '../onboarding/widgets/animal_placeholder.dart';

/// 공유 카드 ① "넌 무슨 동물?" — 캡처 대상 비주얼.
/// 실제 아트 전까지 플레이스홀더. 흐름(렌더→캡처→공유)만 검증.
class AssignShareCard extends StatelessWidget {
  const AssignShareCard({super.key, required this.animal, required this.boundaryKey});

  final Animal animal;
  final GlobalKey boundaryKey;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 320,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              animal.placeholderColor.withValues(alpha: 0.35),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('나의 운세 동물은', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            AnimalPlaceholder(animal: animal, size: 140),
            const SizedBox(height: 20),
            Text(
              animal.name,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('${animal.element} · ${animal.personality}',
                style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Text('넌 무슨 동물일까? 🐾',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// 키로 지정된 RepaintBoundary를 PNG로 캡처 → 임시 파일 → share_plus 공유.
Future<void> captureAndShare({
  required GlobalKey boundaryKey,
  required String text,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) return;

  final image = await boundary.toImage(pixelRatio: 3);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) return;
  final pngBytes = bytes.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
  await File(path).writeAsBytes(pngBytes);

  await SharePlus.instance.share(
    ShareParams(text: text, files: [XFile(path)]),
  );
}
