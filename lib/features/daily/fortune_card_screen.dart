import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/events.dart';
import '../../core/models/animal.dart';
import '../../core/models/item.dart';
import '../../data/providers.dart';
import '../share/lucky_share_card.dart';
import '../share/share_card.dart';
import 'daily_repository.dart';
import 'grade_style.dart';

/// 운세 카드 — 등급 + 카테고리 점수 + 메시지 + 보상.
/// 갬(보상 없음)도 카드 자체가 수집물 + 평온 응원으로 "빈손" 느낌 없게(②).
class FortuneCardScreen extends ConsumerStatefulWidget {
  const FortuneCardScreen({
    super.key,
    required this.animal,
    required this.result,
    required this.onClose,
  });

  final Animal animal;
  final OpenResult result;
  final VoidCallback onClose;

  @override
  ConsumerState<FortuneCardScreen> createState() => _FortuneCardScreenState();
}

class _FortuneCardScreenState extends ConsumerState<FortuneCardScreen> {
  final _shareKey = GlobalKey();
  Item? _reward;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.capture(AnalyticsEvents.packOpened, properties: {
      'grade': widget.result.grade,
      'animal_id': widget.animal.id,
    });
    final id = widget.result.rewardItemId;
    if (id != null) {
      ref.read(dailyRepositoryProvider).item(id).then((it) {
        if (mounted) setState(() => _reward = it);
      });
    }
  }

  Future<void> _shareLucky(GradeStyle g) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await captureAndShare(
        boundaryKey: _shareKey,
        text: '오늘 내 ${widget.animal.name}의 운세는 「${g.label}」 ${g.emoji} 너의 오늘은?',
      );
      await AnalyticsService.instance.capture(AnalyticsEvents.sharedLucky,
          properties: {'grade': g.grade});
      final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (uid != null) {
        await ref.read(supabaseClientProvider).from('share_events').insert(
          {'user_id': uid, 'type': 'lucky_card'},
        ).then((_) {}, onError: (_) {});
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GradeStyle.of(widget.result.grade);
    final text = Theme.of(context).textTheme;
    final r = widget.result;

    return Scaffold(
      backgroundColor: g.color.withValues(alpha: 0.08),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            Text('${g.emoji} ${g.label}',
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(g.headline, textAlign: TextAlign.center, style: text.titleSmall),
            const SizedBox(height: 20),

            // 메시지 카드 (= 수집물, ②: 갬도 이 카드가 선물)
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(r.message ?? '오늘도 너의 하루를 응원해 🐾',
                        style: text.bodyLarge, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    _Scores(scores: r.scores),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 보상 또는 평온 선물(②)
            _RewardBlock(reward: _reward, grade: g),
            const SizedBox(height: 8),

            // 스트릭 (D5: 끊겨도 협박 없음 — 사실만)
            Center(
              child: Text('🔥 연속 ${r.streakCurrent}일째 (최고 ${r.streakLongest}일)',
                  style: text.titleMedium),
            ),
            const SizedBox(height: 20),

            if (g.shareable) ...[
              // 캡처용 카드(오프스크린 아님 — 표시 겸용)
              Center(child: LuckyShareCard(animal: widget.animal, grade: g, boundaryKey: _shareKey)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _sharing ? null : () => _shareLucky(g),
                icon: _sharing
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share),
                label: const Text('오늘의 행운 자랑하기'),
              ),
              const SizedBox(height: 8),
            ],

            TextButton(onPressed: widget.onClose, child: const Text('닫기')),
          ],
        ),
      ),
    );
  }
}

class _Scores extends StatelessWidget {
  const _Scores({required this.scores});
  final Map<String, int> scores;

  static const _labels = {'wealth': '재물', 'love': '애정', 'health': '건강', 'work': '일'};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final key in const ['wealth', 'love', 'health', 'work'])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text(_labels[key]!)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (scores[key] ?? 0) / 100,
                      minHeight: 8,
                      backgroundColor: Colors.black12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${scores[key] ?? 0}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _RewardBlock extends StatelessWidget {
  const _RewardBlock({required this.reward, required this.grade});
  final Item? reward;
  final GradeStyle grade;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (reward == null) {
      // 갬 등 보상 아이템 없는 날 — 빈손 아님(②): 카드 수집 + 평온 응원
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: grade.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('🗂️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('오늘의 카드를 앨범에 담았어. 평온한 하루도 소중한 선물이야.',
                  style: text.bodyMedium),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: grade.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          reward!.thumbnail(size: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('보상 획득!', style: text.titleMedium),
                Text('${reward!.displayName} 을(를) 받았어',
                    style: text.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
