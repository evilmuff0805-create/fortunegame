import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/events.dart';
import '../../../core/models/animal.dart';
import '../../../data/providers.dart';
import '../../account/account_link_sheet.dart';
import '../../share/share_card.dart';

/// 동물 소개 — 서사 + "전체의 N%" 동질감 + 공유/계정연결/시작.
class AnimalIntroScreen extends ConsumerStatefulWidget {
  const AnimalIntroScreen({super.key, required this.animal, required this.onStart});

  final Animal animal;
  final VoidCallback onStart;

  @override
  ConsumerState<AnimalIntroScreen> createState() => _AnimalIntroScreenState();
}

class _AnimalIntroScreenState extends ConsumerState<AnimalIntroScreen> {
  final _shareKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await captureAndShare(
        boundaryKey: _shareKey,
        text: '나의 운세 동물은 ${widget.animal.name}! 너는 무슨 동물일까? 🐾',
      );
      await AnalyticsService.instance.capture(AnalyticsEvents.sharedAssign,
          properties: {'animal_id': widget.animal.id});
      // 바이럴 측정 (share_events) — 실패해도 공유 흐름은 막지 않음
      final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (uid != null) {
        await ref.read(supabaseClientProvider).from('share_events').insert(
          {'user_id': uid, 'type': 'assign'},
        ).then((_) {}, onError: (_) {});
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _linkAccount() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AccountLinkSheet(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계정이 연결됐어요. 이제 동물이 안전해요!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.animal;
    final text = Theme.of(context).textTheme;
    final pct = a.populationPct % 1 == 0
        ? a.populationPct.toStringAsFixed(0)
        : a.populationPct.toStringAsFixed(1);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Text('너의 동물을 만났어!',
                style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // 공유 카드 = 히어로 비주얼(겸 캡처 대상)
            Center(child: AssignShareCard(animal: a, boundaryKey: _shareKey)),
            const SizedBox(height: 24),

            // 동질감 통계
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: a.placeholderColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text('전체의 약 $pct%가 ${a.name}예요',
                      style: text.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('${a.element}의 기운 — ${a.personality}',
                      style: text.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.ios_share),
              label: const Text('친구에게 자랑하기'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _linkAccount,
              icon: const Icon(Icons.lock_outline),
              label: const Text('계정 연결로 동물 지키기'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onStart,
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
