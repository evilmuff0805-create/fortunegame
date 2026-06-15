# tasks/lessons.md — 수정·실수 기록

## 2026-06-12 (Slice 0)

- **flutter_local_notifications(v19)는 core library desugaring 필수.** flutter create 직후
  APK 빌드가 `checkDebugAarMetadata`에서 실패 → `android/app/build.gradle.kts`에
  `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` 추가로 해결.
- **원격 실행 환경은 아웃바운드가 HTTPS(443)만 열림.** Postgres 5432 직결·풀러 전부 차단 →
  `psql`/`supabase db push` 불가. 대신 Supabase **Management API**(`/v1/projects/{ref}/database/query`,
  PAT 필요)로 마이그레이션 적용·SQL 검증 가능. 익명 로그인 토글도 같은 API(`/config/auth`)로 처리.
- **supabase_flutter 2.10부터 `anonKey` 파라미터 deprecated** → `publishableKey` 사용
  (legacy anon key 값도 그대로 호환).

## 2026-06-15 (Slice 1)

- **Deno가 시스템 CA를 안 써서 npm/jsr import가 `UnknownIssuer`로 실패.** 이 환경은 프록시 MITM이라
  `DENO_TLS_CA_STORE=system` 필요 (deno test/check/run 전부). NODE_EXTRA_CA_CERTS·SSL_CERT_FILE은 이미 set.
- **Supabase 원격 함수 배포 번들러는 `functions/deno.json`의 import map을 적용하지 않음.**
  bare specifier(`"korean-lunar-calendar"`)가 "not prefixed" 400 → 코드에서 `npm:패키지@버전` 완전 지정해야 함.
- **`--no-verify-jwt` 배포는 auto-mode classifier가 차단(정당).** 함수가 자체 인증을 해도 플랫폼 JWT 검증은 켜둘 것.
  익명 JWT·service-role 키 모두 유효한 JWT라 verify_jwt=true로도 통과함.
- **service-role 판정은 키 문자열 정확 비교 대신 JWT role 클레임으로.** Management API api-keys가 주는
  service_role 키와 함수 env `SUPABASE_SERVICE_ROLE_KEY`가 포맷(legacy/신규)으로 어긋날 수 있음.
  payload.role === 'service_role' 검사가 견고 (서명은 플랫폼이 이미 검증).
- **RLS 설계상 daily_fortunes INSERT는 service-role 전용**(D10: 클라가 등급 위조 못 하게). Edge Function이
  사용자 JWT로 등급을 쓰려다 RLS 차단됨 → 인증은 사용자 JWT, 등급 기록은 service-role 클라이언트로 분리.
- **bash `UID`는 readonly 예약 변수** — 스크립트에서 사용자 id 담으면 `readonly variable` 에러. `USERID` 등으로.
- **Anthropic 400 `credit balance is too low`는 키 유효 + 잔액 0.** 401(키 오류)과 구분. 배치 코드는 정상,
  계정 결제만 필요.
