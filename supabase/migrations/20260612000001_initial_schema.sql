-- 점신PLAN.md §7 데이터 모델 — 전체 비전 기준 (v1 미사용 테이블 포함)
-- 원칙: 코드는 싸게 고치지만 스키마와 사용자 약속은 비싸게 고친다.

-- ── enums ────────────────────────────────────────────────────────────────

create type public.calendar_type as enum ('solar', 'lunar');

-- D8: 날씨 메타포 6등급 (무지개/쾌청/맑음/갬/흐림/비)
create type public.fortune_grade as enum ('rainbow', 'radiant', 'sunny', 'calm', 'cloudy', 'rainy');

-- §7 items.type: 모자/소품/배경/부적/카드 (+ 골격가이드 BODY 슬롯용 body)
create type public.item_type as enum ('hat', 'hand', 'body', 'bg', 'charm', 'card');

-- 골격가이드 §3 앵커 슬롯
create type public.equip_slot as enum ('hat', 'face', 'hand_r', 'hand_l', 'body', 'bg');

create type public.item_source as enum ('reward', 'purchase', 'restore');

-- 공유 카드 2종: 배정("넌 무슨 동물?") / 행운 카드("오늘의 행운")
create type public.share_type as enum ('assign', 'lucky_card');

-- ── animals (정적 마스터, §12 일간→동물 매핑) ────────────────────────────

create table public.animals (
  id             text primary key,          -- 일간 id (골격가이드 §9: gapmok…gyesu, 에셋 파일명과 일치)
  name           text not null,             -- 동물 이름 (한국어)
  element        text not null,             -- 오행 기운 서사 (갑목=큰 나무 등)
  personality    text not null,             -- 성격 키워드
  population_pct numeric(4,1) not null,     -- "전체의 N%" 통계 동질감 문구용 (각 ~10%)
  asset_key      text not null              -- animal_{일간}_{base|deliver}.png
);

comment on table public.animals is '일간(십간) 10종 동물 마스터 (D7). 쓰기는 service role만.';

-- ── users ────────────────────────────────────────────────────────────────

create table public.users (
  id            uuid primary key references auth.users (id) on delete cascade,
  created_at    timestamptz not null default now(),
  auth_provider text,
  birth_date    date not null,
  birth_time    time,                              -- 선택 입력 (상세 운세용, 온보딩 마찰↓)
  calendar_type public.calendar_type not null default 'solar',
  gender        text,
  saju_pillars  jsonb not null,
  animal_id     text not null references public.animals (id),
  settings      jsonb not null default '{}'::jsonb
);

comment on table public.users is '온보딩 완료 시 생성. animal_id는 불변(D1) — UPDATE 경로 없음 (트리거로 강제).';
comment on column public.users.animal_id is 'D1: 절대 변경 불가. prevent_animal_change 트리거가 service role 포함 모든 UPDATE를 차단.';

-- ── fortune_msgs (일일 배치 캐싱: 동물 10 × 등급 6 = 60개/일) ────────────

create table public.fortune_msgs (
  id         uuid primary key default gen_random_uuid(),
  date       date not null,                        -- KST 기준 날짜
  animal_id  text not null references public.animals (id),
  grade      public.fortune_grade not null,
  body       text not null,
  created_at timestamptz not null default now(),
  unique (date, animal_id, grade)
);

comment on table public.fortune_msgs is 'D10: 매일 자정 배치가 (동물×등급) 60개 생성·캐싱. 사용자별 생성 금지 (원가 고정).';

-- ── daily_fortunes (D4: v1 첫날부터 기록) ────────────────────────────────

create table public.daily_fortunes (
  user_id         uuid not null references public.users (id) on delete cascade,
  date            date not null,                   -- KST 기준 날짜 (날짜 경계 = KST 자정, D10)
  grade           public.fortune_grade not null,
  category_scores jsonb not null,                  -- 재물/애정/건강/일 (같은 해시에서 파생)
  message_id      uuid references public.fortune_msgs (id),
  opened_at       timestamptz,                     -- null = 미개봉 = 앨범 빈 슬롯
  reward_item_id  text,                            -- FK는 items 정의 후 추가
  primary key (user_id, date)
);

