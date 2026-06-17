# tasks/todo.md — v1 빌드 (운세 동물 컴패니언)

> 기준 문서: 점신PLAN.md (§5 v1 범위, §6 비가역 결정, §7 스키마), 골격가이드.md
> 운영: plan mode로 슬라이스 단위 진행. 예상 밖 상황 = stop-the-line → 재계획.
> 이미지는 플레이스홀더로 진행 (카피바라 파일럿과 병렬). 결제 코드 일절 없음 (v1 의도적 제외).

## 목표 + 수용 기준

**가설: "사람들이 매일 돌아와서 봉투를 찢는가?" (PLAN §9)**

v1 완료 조건:
- [ ] 신규 사용자가 생년월일 입력 → 동물 배정 → 매일 카드팩 찢기 → 보상 수령 → 꾸미기 → 앨범 확인까지 막힘 없이 가능
- [ ] 개발자 본인 기기(안드로이드)에서 7일 연속 도그푸딩 성공 (매일 아침 알림 → 개봉)
- [ ] 같은 사용자·같은 날 = 항상 같은 운세 (재실행·재설치·기기 변경 모두) — D10 결정론
- [ ] 기기 분실 시나리오: 새 기기 로그인 → 동물·인벤토리·앨범 100% 복원 — D1 보호
- [ ] 분석 이벤트로 D1/D7 리텐션, 당일 개봉률, 공유율 측정 가능
- [ ] daily_fortunes에 첫 사용자 첫날부터 기록 존재 (D4)

## Working Notes (제약·불변량 — 세션 시작 시 읽기)

- 동물 배정은 **불변** (D1): users.animal_id에 UPDATE 경로를 만들지 않는다
- 등급은 hash(saju, date) **결정론** (D10): Math.random() 금지. 날짜 경계 = KST 자정
- 운세 텍스트는 (동물 10 × 등급 6) = 60개/일 캐싱. **사용자별 LLM 호출 금지** (원가 고정)
- 유료 랜덤 없음 (D3), 다크 패턴 없음 (D5), 불안 유발 문구 없음 (D6 — 배치 프롬프트에 톤 가이드)
- 아이템 렌더링 = 골격가이드 §3 앵커 좌표 (정규화). 하드코딩 픽셀 금지
- 스토어 카테고리 = 라이프스타일 (D2)

---

## Slice 0 — 프로젝트 골조 ✅ (2026-06-12)

- [x] Flutter 프로젝트 생성 (Android 우선 타깃, iOS 빌드 유지)
- [x] 패키지: supabase_flutter, rive, share_plus, flutter_local_notifications, 햅틱(Flutter 내장 HapticFeedback)
- [x] Supabase 프로젝트 + §7 스키마 전체 마이그레이션 (v1 미사용 테이블 포함 — purchases 등)
- [x] RLS 정책: 사용자는 자기 행만 읽기/쓰기 (animal_id는 INSERT만, UPDATE 불가 정책)
- [x] 익명 인증(anonymous sign-in)으로 첫 실행 즉시 user 생성
- [x] 분석 SDK 연결 + 이벤트 상수 정의 (onboarding_complete, pack_opened, shared_assign, shared_lucky)
      — PostHog 래퍼 완료, **API key 미발급 → no-op 모드. 키 받으면 dart_defines.json에 주입만 하면 됨**
- [x] Verify: 빌드 성공, 익명 유저 생성·RLS 차단 동작을 SQL로 확인 (아래 Results)

## Slice 1 — 사주 엔진 (서버, UI 없이 검증 가능)

- [x] Edge Function `calc-saju`: 생년월일(양/음) → 일간 → animal_id — 배포·E2E 확인
- [x] 만세력 검증: 10 테스트 케이스 (공개 만세력 대조) — 음력 윤달 2건 포함, 전부 통과
- [x] 등급 함수: hash(일주, date_kst) → §4.1 분포 매핑 + 카테고리 점수 파생
- [x] 결정론 테스트: 동일 입력 1,000회 동일 / 분포 10만 샘플 최대 편차 0.24%p
- [x] Edge Function `daily-batch` (cron 00:05 KST 등록됨): LLM 60개 생성 → fortune_msgs
- [x] 배치 실패 폴백: 전일 메시지 재사용 + 로그 (코드 완성, 동작 확인 — 첫날은 전일 없음)
- [x] D6 톤 가이드 프롬프트 작성 + 금지어 자동 검증 / 첫 배치 60개 생성·금지어 0건 (사용자 검수 진행)
- [x] Verify: 사주→동물·날짜→등급·메시지 조회 E2E 전부 확인 (2026-06-16 배치 60/60 생성)

