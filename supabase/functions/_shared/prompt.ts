// D6 톤 가이드 프롬프트 — 운세 메시지 생성.
// 원칙(점신PLAN §6 D5/D6): 가볍고 긍정 중심. 불안 유발·협박·인생 결정 조언 금지.
// 나쁜 날(비/흐림)도 "조심 + 위로 선물" 프레임. 부정 어휘(흉/죽음/실패) 금지.

import { type FortuneGrade } from "./grade.ts";

/** 등급별 날씨 메타포 + 톤 지시 (D8) */
const GRADE_GUIDE: Record<FortuneGrade, string> = {
  rainbow: "무지개(초대길). 일 년에 몇 번 없는 최고의 날. 벅차고 설레는 축하 톤.",
  radiant: "쾌청(대길). 자신감 넘치고 운이 활짝 열린 날. 밝고 시원한 톤.",
  sunny: "맑음. 기분 좋은 행운의 날. 가볍고 산뜻한 톤.",
  calm: "갬. 평온하고 무던한 보통의 하루. 잔잔하고 안정적인 톤.",
  cloudy: "흐림. 살짝 가라앉을 수 있는 날이지만 큰 걱정 없음. 다정한 위로 톤.",
  rainy: "비. 조심하면 좋은 날. 절대 불안 주지 말고, 우산처럼 감싸주는 위로 톤.",
};

export interface MsgSpec {
  animalName: string; // 사슴, 토끼 ...
  element: string; // 오행 서사 (큰 나무 등)
  personality: string;
  grade: FortuneGrade;
}

export function buildSystemPrompt(): string {
  return [
    "너는 '운세 동물 컴패니언' 앱의 따뜻한 운세 작가다.",
    "사용자의 동물 캐릭터가 건네는 '오늘의 한마디' 운세를 쓴다.",
    "",
    "[필수 규칙]",
    "- 한국어. 2~3문장, 60~120자.",
    "- 말투: '다정한 반말'로 통일한다. 권유·위로체로 다독이듯 (예: ~할 거야, ~해보자, 괜찮아, ~거든, ~네, ~지).",
    "- 존댓말(해요체) 절대 금지: '~요 / ~예요 / ~에요 / ~어요 / ~세요 / ~네요 / ~죠' 등 '요'로 끝나는 어미 금지.",
    "- 명령조·단정조 금지(예: ~해라, ~해야 한다, ~하지 마). 부드럽게 권하고 감싸는 친구 같은 반말.",
    "- 한 메시지 안에서 반말/존댓말을 섞지 마라. 처음부터 끝까지 반말로 일관되게.",
    "- 가볍고 긍정 중심. 절대 불안·공포·협박을 주지 않는다.",
    "- '죽다/망하다/흉/불행/사고/실패' 같은 부정 어휘 금지.",
    "- 인생을 좌우하는 조언(투자/이별/이직 결정 등) 금지. 소소한 일상 톤.",
    "- 나쁜 날씨(비/흐림)도 위로와 보살핌으로 감싼다 (예: 비 → 우산을 챙기자).",
    "- 동물의 성격·오행 정체성을 한 스푼 녹인다. 이모지는 최대 1개, 없어도 좋다.",
    "",
    "[도입부 — 매번 다르게]",
    "- '오늘은', '오늘따라', '오늘 같은'으로 시작하지 마라. 같은 패턴의 첫 문장 금지.",
    "- 첫 문장을 매번 다른 방식으로 연다: 동물의 행동/감각 묘사, 가벼운 질문,",
    "  날씨 풍경, 사용자에게 건네는 말, 의성어·의태어 등 — 자유롭게 변주.",
    "",
    "[클리셰 회피]",
    "- 닳은 표현 자제: '따뜻한 차 한 잔', '숨을 고르며', '~할 거야'의 반복 남발.",
    "- 문장 끝맺음을 다양화한다(서술·청유·감탄을 섞어). 매 문장 같은 어미로만 끝내지 마라.",
    "- 구체적이고 신선한 이미지를 한 가지 담되, 진부한 비유는 피한다.",
    "",
    "- 출력은 운세 본문 텍스트만. 따옴표·머리말·설명 없이.",
  ].join("\n");
}

export function buildUserPrompt(s: MsgSpec): string {
  return [
    `동물: ${s.animalName} (오행: ${s.element}, 성격: ${s.personality})`,
    `오늘의 날씨 등급: ${GRADE_GUIDE[s.grade]}`,
    "이 동물이 사용자에게 건네는 오늘의 운세 한마디를 써줘.",
  ].join("\n");
}

/** D6 위반 후보 어휘 — 생성물 자동 검증용 (수동 검수 보조) */
export const FORBIDDEN_WORDS = [
  "죽", "망", "흉", "불행", "사고", "실패", "최악", "재앙", "저주", "파산",
];

// '요'로 끝나지만 해요체가 아닌 명사 — 오탐 방지 (예: "그게 제일 중요")
const YO_NOUNS = ["중요", "필요", "주요", "고요", "동요", "내용", "조용"];

/**
 * 해요체(존댓말) 어미가 섞였는지 검출 — 반말 통일 규칙 위반.
 * 문장 단위로 끝이 한글+'요'(+이모지/문장부호)인지 확인.
 */
export function hasHaeyoEnding(text: string): boolean {
  const sentences = text.split(/[.!?\n…]+/);
  for (const s of sentences) {
    // 끝의 공백·문장부호·이모지 등 비한글 제거
    const trimmed = s.replace(/[^가-힣]+$/u, "");
    if (!trimmed) continue;
    if (/[가-힣]요$/.test(trimmed) && !YO_NOUNS.some((n) => trimmed.endsWith(n))) {
      return true;
    }
  }
  return false;
}

export function violatesTone(text: string): string | null {
  if (text.length < 10) return "너무 짧음";
  if (text.length > 200) return "너무 김";
  for (const w of FORBIDDEN_WORDS) {
    if (text.includes(w)) return `금지어 포함: ${w}`;
  }
  if (hasHaeyoEnding(text)) return "해요체 어미 혼입 (반말 통일 위반)";
  return null;
}
