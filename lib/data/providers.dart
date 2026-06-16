import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/animal.dart';
import '../core/models/profile.dart';
import '../core/supabase_client.dart';
import 'onboarding_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseBootstrap.client,
);

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(supabaseClientProvider)),
);

/// 동물 카탈로그 (id → Animal). 인증된 사용자 누구나 읽기 가능(RLS).
final animalCatalogProvider = FutureProvider<Map<String, Animal>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final rows = await client
      .from('animals')
      .select('id, name, element, personality, population_pct');
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