comment on column public.daily_fortunes.date is 'KST(Asia/Seoul) 기준 날짜. 클라이언트·서버 모두 KST 자정 경계 사용 (D10).';
comment on column public.daily_fortunes.opened_at is 'null = 미개봉 = 앨범 빈 슬롯 (손실 회피 장치).';

-- ── items (마스터) ───────────────────────────────────────────────────────

create table public.items (
  id        text primary key,                      -- 에셋 파일명과 일치 (예: hat_umbrella01)
  type      public.item_type not null,
  rarity    text not null default 'common',        -- common/rare/limited (무지개 비매품 = limited)
  season    text,
  source    public.item_source not null default 'reward',
  price     integer,                               -- KRW, v2 단품 판매용. null = 비매품
  asset_key text not null                          -- item_{hat|hand|body|bg}_{id}.png
);

comment on table public.items is '아이템 마스터. D3: 유료 랜덤 없음 — 랜덤은 운세가 결정, 돈은 고르는 데만(v2).';

alter table public.daily_fortunes
  add constraint daily_fortunes_reward_item_id_fkey
  foreign key (reward_item_id) references public.items (id);

-- ── inventory / equipped ─────────────────────────────────────────────────

create table public.inventory (
  user_id     uuid not null references public.users (id) on delete cascade,
  item_id     text not null references public.items (id),
  acquired_at timestamptz not null default now(),
  source      public.item_source not null default 'reward',
  primary key (user_id, item_id)
);

create table public.equipped (
  user_id uuid not null references public.users (id) on delete cascade,
  slot    public.equip_slot not null,
  item_id text not null references public.items (id),
  primary key (user_id, slot)
);

-- ── streaks ──────────────────────────────────────────────────────────────

create table public.streaks (
  user_id          uuid primary key references public.users (id) on delete cascade,
  current          integer not null default 0,
  longest          integer not null default 0,
  last_opened_date date                            -- KST 기준 날짜
);

-- ── purchases (v2 — 테이블은 v1부터 존재, 결제 코드는 v1에 없음) ─────────

create table public.purchases (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users (id) on delete cascade,
  product_id text not null,
  store      text not null,                        -- play/appstore
  receipt    jsonb not null,
  created_at timestamptz not null default now()
);

comment on table public.purchases is 'v2 결제용. v1은 테이블만 존재 — 클라이언트 쓰기 경로 없음 (서버 검증 후 service role INSERT).';

-- ── share_events (바이럴 측정) ───────────────────────────────────────────

create table public.share_events (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.users (id) on delete cascade,
  type       public.share_type not null,
  created_at timestamptz not null default now()
);

-- ── seed: §12 일간→동물 매핑 10종 ────────────────────────────────────────

insert into public.animals (id, name, element, personality, population_pct, asset_key) values
  ('gapmok',     '사슴',     '큰 나무',      '리더, 곧음, 개척',          10.0, 'animal_gapmok'),
  ('eulmok',     '토끼',     '화초·덩굴',    '유연, 사교적, 끈기',        10.0, 'animal_eulmok'),
  ('byeonghwa',  '사자',     '태양',         '열정, 표현력, 무대 체질',   10.0, 'animal_byeonghwa'),
  ('jeonghwa',   '여우',     '촛불·달빛',    '따뜻함, 직관, 헌신',        10.0, 'animal_jeonghwa'),
  ('muto',       '곰',       '산',           '듬직함, 신뢰, 포용',        10.0, 'animal_muto'),
  ('gito',       '카피바라', '밭·대지',      '보살핌, 겸손, 친화',        10.0, 'animal_gito'),
  ('gyeonggeum', '호랑이',   '바위·칼',      '결단, 의리, 강철 의지',     10.0, 'animal_gyeonggeum'),
  ('singeum',    '고양이',   '보석·금속',    '세련, 미감, 완벽주의',      10.0, 'animal_singeum'),
  ('imsu',       '고래',     '바다',         '깊은 지혜, 큰 꿈, 자유',    10.0, 'animal_imsu'),
  ('gyesu',      '수달',     '이슬비·시냇물','섬세, 공감, 통찰',          10.0, 'animal_gyesu');
