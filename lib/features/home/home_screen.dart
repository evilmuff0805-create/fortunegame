import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/animal.dart';
import '../../core/models/profile.dart';
import '../../data/providers.dart';
import '../account/account_link_sheet.dart';
import '../daily/daily_open_screen.dart';
import '../dressup/dressed_animal.dart';

/// 홈 탭 (body 전용 — 셸이 Scaffold/AppBar 제공). 내 동물(장착 반영) + 오늘 봉투.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(animalCatalogProvider);
    final status = ref.watch(dailyStatusProvider);

    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('카탈로그 로드 실패: $e')),
      data: (map) {
        final animal = map[profile.animalId];
        if (animal == null) {
          return Center(child: Text('알 수 없는 동물: ${profile.animalId}'));
        }
        return status.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Offline(animal: animal, error: '$e'),
          data: (s) => _HomeBody(animal: animal, opened: s.opened, leak: s.leak),
        );
      },
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.animal, required this.opened, required this.leak});

  final Animal animal;
  final bool opened;
  final String leak;

  Future<void> _openFlow(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DailyOpenScreen(animal: animal, leak: leak),
    ));
    ref.invalidate(dailyStatusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final anon =
        ref.read(supabaseClientProvider).auth.currentUser?.isAnonymous ?? false;
    final equippedItems = ref.watch(equippedItemsProvider);
    // 미개봉이면 봉투 전달 포즈(있을 때)
    final showDeliver = !opened && animal.deliverAsset != null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        Center(
          child: equippedItems.maybeWhen(
            data: (eq) => DressedAnimal(
              animal: animal,
              equipped: eq,
              size: 200,
              useDeliverPose: showDeliver,
            ),
            orElse: () =>
                DressedAnimal(animal: animal, size: 200, useDeliverPose: showDeliver),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Text(animal.name, style: text.headlineSmall)),
        const SizedBox(height: 24),

        if (!opened)
          Card(
            color: leak == 'rainbow'
                ? const Color(0xFFF3E5F5)
                : leak == 'radiant'
                    ? const Color(0xFFFFF8E1)
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    leak == 'rainbow'
                        ? '봉투 틈으로 무지갯빛이…! 🌈'
                        : leak == 'radiant'
                            ? '봉투가 금빛으로 반짝여 ✨'
                            : '오늘의 봉투가 도착했어',
                    style: text.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openFlow(context, ref),
                    icon: const Icon(Icons.drafts),
                    label: const Text('봉투 열기'),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('오늘 봉투는 이미 열었어 🗂️', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text('내일 아침 새 봉투로 또 만나자', style: text.bodySmall),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _openFlow(context, ref),
                    child: const Text('오늘 운세 다시 보기'),
                  ),
                ],
              ),
            ),
          ),

        if (anon) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AccountLinkSheet(),
            ),
            icon: const Icon(Icons.lock_outline),
            label: const Text('계정 연결로 동물 지키기'),
          ),
        ],
      ],
    );
  }
}

class _Offline extends StatelessWidget {
  const _Offline({required this.animal, required this.error});
  final Animal animal;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DressedAnimal(animal: animal, size: 140, idle: false),
            const SizedBox(height: 16),
            Text('오늘 봉투를 불러오지 못했어\n$error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
