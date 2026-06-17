import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 봉투 찢기 — "보는 애니메이션"이 아니라 손가락 드래그로 직접 찢는다(§11-2, TCG Pocket 문법).
/// 드래그 진행도 = 찢김 정도 실시간 연동. 단계별 햅틱. 탭 = 바로 열기(스킵, 100일째 배려 §11-6).
/// leak: 'rainbow'/'radiant'면 개봉 전 봉투 틈으로 빛 누설(§11-3 기대 스파이크).
class EnvelopeTear extends StatefulWidget {
  const EnvelopeTear({
    super.key,
    required this.leak,
    required this.onOpened,
    this.deliverImage, // 동물이 봉투 건네는 포즈 (gito: animal_gito_deliver)
  });

  final String leak;
  final VoidCallback onOpened;
  final String? deliverImage;

  @override
  State<EnvelopeTear> createState() => _EnvelopeTearState();
}

class _EnvelopeTearState extends State<EnvelopeTear> {
  double _progress = 0; // 0=닫힘 … 1=완전히 찢김
  int _hapticStage = 0;
  bool _done = false;
  static const _tearWidth = 260.0; // 이 거리만큼 드래그하면 완전 개봉

  void _addProgress(double dxAbs) {
    if (_done) return;
    final next = (_progress + dxAbs / _tearWidth).clamp(0.0, 1.0);
    // 단계별 햅틱 (약→중→강)
    final stage = next >= 1.0 ? 3 : next >= 0.6 ? 2 : next >= 0.25 ? 1 : 0;
    if (stage > _hapticStage) {
      _hapticStage = stage;
      switch (stage) {
        case 1:
          HapticFeedback.lightImpact();
        case 2:
          HapticFeedback.mediumImpact();
        case 3:
          HapticFeedback.heavyImpact();
      }
    }
    setState(() => _progress = next);
    if (next >= 1.0) _complete();
  }

  void _complete() {
    if (_done) return;
    _done = true;
    HapticFeedback.selectionClick();
    // 살짝 여운 후 콜백
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) widget.onOpened();
    });
  }

  /// 탭 = 바로 열기 (스킵). 진행도를 끝까지 채우며 완료.
  void _skip() => setState(() {
        _progress = 1;
        _complete();
      });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: _skip,
      onPanUpdate: (d) => _addProgress(d.delta.distance),
      onPanEnd: (_) {
        // 절반 이상 찢었으면 자동 완료, 아니면 그대로 둠(되돌아가지 않음 = 진행감 유지)
        if (_progress >= 0.6 && !_done) _complete();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.deliverImage != null)
            Image.asset(widget.deliverImage!, height: 150, fit: BoxFit.contain),
          const SizedBox(height: 12),
          Text(_progress <= 0 ? '봉투를 쭉 찢어봐' : '조금만 더…', style: text.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            width: 300,
            height: 200,
            child: CustomPaint(
              painter: _EnvelopePainter(progress: _progress, leak: widget.leak),
            ),
          ),
          const SizedBox(height: 16),
          Text('톡 누르면 바로 열려요', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  _EnvelopePainter({required this.progress, required this.leak});
  final double progress;
  final String leak;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 20, w - 20, h - 40), const Radius.circular(16));

    // 누설 빛 (개봉 전 틈) — rainbow/radiant일 때 봉투 안쪽에서 새어 나옴
    if (leak != 'none') {
      final glow = Paint()
        ..shader = (leak == 'rainbow'
                ? const LinearGradient(colors: [
                    Color(0xFFFF8A80), Color(0xFFFFD180), Color(0xFFFFFF8D),
                    Color(0xFFB9F6CA), Color(0xFF80D8FF), Color(0xFFB388FF),
                  ])
                : const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFB300)]))
            .createShader(Rect.fromLTWH(10, 20, w - 20, h - 40))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRRect(r, glow);
    }

    // 봉투 본체
    final body = Paint()..color = const Color(0xFFEFE2C8);
    canvas.drawRRect(r, body);

    // 찢긴 윗부분: progress만큼 위쪽 덮개가 들려 사라지고 톱니 틈이 벌어짐
    final coverH = (h - 40) * (1 - progress);
    if (coverH > 0) {
      final cover = Paint()..color = const Color(0xFFD9C39A);
      final path = Path()..moveTo(10, 20);
      path.lineTo(w - 10, 20);
      path.lineTo(w - 10, 20 + coverH);
      // 톱니(찢긴) 아랫변
      const teeth = 12;
      for (int i = teeth; i >= 0; i--) {
        final x = 10 + (w - 20) * (i / teeth);
        final dy = (i.isEven ? 0.0 : 10.0);
        path.lineTo(x, 20 + coverH - dy);
      }
      path.close();
      canvas.drawPath(path, cover);
    }

    // 봉투 외곽선
    canvas.drawRRect(
        r, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF8A6A48));
    // 진행 게이지
    final track = Paint()..color = const Color(0x33000000);
    final fill = Paint()..color = const Color(0xFF8A6A48);
    final gy = h - 14;
    canvas.drawLine(Offset(20, gy), Offset(w - 20, gy), track..strokeWidth = 4);
    canvas.drawLine(
        Offset(20, gy), Offset(20 + (w - 40) * progress, gy), fill..strokeWidth = 4);
    // 진행 핸들 점
    canvas.drawCircle(Offset(20 + (w - 40) * progress, gy), 8,
        Paint()..color = const Color(0xFF8A6A48));
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) =>
      old.progress != progress || old.leak != leak;
}
