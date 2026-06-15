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
- [x] D6 톤 가이드 프롬프트 작성 + 금지어 자동 검증 / **수동 검수는 크레딧 충전 후 1회 예정**
- [~] Verify: 사주→동물·날짜→등급 E2E 확인 / **메시지 생성은 Anthropic 크레딧 부족으로 보류**
      → 키는 유효(인증 통과), 계정 잔액 0. 충전 후 배치 1회 재실행하면 60개 채워짐.

## Slice 2 — 온보딩 → 배정 (첫 수직 슬라이스, Day 0 승부처)

- [ ] 입력 UI: 생년월일, 양/음력, 시간(선택 — "모르면 건너뛰기")
- [ ] 배정 연출 v1: 심플 봉투/카드 오픈 (Rive 1개 또는 커스텀, 2~4초 + 탭 스킵)
- [ ] 동물 소개 화면: 일간 서사 + "전체의 N%" 통계 동질감 문구
- [ ] 공유 카드 ①: "넌 무슨 동물?" 이미지 합성 → share_plus
- [ ] 소셜 로그인 연결(Google/Apple) — 익명 계정 승격, 동물 보존 확인
- [ ] Verify: 신규 설치 → 배정 → 공유 → 재설치 → 로그인 → 동일 동물 복원 (수동 E2E)

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
- **미완**: daily-batch 실배치 — Anthropic 계정 크레딧 부족(400 credit balance)으로 0개 생성.
  인증·루프·에러핸들링·폴백 경로는 정상 동작 확인. 크레딧 충전 후 1회 재실행 필요.

**다음 슬라이스 전 사용자 액션:**
- Anthropic 콘솔에서 크레딧 충전(Plans & Billing) → daily-batch 재실행하면 60개 생성·검수 가능

## Lessons → tasks/lessons.md

(수정·실수 발생 시 즉시 기록)
