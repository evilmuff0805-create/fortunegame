// 결정론 등급 + 카테고리 점수 (D8/D10).
//
// 등급 = hash(일주, 날짜KST) → §4.1 확률 분포 매핑.
// 결정론 필수: 재개봉·기기 변경·재설치에도 동일해야 '운세'(매번 바뀌면 '뽑기' = D3 위반).
// → Math.random() 금지. 입력은 (일주 갑자 + KST 날짜)뿐.
//
// 해시 입력 계약(동결): `${dayPillar}|${dateKst}`
//   saju_pillars에 월주·시주를 나중에 추가해도 등급이 바뀌면 안 되므로(과거 운세 불변),
//   해시 입력은 일주와 날짜만으로 영구 고정한다.

import { STEMS } from "./saju.ts";

export type FortuneGrade =
  | "rainbow"
  | "radiant"
  | "sunny"
  | "calm"
  | "cloudy"
  | "rainy";

/** §4.1 분포 (확률 수치는 가역, 등급 골격은 비가역). 누적 매핑용 순서. */
export const GRADE_DISTRIBUTION: ReadonlyArray<{ grade: FortuneGrade; p: number }> = [
  { grade: "rainbow", p: 0.01 }, // 무지개 (초대길)
  { grade: "radiant", p: 0.03 }, // 쾌청 (대길)
  { grade: "sunny", p: 0.24 }, // 맑음
  { grade: "calm", p: 0.32 }, // 갬
  { grade: "cloudy", p: 0.25 }, // 흐림
  { grade: "rainy", p: 0.15 }, // 비
];

export interface CategoryScores {
  wealth: number; // 재물
  love: number; // 애정
  health: number; // 건강
  work: number; // 일
}

export interface FortuneResult {
  grade: FortuneGrade;
  scores: CategoryScores;
}

/** 해시 입력 계약 — 형식 변경 금지 (과거 운세 결정론 깨짐) */
export function hashInput(dayPillar: string, dateKst: string): string {
  return `${dayPillar}|${dateKst}`;
}

async function sha256Bytes(input: string): Promise<Uint8Array> {
  const data = new TextEncoder().encode(input);
  const buf = await crypto.subtle.digest("SHA-256", data);
  return new Uint8Array(buf);
}

/** 4바이트 빅엔디언 → [0,1) 실수 */
function bytesToUnitFloat(b: Uint8Array, offset: number): number {
  const v =
    (b[offset] << 24) |
    (b[offset + 1] << 16) |
    (b[offset + 2] << 8) |
    b[offset + 3];
  // >>> 0 으로 부호 제거 → uint32
  return (v >>> 0) / 0x100000000;
}

/** 누적 분포로 등급 결정 */
export function gradeFromFraction(f: number): FortuneGrade {
  let acc = 0;
  for (const { grade, p } of GRADE_DISTRIBUTION) {
    acc += p;
    if (f < acc) return grade;
  }
  return GRADE_DISTRIBUTION[GRADE_DISTRIBUTION.length - 1].grade; // 부동소수 보정
}

/** 등급별 점수 기준선 — 좋은 날일수록 높게 (D6: 나쁜 날도 바닥 아닌 위로 범위) */
const GRADE_SCORE_BASE: Record<FortuneGrade, number> = {
  rainbow: 88,
  radiant: 80,
  sunny: 70,
  calm: 58,
  cloudy: 48,
  rainy: 40,
};

/**
 * 결정론 운세 = 등급 + 4카테고리 점수.
 * 모두 같은 SHA-256 해시에서 파생 (D10).
 */
export async function computeFortune(
  dayPillar: string,
  dateKst: string,
): Promise<FortuneResult> {
  const h = await sha256Bytes(hashInput(dayPillar, dateKst));

  const grade = gradeFromFraction(bytesToUnitFloat(h, 0));

  // 카테고리 점수: 등급 기준선 ± (해시 바이트로 ±12 변동), 1~100 클램프
  const base = GRADE_SCORE_BASE[grade];
  const jitter = (byte: number) => Math.round((byte / 255) * 24 - 12); // -12..+12
  const clamp = (n: number) => Math.max(1, Math.min(100, n));
  const scores: CategoryScores = {
    wealth: clamp(base + jitter(h[8])),
    love: clamp(base + jitter(h[9])),
    health: clamp(base + jitter(h[10])),
    work: clamp(base + jitter(h[11])),
  };

  return { grade, scores };
}

// STEMS는 매핑 검증용 재노출 (테스트에서 사용)
export { STEMS };
