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

Deno.test("금지 표현: 진짜 부정 용법만 잡고 오탐 없음", () => {
  // 부정 용법 → 잡혀야
  assert(violatesTone("오늘 일이 망해버릴 것 같아. 조심하자.") !== null);
  assert(violatesTone("불행이 닥칠 거야. 무서워하자.") !== null);
  // 오탐 후보 → 통과해야 (망설임/희망/죽(음식)/사고력/전망)
  for (
    const ok of [
      "망설임 없이 네가 하고 싶던 말을 꺼내 보자.",
      "작은 희망 하나가 너를 환하게 데워줄 거야.",
      "따뜻한 죽 한 그릇처럼 속이 든든해지는 하루가 될 거야.",
      "네 사고력이 오늘따라 반짝이니까 마음껏 굴려 보자.",
      "전망 좋은 창가에서 잠깐 멍때려도 괜찮아.",
    ]
  ) {
    assertEquals(violatesTone(ok), null, `오탐: ${ok}`);
  }
});