## Slice 2 — 온보딩 → 배정 (첫 수직 슬라이스, Day 0 승부처) ✅ (2026-06-16)

> ⚠️ 배정 연출·공유 카드·동물 비주얼은 **전부 플레이스홀더**(아트 전). 이 슬라이스는 **흐름만** 검증한다.
> "개봉이 의식처럼 기분 좋은가" 같은 **감동·완성도 평가는 실제 아트(카피바라 파일럿) 이후로 미룬다.**

- [x] 입력 UI: 생년월일, 양/음력(+윤달), 시간(선택 — "모르면 건너뛰기"), 성별(선택)
- [x] **배정 확인 단계(추가, D1 안전장치)**: "동물은 한 번 정해지면 못 바꿈" 안내 + 생년월일·양음력 재확인
      (오입력 영구 오배정 방지. 협박 아닌 안내 톤 = D5 위반 아님)
- [x] 배정 연출 v1: 커스텀 봉투/카드 오픈(2.4초 + 탭 스킵). 플레이스홀더 — Rive는 아트 후
- [x] 동물 소개 화면: 오행 서사 + "전체의 N%" 동질감 문구 + 성격
- [x] 공유 카드 ①: "넌 무슨 동물?" 위젯→PNG(RepaintBoundary)→share_plus. shared_assign + share_events
- [x] 계정 승격: **이메일 OTP**(익명→이메일, uid 보존). Google/Apple은 버튼+비활성(코드 자리만)
      → **네이티브 OAuth 설정은 실기기 단계로 이연** (아래 Lessons 참조)
- [x] Verify: D1 핵심(익명→이메일→새 세션 로그인→동일 uid·animal_id) REST E2E 통과. 멱등성(다른 생일 재호출=기존 동물 유지) 확인
      → **신규설치→배정→공유→재설치→로그인 전체 수동 E2E는 실기기(Android)에서 — 컨테이너 불가분 이연**

## Slice 3 — 데일리 루프 (코어 가설)

- [ ] 홈 화면: 내 동물 + 오늘 봉투 (미개봉/개봉 상태)
- [ ] 찢기 인터랙션: 드래그 진행도 = 찢김 정도, 햅틱 단계 피드백 (플레이스홀더 에셋)
- [ ] 운세 카드 화면: 날씨 등급 + 카테고리 점수 + 메시지
- [ ] 보상 지급: 등급→아이템 (inventory INSERT, 수령 연출 심플)
- [ ] 무지개 사전 누설 연출 (개봉 전 봉투 틈 무지갯빛)
- [ ] 스트릭 로직 (KST 자정 경계 엣지케이스 테스트: 23:59 개봉 → 00:01 상태)
- [ ] 공유 카드 ②: "오늘의 행운" (맑음 이상에서 노출)
- [ ] 아침 로컬 푸시 (시간 설정 가능, 협박 문구 금지 — D5)
- [ ] Verify: 이틀 연속 실기기 개봉 (날짜 전환 확인), 등급별 보상 매핑 수동 점검

## Slice 4 — 꾸미기 + 앨범

- [ ] 꾸미기 화면: 슬롯 3개 (모자/손 소품/배경), 골격가이드 §3 앵커로 합성 렌더링
- [ ] equipped 저장 → 홈 화면 반영
- [ ] 카드 앨범: 월별 그리드, 개봉일 = 카드 / 미개봉일 = 빈 슬롯 (회색)
- [ ] Verify: 아이템 장착 → 재실행 유지, 하루 건너뛴 날 빈 슬롯 표시 확인

## Slice 5 — 마감 + 배포

