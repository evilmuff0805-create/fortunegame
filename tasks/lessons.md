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
