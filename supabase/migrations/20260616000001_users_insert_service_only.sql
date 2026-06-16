-- 동물 배정 서버 권위화 (D1/D7): users 행 INSERT를 service-role 전용으로.
-- calc-saju Edge Function만 프로필을 만든다 → 클라이언트가 animal_id를 위조 불가.
-- read/update(본인) 정책과 animal_id 불변 트리거는 유지.

drop policy if exists "users: insert own" on public.users;

-- (authenticated용 INSERT 정책 없음 = service-role만 통과. RLS는 service-role을 우회.)