- [ ] 빈 상태/오류/오프라인 처리 (배치 누락 폴백 포함)
- [ ] 분석 이벤트 전 구간 발화 확인 (개봉률·공유율 대시보드 쿼리 작성)
- [ ] 플레이스홀더 → 실제 에셋 교체 (카피바라 파일럿 검증 후 일괄)
- [ ] 스토어 등록: 라이프스타일 카테고리, 스크린샷, 개인정보처리방침
- [ ] 내부 테스트 트랙 배포 (Android 우선) → 본인 도그푸딩 7일 시작
- [ ] Verify: 수용 기준 전 항목 체크, 결과를 Results에 기록

---

## Results

(슬라이스 완료 시마다: 무엇이 바뀌었고, 어떻게 검증했는지)

### Slice 0 (2026-06-12)

**무엇이 바뀌었나:**
- Flutter 3.44.2 프로젝트 (applicationId `com.fortunecook.fortunegame` — 스토어 첫 업로드 전까지 변경 가능)
- `lib/core/`: env(--dart-define), Supabase 부트스트랩(익명 로그인), PostHog 래퍼(no-op 폴백), 이벤트 상수 4종
- `supabase/migrations/`: §7 스키마 전체 + animals 10종 시드(§12) + RLS 20개 정책 + animal_id 불변 트리거(D1)
- Supabase 클라우드 프로젝트 `oqistijjopgzjloncoru`(ap-northeast-2)에 적용 완료, anonymous sign-in 활성화

**어떻게 검증했나:**
- `flutter analyze` 0 issues / `flutter test` 2건 통과 / `flutter build apk --debug` 성공
- REST 실검증 (익명 유저 A·B 2명 생성):
  - A 자기 users 행 INSERT → 201 / A가 B의 uid로 INSERT → 403 (RLS 차단)
  - B의 users SELECT → 빈 배열 (타인 행 안 보임) / B가 A 행 UPDATE → 0행 영향
  - A의 animal_id 변경 시도 → `animal_id is immutable (D1)` 트리거 예외 / settings 변경 → 204 허용
- iOS: Linux 컨테이너라 빌드 검증 불가 — macOS에서 수행 필요 (이연)

**다음 슬라이스 전 사용자 액션:**
- PostHog 프로젝트 생성 후 API key를 dart_defines.json에 주입 (없어도 앱 동작엔 지장 없음) — 2026-06-15 완료

### Slice 1 (2026-06-15)

**무엇이 바뀌었나:**
- `supabase/functions/_shared/`: 사주 일간(JDN 순수계산)·등급(SHA-256 결정론)·KST 경계·D6 프롬프트·CORS
- Edge Function 3개 배포 (Supabase `oqistijjopgzjloncoru`):
  - `calc-saju` — 생년월일(양/음·윤달) → 일주 갑자 + animal_id
  - `today-fortune` — 오늘(KST) 등급·점수·메시지 + daily_fortunes 기록(D4). 등급 기록은 service-role(클라 위조 차단)
  - `daily-batch` — Haiku로 60개(동물10×등급6) 생성 + 전일 폴백. service-role(role 클레임 검증)
- cron `daily-fortune-batch` 등록(`5 15 * * *` = 00:05 KST), 시크릿은 Vault(project_url/service_role_key)
- 해시 입력 계약 동결: `${일주갑자}|${YYYY-MM-DD KST}` (월주·시주 추가해도 과거 운세 불변)

**어떻게 검증했나 (deno test 17개 통과):**
- 만세력 10케이스: 양력 anchor(2024-01-01 갑자, 2000-01-01 무오) + 음력 윤달 2건
  (음력 2020 윤4/1→2020-05-23, 2023 윤2/1→2023-03-22, 공개 만세력 일치). **윤달 게이트 통과**
- 일간 교차검증: JDN 공식 ≡ 라이브러리 getGapja, 1950–2035 **31,411일 0건 불일치**
- 결정론 1,000회 동일 / 분포 10만 샘플 최대 편차 0.24%p
- 실배포 E2E (익명 유저, curl): calc-saju 양력 1990-05-15→경진→호랑이, 음력 윤2/1→2023-03-22 기묘→카피바라;
  today-fortune 2회 호출 동일 등급(cloudy)·점수 = 결정론 확인
- daily-batch 실배치(2026-06-16): **60/60 생성, errors 0, 금지어 0건, 길이 전부 정상**.
  today-fortune E2E(양력 1988-12-25→갑인→사슴, rainy)에서 메시지 정상 연결 확인.
  크레딧 충전(2026-06-16) 후 재실행으로 해결.

