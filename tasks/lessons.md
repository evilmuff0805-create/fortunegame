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

## 2026-06-16 (Slice 1 — LLM 생성물 톤 검증)

- **금지어를 단일 글자 substring으로 막으면 오탐 폭탄.** `"망"`이 망설임·희망·소망·전망을,
  `"죽"`이 죽(음식)을, `"사고"`가 사고력·사고방식을 잡음 → 멀쩡한 문장이 배치에서 탈락.
  부정 용법만 매칭하는 정규식으로(`/망(하|했|쳐|칠)/`, `/사고(?!력|방식|회로)/` 등) 좁혀야 함.
  교훈: LLM 출력 필터는 "단어 포함"이 아니라 "용법" 기준으로. 오탐은 좋은 생성물을 버리고 토큰을 태움.
- **해요체/반말 판별은 문장 끝 `요`로.** 단, 요-명사(중요·필요·고요·조용…)가 문장 끝에 오면 오탐 →
  명사 denylist로 제외. 검출은 문장 분리 후 끝 토큰만 검사(`[가-힣]요$`), 중간 `요`는 무시.
- **상투구 차단은 정규식 앵커(`^`)로 위치를 좁혀라.** "도입부의 오늘은"만 막고 싶은데 앵커 없이 막으면
  문장 중간의 자연스러운 '오늘'까지 죽는다. 사용자 의도 = 위치 한정이면 `^`/`$`로 명시.
- **LLM 톤 재검 루프엔 반드시 재시도 상한 + 폴백.** 검증 실패 → 무한 재생성은 토큰·시간 낭비.
  N회(여기선 3) 초과 시 마지막 결과를 통과시키고 `degraded`로 로깅 → 검수 우선 대상으로 노출.
  단 빈 응답은 통과 불가(throw → 전일 폴백). "빈 화면 금지(D-fallback)"와 "무한루프 금지"를 양립.
- **자동검증 규칙은 프롬프트 지시만으로 강제되지 않는다.** 프롬프트에 "오늘은으로 시작 마라"를 넣어도
  60개 중 2개가 어김 → 하드체크(코드)로 막아야 cron이 매일 품질 보장. 프롬프트=권고, 코드체크=강제.
- **검증 로직은 배치에 태우기 전에 deno 단위 테스트로.** 검출 케이스 + 오탐 후보를 같이 넣어
  (예: 해요체 8건 잡기 / 필요·희망·죽 통과) 실 LLM 호출(비용) 없이 필터 정확도를 먼저 고정.

## 2026-06-16 (Slice 2 — 온보딩·배정·계정 승격)

- **Supabase는 `@example.com` 등 테스트 도메인을 거부**(`email_address_invalid`, 본문에 빈 이메일로 표시돼 헷갈림).
  익명→이메일 승격 E2E는 실제 도메인으로 테스트할 것. 인박스 없이 검증하려면 admin API
  (`PUT /auth/v1/admin/users/{id}` + service_role, `email_confirm:true`)로 확정 후 password grant 재로그인.
  실제 OTP 전달은 SMTP 설정 필요(빌트인 메일러는 한도 매우 낮음 → 프로덕션 전 커스텀 SMTP).
- **익명→이메일 승격은 uid를 보존**한다 → animal_id가 uid 기반이라 프로필 행이 그대로(D1 복원의 핵심).
  reload 불필요(행 불변). 단 라우터가 프로필을 watch하면 승격/배정 직후 reload 시 **온보딩 도중 홈으로 채감** →
  reload는 "시작하기"(onComplete) 시점에만. 연출/소개 중에는 결과를 로컬 state로 들고 간다.
- **서버 권위 쓰기 + RLS 잠금 패턴(D10과 동일)**: animal_id 위조를 막으려면 users INSERT 정책을 제거하고
  Edge Function(service-role)만 쓰게. 멱등성: 이미 프로필 있으면 다른 입력이 와도 기존 동물 반환(불변 트리거와 이중 방어).
- **share_plus 12.x API 변경**: `Share.shareXFiles(...)` → `SharePlus.instance.share(ShareParams(text:, files:[XFile]))`.
- **위젯→이미지 공유는 RepaintBoundary + path_provider.** `boundary.toImage(pixelRatio:3)` → PNG bytes →
  temp dir 파일 → XFile. 캡처 대상은 화면에 마운트돼 있어야 함(오프스크린이면 별도 렌더 필요).
- **플레이스홀더 단계에선 '흐름'과 '감동'을 분리해 검증·평가**. 아트 전 슬라이스는 경로/상태/데이터 정합만 보고,
  완성도 판단은 아트 후로 미룬다(todo에 명시) — 조기 평가로 흔들리지 않기.

## 2026-06-17 (카피바라 파일럿 아트 처리)

- **채팅 업로드 이미지는 컨테이너 디스크에 없다.** 픽셀 처리하려면 파일이 디스크에 있어야 함 →
  사용자가 GitHub 웹으로 레포에 커밋 → `git fetch/pull`로 수령하는 경로가 확실(이 환경은 git 기반).
  업로드 staged 상태와 commit 완료는 다름 — `git log`로 실제 커밋 도착을 확인하고 진행.
- **이미지 도구는 기본 미설치(PIL/numpy/ImageMagick 없음). pip는 HTTPS로 동작** → `pip install Pillow numpy scipy`.
- **누끼는 색키잉 말고 외곽 플러드필.** near-bg 마스크를 `ndimage.label` 후 **테두리에 연결된 라벨만** 제거 →
  내부 흰색(눈 하이라이트)은 외곽과 단절돼 보존. AA 흰 후광은 bg마스크 1px `binary_dilation`으로 제거
  (어두운 아웃라인은 색차 커서 무사). 검증: 처리 후 내부 흰픽셀 수 > 0 + 투명비율 확인.
- **'투명해 보임'에 속지 말 것.** Read 렌더의 체커보드 ≠ 실제 알파. 코너 픽셀 알파를 직접 확인하니
  동물은 100% 불투명(흰 배경), 모자만 이미 투명이었음. 처리 전 알파 실측 필수.
- **에셋은 마스터(2048, art/master, 비번들)와 앱(512, assets/, 번들) 분리**(골격가이드 §1). 2048을 APK에 넣지 않는다.
- **처리는 스크립트로 재현 가능하게**(`art/process_capybara.py`). 나머지 9종 양산 시 그대로 재사용 — 일회성 수작업 금지.
