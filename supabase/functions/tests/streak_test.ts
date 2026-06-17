import { assertEquals } from "std/assert";
import { nextStreak, type StreakState } from "../_shared/streak.ts";

Deno.test("최초 개봉 → current 1", () => {
  const s = nextStreak(null, "2026-06-17");
  assertEquals(s, { current: 1, longest: 1, lastOpenedDate: "2026-06-17" });
});

Deno.test("연속 개봉 → +1", () => {
  const prev: StreakState = { current: 3, longest: 5, lastOpenedDate: "2026-06-16" };
  const s = nextStreak(prev, "2026-06-17");
  assertEquals(s.current, 4);
  assertEquals(s.longest, 5); // 아직 longest 안 넘음
});

Deno.test("연속으로 최고 기록 갱신", () => {
  const prev: StreakState = { current: 5, longest: 5, lastOpenedDate: "2026-06-16" };
  assertEquals(nextStreak(prev, "2026-06-17").longest, 6);
});

Deno.test("하루 건너뜀 → 1로 리셋(조용히)", () => {
  const prev: StreakState = { current: 9, longest: 9, lastOpenedDate: "2026-06-15" };
  const s = nextStreak(prev, "2026-06-17"); // 16 건너뜀
  assertEquals(s.current, 1);
  assertEquals(s.longest, 9); // 최고 기록은 보존
});

Deno.test("같은 날 재호출 → 멱등(변화 없음)", () => {
  const prev: StreakState = { current: 4, longest: 6, lastOpenedDate: "2026-06-17" };
  assertEquals(nextStreak(prev, "2026-06-17"), prev);
});

// ★ KST 자정 경계: 23:59 개봉(17일) → 00:01(18일) 개봉 = 연속
Deno.test("KST 자정 경계: 17일 23:59 개봉 후 18일 00:01 개봉 → 연속 +1", () => {
  // 23:59 KST 개봉 = KST 날짜 2026-06-17
  const after2359 = nextStreak(null, "2026-06-17");
  assertEquals(after2359.current, 1);
  // 00:01 KST = KST 날짜 2026-06-18 → 연속
  const after0001 = nextStreak(after2359, "2026-06-18");
  assertEquals(after0001.current, 2);
  assertEquals(after0001.lastOpenedDate, "2026-06-18");
});

// 월·년 경계도 하루 차이로 올바르게 연속 처리
Deno.test("월말 경계: 06-30 → 07-01 연속", () => {
  const a = nextStreak(null, "2026-06-30");
  assertEquals(nextStreak(a, "2026-07-01").current, 2);
});

Deno.test("연말 경계: 12-31 → 01-01 연속", () => {
  const a: StreakState = { current: 2, longest: 2, lastOpenedDate: "2026-12-31" };
  assertEquals(nextStreak(a, "2027-01-01").current, 3);
});