**Slice 1 완료. 다음 슬라이스 전 사용자 액션:**
- 생성된 60개 메시지 직접 검수(동물×등급) — 톤/표현 수정 원하면 프롬프트(`_shared/prompt.ts`) 조정 후 재배치
- cron이 매일 00:05 KST 자동 생성하므로 이후 별도 조치 불필요

### Slice 2 (2026-06-16)

**무엇이 바뀌었나:**
- 동물 배정 **서버 권위화**: `calc-saju`가 사주 계산 + `users` 행 upsert(service-role)까지. 입력에 birthTime/gender 추가
- 마이그레이션 `20260616000001`: users INSERT 정책 제거 → service-role 전용(클라이언트 animal_id 위조 차단). read/update·불변 트리거 유지
- 이메일 인증 활성화(Management API). 익명 sign-in과 병행
- Flutter: Riverpod 데이터 계층(animalCatalog/profile/onboardingRepo), 온보딩 플로우(웰컴→입력→확인→연출→소개),
  계정연결 시트(이메일 OTP + OAuth 자리), 최소 홈, 라우터 게이트(프로필 유무 분기). `path_provider` 추가
- 플레이스홀더: 동물=파스텔 원+이모지, 배정 연출=커스텀 봉투 오픈, 공유 카드=위젯 캡처 (전부 아트 후 교체)

**어떻게 검증했나:**
- `flutter analyze` 0 issues / `flutter test` 5건 통과 / `flutter build apk --debug` (dart-define 주입) — 빌드 확인
- 백엔드 E2E (REST+Admin):
  - calc-saju 서버 권위 프로필 생성, **클라이언트 직접 users INSERT → 403 차단**
  - **D1 핵심**: 익명→`updateUser(email)`→(admin 확정)→이메일 새 세션 로그인 → **uid 동일·animal_id 보존(imsu)**
  - 음력 윤달+시간+성별 저장 정상(카피바라, solarDate 2023-03-22)
  - 멱등성: 다른 생일로 calc-saju 재호출해도 기존 동물 유지 + alreadyAssigned=true (D1 서버 강제)
- 플레이스홀더라 **감동·완성도 평가는 아트 후로 유보**(흐름만 검증)

**다음 슬라이스 전 사용자 액션:**
- (선택) 실기기에서 신규설치→배정→공유→재설치→이메일로그인→동물복원 수동 E2E (컨테이너 검증 불가분)
- Google/Apple 쓰려면 네이티브 OAuth 설정 필요 (실기기 단계, lessons 참조)

### 카피바라 파일럿 아트 (2026-06-17) — D11 §10 step 2

**무엇이 바뀌었나:**
- 원본 6장 수신(`art/raw/capybara/`) → `art/process_capybara.py`로 일괄 처리(재현 가능, 9종 양산 재사용)
- 누끼: **외곽 플러드필**(테두리 연결 흰색만 제거) — 눈 하이라이트 등 내부 흰색 보존(~1900px 확인)
- §1 규격: 동물 5종 2048² 마스터(정수리 0.12/바닥 0.88/중심 0.50 자동검증 OK), 512² 앱 에셋
- §8 모자: 이미 투명 → 1024×768 하단중앙 재배치(`item_hat_beret01`)
- §9 네이밍: `animal_gito_base/deliver`, `face_gito_happy/worry/wow`, `item_hat_beret01`
- 연결: pubspec assets 등록, animals.gito.asset_key='animal_gito_base', AnimalPlaceholder가 gito는 실제 이미지·나머지 9종은 색 플레이스홀더
- **이제 gito만 실제 아트** — 온보딩/소개/홈/공유카드에서 카피바라 진짜 그림 노출. 9종은 여전히 플레이스홀더

**검증:** flutter analyze 0 / test 5건 / APK 빌드. 512 앱 에셋 시각 확인(투명·하이라이트·후광 없음)
**유보:** 표정은 풀 스프라이트(눈·입 분리 레이어 아님 — 벡터 원본 필요 시 후속). 모자 앵커 스냅은 Slice 4

## Lessons → tasks/lessons.md

(수정·실수 발생 시 즉시 기록)
