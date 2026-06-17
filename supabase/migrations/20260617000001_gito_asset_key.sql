-- 카피바라 파일럿 아트 연결 (골격가이드 §9·§10).
-- gito 기본 컷 파일 stem으로 asset_key 갱신. 나머지 9종은 양산 후 갱신.
update public.animals set asset_key = 'animal_gito_base' where id = 'gito';
