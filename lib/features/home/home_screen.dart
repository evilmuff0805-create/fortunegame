import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/profile.dart';
import '../../data/providers.dart';
import '../account/account_link_sheet.dart';
import '../onboarding/widgets/animal_placeholder.dart';

/// 최소 홈 — 내 동물 표시. 진짜 데일리 루프(봉투 찢기·운세)는 Slice 3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(animalCatalogProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('내 동물')),
      body: Center(
        child: catalog.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('카탈로그 로드 실패: $e'),
          data: (map) {
            final animal = map[profile.animalId];
            if (animal == null) {
              return Text('알 수 없는 동물: ${profile.animalId}');
            }
            final anon = ref.read(supabaseClientProvider).auth.currentUser
                    ?.isAnonymous ??
                false;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimalPlaceholder(animal: animal, size: 180),
                  const SizedBox(height: 24),
                  Text(animal.name, style: text.headlineMedium),
                  const SizedBox(height: 4),
                  Text('${animal.element} · ${animal.personality}',
                      style: text.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        '오늘의 운세 봉투는 곧 만나요 🌤️\n(데일리 루프 = 다음 업데이트)',
                        style: text.bodyMedium,
                        textAlign: TextAlign.center,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
