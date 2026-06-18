import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/animal.dart';
import '../../core/models/item.dart';
import '../../data/providers.dart';
import 'dressed_animal.dart';

/// 꾸미기 — 슬롯 3개(모자/손소품/배경). 미소유도 미리보기 가능, 저장(장착)은 소유만(🔒).
class DressupScreen extends ConsumerStatefulWidget {
  const DressupScreen({super.key, required this.animal});
  final Animal animal;

  @override
  ConsumerState<DressupScreen> createState() => _DressupScreenState();
}

const _slots = [('hat', '모자'), ('hand_r', '손소품'), ('bg', '배경')];

class _DressupScreenState extends ConsumerState<DressupScreen> {
  String _slot = 'hat';
  // 미리보기 오버레이 (slot → Item?). null = 벗김. 미초기화 슬롯은 equipped 사용.
  final Map<String, Item?> _preview = {};

  Map<String, Item?> _composeMap(Map<String, Item?> equipped) {
    final m = <String, Item?>{...equipped};
    for (final e in _preview.entries) {
      m[e.key] = e.value;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final itemsBySlot = ref.watch(itemsBySlotProvider);
    final inventory = ref.watch(inventoryProvider);
    final equippedItems = ref.watch(equippedItemsProvider);

    return itemsBySlot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('아이템 로드 실패: $e')),
      data: (slotItems) => inventory.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('인벤토리 로드 실패: $e')),
        data: (owned) => equippedItems.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('장착 로드 실패: $e')),
          data: (equipped) =>
              _body(slotItems, owned, _composeMap(equipped)),
        ),
      ),
    );
  }

  Widget _body(Map<String, List<Item>> slotItems, Set<String> owned,
      Map<String, Item?> composed) {
    final text = Theme.of(context).textTheme;
    final items = slotItems[_slot] ?? const <Item>[];
    final current = composed[_slot];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: DressedAnimal(animal: widget.animal, equipped: composed, size: 220),
        ),
        const SizedBox(height: 16),

        // 슬롯 선택
        Center(
          child: Wrap(
            spacing: 8,
            children: [
              for (final s in _slots)
                ChoiceChip(
                  label: Text(s.$2),
                  selected: _slot == s.$1,
                  onSelected: (_) => setState(() => _slot = s.$1),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 아이템 목록 (소유=장착 가능, 미소유=🔒 미리보기만)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 벗기
            _OptionTile(
              label: '벗기',
              selected: current == null,
              locked: false,
              child: const Icon(Icons.not_interested, size: 36),
              onTap: () => setState(() => _preview[_slot] = null),
            ),
            for (final it in items)
              _OptionTile(
                label: it.displayName,
                selected: current?.id == it.id,
                locked: !owned.contains(it.id),
                child: it.thumbnail(size: 64),
                onTap: () => setState(() => _preview[_slot] = it),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // 저장 (소유만 반영 — 미소유 미리보기는 저장 시 건너뜀)
        FilledButton.icon(
          onPressed: () => _save(composed, owned),
          icon: const Icon(Icons.check),
          label: const Text('이대로 저장'),
        ),
        const SizedBox(height: 8),
        Text('🔒 아이템은 봉투를 열어 모으면 장착할 수 있어',
            style: text.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Future<void> _save(Map<String, Item?> composed, Set<String> owned) async {
    final notifier = ref.read(equippedProvider.notifier);
    var skippedLocked = false;
    for (final s in _slots) {
      final slot = s.$1;
      if (!_preview.containsKey(slot)) continue; // 변경 안 함
      final item = _preview[slot];
      if (item == null) {
        await notifier.unequip(slot);
      } else if (owned.contains(item.id)) {
        await notifier.equip(slot, item.id);
      } else {
        skippedLocked = true; // 미소유 → 저장 건너뜀
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(skippedLocked ? '잠긴 아이템은 빼고 저장했어' : '저장했어!'),
    ));
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.locked,
    required this.child,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? scheme.primary : Colors.black12,
                  width: selected ? 3 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(child: child),
                  if (locked)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('🔒', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
