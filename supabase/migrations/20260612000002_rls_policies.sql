-- RLS: 사용자는 자기 행만 읽기/쓰기. animal_id는 INSERT만 가능, UPDATE 불가 (D1).

-- ── D1: animal_id 불변 트리거 (service role의 UPDATE까지 차단) ───────────

create function public.prevent_animal_change()
returns trigger
language plpgsql
as $$
begin
  if new.animal_id is distinct from old.animal_id then
    raise exception 'animal_id is immutable (D1: 동물은 절대 변경 불가)';
  end if;
  return new;
end;
$$;

create trigger users_animal_id_immutable
  before update on public.users
  for each row
  execute function public.prevent_animal_change();

-- ── RLS 활성화 (전 테이블) ───────────────────────────────────────────────

alter table public.animals        enable row level security;
alter table public.users          enable row level security;
alter table public.fortune_msgs   enable row level security;
alter table public.daily_fortunes enable row level security;
alter table public.items          enable row level security;
alter table public.inventory      enable row level security;
alter table public.equipped       enable row level security;
alter table public.streaks        enable row level security;
alter table public.purchases      enable row level security;
alter table public.share_events   enable row level security;

-- ── 읽기 전용 공용 마스터 (쓰기는 service role만 — 정책 없음 = 차단) ─────

create policy "animals: authenticated read"
  on public.animals for select to authenticated using (true);

create policy "items: authenticated read"
  on public.items for select to authenticated using (true);

create policy "fortune_msgs: authenticated read"
  on public.fortune_msgs for select to authenticated using (true);

-- ── users: 자기 행만. INSERT 시 animal_id 설정, UPDATE는 트리거가 변경 차단 ──

create policy "users: read own"
  on public.users for select to authenticated using (auth.uid() = id);

create policy "users: insert own"
  on public.users for insert to authenticated with check (auth.uid() = id);

create policy "users: update own"
  on public.users for update to authenticated
  using (auth.uid() = id) with check (auth.uid() = id);

-- ── daily_fortunes: 읽기 + 개봉(opened_at) 갱신만 클라이언트 허용 ─────────
-- INSERT는 서버(Edge Function, service role) 전용 — 클라이언트가 등급을 위조할 수 없게 (D10)

create policy "daily_fortunes: read own"
  on public.daily_fortunes for select to authenticated using (auth.uid() = user_id);

create policy "daily_fortunes: update own"
  on public.daily_fortunes for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── inventory: 자기 행 읽기/쓰기 (v1 보상 지급은 클라이언트 INSERT) ──────

create policy "inventory: read own"
  on public.inventory for select to authenticated using (auth.uid() = user_id);

create policy "inventory: insert own"
  on public.inventory for insert to authenticated with check (auth.uid() = user_id);

-- ── equipped: 자기 행 전체 CRUD (꾸미기 슬롯) ────────────────────────────

create policy "equipped: read own"
  on public.equipped for select to authenticated using (auth.uid() = user_id);

create policy "equipped: insert own"
  on public.equipped for insert to authenticated with check (auth.uid() = user_id);

create policy "equipped: update own"
  on public.equipped for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "equipped: delete own"
  on public.equipped for delete to authenticated using (auth.uid() = user_id);

-- ── streaks: 자기 행 읽기/쓰기 ───────────────────────────────────────────

create policy "streaks: read own"
  on public.streaks for select to authenticated using (auth.uid() = user_id);

create policy "streaks: insert own"
  on public.streaks for insert to authenticated with check (auth.uid() = user_id);

create policy "streaks: update own"
  on public.streaks for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ── purchases: 자기 행 읽기만 (INSERT는 v2 서버 검증 경로 — service role) ─

create policy "purchases: read own"
  on public.purchases for select to authenticated using (auth.uid() = user_id);

-- ── share_events: 자기 행 기록/읽기 ──────────────────────────────────────

create policy "share_events: read own"
  on public.share_events for select to authenticated using (auth.uid() = user_id);

create policy "share_events: insert own"
  on public.share_events for insert to authenticated with check (auth.uid() = user_id);
