-- daily-batch cron (D10): 매일 00:05 KST = 15:05 UTC.
-- 시크릿은 git에 두지 않는다 → Vault 참조(project_url, service_role_key).
-- 배포 시 Management API로 두 시크릿을 주입한 뒤 이 마이그레이션을 적용한다.

create extension if not exists pg_cron;
create extension if not exists pg_net;

-- 재적용 안전: 기존 job 제거 후 재등록
select cron.unschedule('daily-fortune-batch')
where exists (select 1 from cron.job where jobname = 'daily-fortune-batch');

select cron.schedule(
  'daily-fortune-batch',
  '5 15 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
           || '/functions/v1/daily-batch',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key')
    ),
    body := '{}'::jsonb
  );
  $$
);
