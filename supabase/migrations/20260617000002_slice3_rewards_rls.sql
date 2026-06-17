-- Slice 3: 보상 아이템 시드 + 보상/스트릭 서버 권위화(RLS 잠금).

-- 등급별 보상 아이템 (결정 2). hat_beret01만 실제 아트, 나머지는 플레이스홀더.
insert into public.items (id, type, rarity, source, price, asset_key) values
  ('hat_beret01',      'hat',   'rare',    'reward', null, 'item_hat_beret01'),
  ('card_lucky01',     'card',  'common',  'reward', null, 'item_card_lucky01'),
  ('charm_comfort01',  'charm', 'common',  'reward', null, 'item_charm_comfort01'),
  ('charm_umbrella01', 'charm', 'common',  'reward', null, 'item_charm_umbrella01'),
  ('bg_rainbow01',     'bg',    'limited', 'reward', null, 'item_bg_rainbow01')
on conflict (id) do nothing;

-- 보상·스트릭은 서버(open-pack, service-role)만 기록 → 아이템 파밍·스트릭 조작 차단(결정 1).
-- read는 유지(클라이언트가 인벤토리·스트릭 표시).
drop policy if exists "inventory: insert own" on public.inventory;
drop policy if exists "streaks: insert own" on public.streaks;
drop policy if exists "streaks: update own" on public.streaks;
