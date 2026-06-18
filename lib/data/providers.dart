import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/animal.dart';
import '../core/models/item.dart';
import '../core/models/profile.dart';
import '../core/supabase_client.dart';
import '../features/daily/daily_repository.dart';
import 'onboarding_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseBootstrap.client,
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(supabaseClientProvider)),
);

final dailyRepositoryProvider = Provider<DailyRepository>(
  (ref) => DailyRepository(ref.watch(supabaseClientProvider)),
);

/// 오늘 봉투 상태 (미개봉/개봉 + 누설 티어). 개봉 후 invalidate로 새로고침.
final dailyStatusProvider = FutureProvider<DailyStatus>(
  (ref) => ref.watch(dailyRepositoryProvider).status(),
);

/// 동물 카탈로그 (id → Animal). 인증된 사용자 누구나 읽기 가능(RLS).
final animalCatalogProvider = FutureProvider<Map<String, Animal>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('animals')
      .select('id, name, element, personality, population_pct, asset_key');
  final map = <String, Animal>{};
  for (final r in rows) {
    final a = Animal.fromRow(r);
    map[a.id] = a;
  }
  return map;
});

/// 본인 프로필. null = 온보딩 필요. 라우팅 게이트.
class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() => _load();

  Future<Profile?> _load() async {
    final uid = SupabaseBootstrap.currentUserId;
    if (uid == null) return null;
    final client = ref.read(supabaseClientProvider);
    final row = await client
        .from('users')
        .select('animal_id, saju_pillars, birth_date, calendar_type')
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Profile.fromRow(row);
  }

  /// 배정 완료/로그인 후 새로고침.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

// ── 꾸미기(Slice 4) ────────────────────────────────────────────────────────

/// 전체 아이템 (id → Item).
final allItemsProvider = FutureProvider<Map<String, Item>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.from('items').select('id, type, asset_key');
  return {for (final r in rows) r['id'] as String: Item.fromRow(r)};
});

/// 장착 슬롯별 전체 아이템 목록 (꾸미기 UI).
final itemsBySlotProvider = FutureProvider<Map<String, List<Item>>>((ref) async {
  final all = await ref.watch(allItemsProvider.future);
  final map = <String, List<Item>>{};
  for (final it in all.values) {
    final s = it.equipSlot;
    if (s != null) (map[s] ??= []).add(it);
  }
  return map;
});

/// 소유한 아이템 id 집합.
final inventoryProvider = FutureProvider<Set<String>>((ref) async {
  final uid = SupabaseBootstrap.currentUserId;
  if (uid == null) return {};
  final client = ref.watch(supabaseClientProvider);
  final rows = await client.from('inventory').select('item_id').eq('user_id', uid);
  return {for (final r in rows) r['item_id'] as String};
});

/// 현재 장착 (slot → item_id). 꾸미기에서 변경, 홈이 watch해서 반영.
class EquippedNotifier extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() => _load();

  Future<Map<String, String>> _load() async {
    final uid = SupabaseBootstrap.currentUserId;
    if (uid == null) return {};
    final client = ref.read(supabaseClientProvider);
    final rows = await client.from('equipped').select('slot, item_id').eq('user_id', uid);
    return {for (final r in rows) r['slot'] as String: r['item_id'] as String};
  }

  Future<void> equip(String slot, String itemId) async {
    final uid = SupabaseBootstrap.currentUserId;
    if (uid == null) return;
    final client = ref.read(supabaseClientProvider);
    await client.from('equipped').upsert(
      {'user_id': uid, 'slot': slot, 'item_id': itemId},
      onConflict: 'user_id,slot',
    );
    state = AsyncData({...(state.value ?? <String, String>{}), slot: itemId});
  }

  Future<void> unequip(String slot) async {
    final uid = SupabaseBootstrap.currentUserId;
    if (uid == null) return;
    final client = ref.read(supabaseClientProvider);
    await client.from('equipped').delete().eq('user_id', uid).eq('slot', slot);
    final next = {...(state.value ?? <String, String>{})}..remove(slot);
    state = AsyncData(next);
  }
}

final equippedProvider =
    AsyncNotifierProvider<EquippedNotifier, Map<String, String>>(
        EquippedNotifier.new);

/// 장착 슬롯 → Item (홈 합성 렌더용).
final equippedItemsProvider = FutureProvider<Map<String, Item?>>((ref) async {
  final equipped = await ref.watch(equippedProvider.future);
  final all = await ref.watch(allItemsProvider.future);
  return {for (final e in equipped.entries) e.key: all[e.value]};
});
