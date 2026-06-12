# 운세 동물 컴패니언 (가칭: 포츈쿡 2)

사주가 정해준 나만의 동물 컴패니언이 매일 운세를 건네고, 꾸미고 수집하며 키우는 앱.

> **단일 진실 공급원: [점신PLAN.md](점신PLAN.md)** — 모든 작업 전에 읽는다.
> 진행 체크리스트: [tasks/todo.md](tasks/todo.md) · 캐릭터 제작 규격: [골격가이드.md](골격가이드.md)

## 스택 (D9)

Flutter + Supabase(Auth/Postgres/Edge Functions) + Rive. 분석: PostHog.

## 실행

```sh
cp dart_defines.example.json dart_defines.json   # 값 채우기 (커밋 금지)
flutter run --dart-define-from-file=dart_defines.json
```

키 없이 실행하면 Supabase/분석이 비활성인 골조 모드로 뜬다 (디버그 홈에서 상태 확인).

## Supabase 적용

```sh
supabase link --project-ref <project-ref>
supabase db push
```

- 마이그레이션: `supabase/migrations/` (§7 스키마 전체 + RLS + animal_id 불변 트리거)
- Auth > Sign In/Up 에서 **Anonymous sign-ins 활성화** 필요 (첫 실행 즉시 익명 user 생성)

## 검증 환경 기록

- Flutter 3.44.2 stable / Supabase CLI 2.106.0 기준으로 골조 검증
- iOS는 Linux CI 컨테이너에서 빌드 불가 — 구조만 유지, 검증은 macOS에서 수행할 것
