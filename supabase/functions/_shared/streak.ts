// 스트릭 전이 (KST 날짜 경계, D10). 순수 함수 — deno 테스트로 경계 검증.
// 다크패턴 금지(D5): 끊김은 조용히 1로 리셋, 협박·죄책감 문구는 UI에서 안 쓴다.

export interface StreakState {
  current: number;
  longest: number;
  lastOpenedDate: string | null; // 'YYYY-MM-DD' (KST)
}

/** 'YYYY-MM-DD' 두 날짜가 정확히 하루 차이인가 (prev → today 연속). */
function isConsecutive(prev: string, today: string): boolean {
  const a = Date.parse(`${prev}T00:00:00Z`);
  const b = Date.parse(`${today}T00:00:00Z`);
  return b - a === 86_400_000;
}

/**
 * 개봉 시 스트릭 전이.
 * - 같은 날 재호출 → 변화 없음 (멱등)
 * - 어제 개봉 → current+1 (연속)
 * - 그 외(공백/최초) → current=1 (조용히 리셋)
 */
export function nextStreak(prev: StreakState | null, today: string): StreakState {
  const p = prev ?? { current: 0, longest: 0, lastOpenedDate: null };
  if (p.lastOpenedDate === today) return p; // 멱등

  const current = (p.lastOpenedDate && isConsecutive(p.lastOpenedDate, today))
    ? p.current + 1
    : 1;
  return {
    current,
    longest: Math.max(p.longest, current),
    lastOpenedDate: today,
  };
}
