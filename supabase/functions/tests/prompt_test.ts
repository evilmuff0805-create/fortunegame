// 어체 통일 자동검증 (반말 통일 규칙).
import { assert, assertEquals } from "std/assert";
import { hasHaeyoEnding, violatesTone } from "../_shared/prompt.ts";

Deno.test("해요체 어미 검출 = true", () => {
  const haeyo = [
    "오늘은 참 좋은 날이에요.",
    "우산을 챙겨요.",
    "충분히 빛날 자격이 있어요.",
    "그 느낌을 믿고 따라가 보세요.",
    "마음도 함께 펼쳐질 거예요!",
    "좋은 일들이 맞닿을 거예요. ✨",
    "한 발 내디뎌 봐요.",
    "참 멋있네요.",
  ];
  for (const t of haeyo) {
    assert(hasHaeyoEnding(t), `검출 실패: ${t}`);
  }
});

Deno.test("다정한 반말 = false (오탐 없음)", () => {
  const banmal = [
    "뿔 위로 무지개가 걸렸어. 한 발 더 나아가 보자.",
    "괜찮아, 천천히 가도 돼.",
    "빗소리가 좋은 날이네. 우산 챙기고 나가자.",
    "넌 이미 충분히 강하거든.",
    "그게 제일 중요.", // 요-명사 오탐 방지
    "마음이 고요.", // 요-명사 오탐 방지
    "오늘 하루도 네 페이스대로 가면 돼.",
  ];
  for (const t of banmal) {
    assert(!hasHaeyoEnding(t), `오탐: ${t}`);
  }
});

Deno.test("violatesTone이 해요체 혼입을 잡는다", () => {
  assertEquals(
    violatesTone("뿔을 쭉 펴는 기분이야. 오늘은 먼저 나서도 좋은 날이에요."),
    "해요체 어미 혼입 (반말 통일 위반)",
  );
  assertEquals(violatesTone("괜찮아, 천천히 가도 돼. 넌 잘하고 있어."), null);
});
