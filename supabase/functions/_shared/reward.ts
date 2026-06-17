// 등급 → 보상 아이템 매핑 (결정 2: 등급당 고정, 랜덤 아님 — D3).
// 랜덤성은 이미 운세(등급)가 결정했으므로 보상은 결정론적 1:1.
// 확률·아이템은 가역(데이터 보고 조정). null = 보상 아이템 없음(갬 = 카드 자체가 선물).

import { type FortuneGrade } from "./grade.ts";

export const GRADE_REWARD: Record<FortuneGrade, string | null> = {
  rainbow: "bg_rainbow01", // 비매품 한정
  radiant: "hat_beret01", // 희귀 (실제 아트)
  sunny: "card_lucky01", // 행운 카드 (공유용)
  calm: null, // 평온 — 아이템 없음, 카드가 선물
  cloudy: "charm_comfort01", // 위로 (일반)
  rainy: "charm_umbrella01", // 위로 + 우산·부적
};

/**
 * 개봉 전 누설 티어 (§11-3 기대 스파이크).
 * 좋은 희귀 등급만 누설하고, 나머지(비/흐림/갬/맑음)는 전부 'none'으로 동일하게 보여
 * "나쁜 날 골라 안 열기" 악용을 원천 차단(①). 등급은 결정론이라 안 열어도 안 바뀜.
 */
export function leakTier(grade: FortuneGrade): "rainbow" | "radiant" | "none" {
  if (grade === "rainbow") return "rainbow";
  if (grade === "radiant") return "radiant";
  return "none";
}
