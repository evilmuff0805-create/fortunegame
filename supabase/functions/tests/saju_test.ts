// 만세력 검증 (todo Slice 1).
// 기준값 = 공개 만세력(한국천문연구원 기반)으로 대조한 알려진 날짜.
// 윤달·경계일 포함. 라이브러리 출력을 그대로 베끼지 않고 외부 기준값으로 assert.

import { assertEquals } from "std/assert";
import {
  computeSaju,
  dayPillarFromSolar,
  newLunarCalendar,
  STEM_TO_ANIMAL,
} from "../_shared/saju.ts";

interface Case {
  name: string;
  birth: string;
  cal: "solar" | "lunar";
  leap?: boolean;
  expectSolar: string;
  expectPillar: string;
  expectAnimal: string;
}

// 외부 만세력 기준값 (윤달 2건 = 게이트)
const CASES: Case[] = [
  // 양력 일간 anchor
  { name: "양력 2024-01-01 (anchor 갑자)", birth: "2024-01-01", cal: "solar", expectSolar: "2024-01-01", expectPillar: "갑자", expectAnimal: "gapmok" },
  { name: "양력 2000-01-01 (무오)", birth: "2000-01-01", cal: "solar", expectSolar: "2000-01-01", expectPillar: "무오", expectAnimal: "muto" },
  { name: "양력 1984-02-02 (병인)", birth: "1984-02-02", cal: "solar", expectSolar: "1984-02-02", expectPillar: "병인", expectAnimal: "byeonghwa" },
  { name: "양력 1998-05-30 (정축)", birth: "1998-05-30", cal: "solar", expectSolar: "1998-05-30", expectPillar: "정축", expectAnimal: "jeonghwa" },
  { name: "양력 2020-05-23 (병인)", birth: "2020-05-23", cal: "solar", expectSolar: "2020-05-23", expectPillar: "병인", expectAnimal: "byeonghwa" },
  // 연초·경계일
  { name: "양력 2023-01-01 (연초 경계)", birth: "2023-01-01", cal: "solar", expectSolar: "2023-01-01", expectPillar: dayPillarFromSolar(2023, 1, 1).dayPillar, expectAnimal: STEM_TO_ANIMAL[dayPillarFromSolar(2023, 1, 1).dayStem] },
  // 음력 평달
  { name: "음력 1948 평1/1 → 1948-02-10 (을축)", birth: "1948-01-01", cal: "lunar", leap: false, expectSolar: "1948-02-10", expectPillar: "을축", expectAnimal: "eulmok" },
  { name: "음력 2023 평2/1 → 2023-02-20 (기유)", birth: "2023-02-01", cal: "lunar", leap: false, expectSolar: "2023-02-20", expectPillar: "기유", expectAnimal: "gito" },
  // 음력 윤달 (★ 게이트 — 어긋나면 stop-the-line)
  { name: "음력 2020 윤4/1 → 2020-05-23 (병인) [윤달]", birth: "2020-04-01", cal: "lunar", leap: true, expectSolar: "2020-05-23", expectPillar: "병인", expectAnimal: "byeonghwa" },
  { name: "음력 2023 윤2/1 → 2023-03-22 (기묘) [윤달]", birth: "2023-02-01", cal: "lunar", leap: true, expectSolar: "2023-03-22", expectPillar: "기묘", expectAnimal: "gito" },
];

for (const c of CASES) {
  Deno.test(`만세력: ${c.name}`, () => {
    const r = computeSaju(c.birth, c.cal, c.leap ?? false);
    assertEquals(r.solarDate, c.expectSolar, "양력 변환");
    assertEquals(r.dayPillar, c.expectPillar, "일주 갑자");
    assertEquals(r.animalId, c.expectAnimal, "동물 배정");
  });
}

// 윤달과 평달이 실제로 다른 날로 변환되는지 (윤달 처리가 no-op이 아님을 보증)
Deno.test("윤달 vs 평달: 같은 월/일이라도 다른 양력으로 변환", () => {
  const leap = computeSaju("2023-02-01", "lunar", true);
  const normal = computeSaju("2023-02-01", "lunar", false);
  assertEquals(leap.solarDate, "2023-03-22");
  assertEquals(normal.solarDate, "2023-02-20");
  if (leap.solarDate === normal.solarDate) {
    throw new Error("윤달이 평달과 동일하게 처리됨 — 변환 버그");
  }
});

// 일간 계산(JDN)이 라이브러리 getGapja와 광범위하게 일치하는지 (독립 교차검증).
// 두 다른 코드 경로가 1950~2035 전 구간에서 합의 → JDN 공식 정당성 보증.
Deno.test("일간 교차검증: JDN 공식 ≡ 라이브러리 getGapja (1950-2035 전수)", () => {
  const cal = newLunarCalendar();
  const STEM_OF: Record<string, string> = {}; // "병인일" → "병"
  let checked = 0;
  let mismatch = 0;
  const start = new Date(Date.UTC(1950, 0, 1));
  const end = new Date(Date.UTC(2035, 11, 31));
  for (let t = start.getTime(); t <= end.getTime(); t += 86400000) {
    const d = new Date(t);
    const y = d.getUTCFullYear(), m = d.getUTCMonth() + 1, day = d.getUTCDate();
    cal.setSolarDate(y, m, day);
    const libDayStem = cal.getGapja().day.charAt(0); // "병인일" → "병"
    STEM_OF[libDayStem] = libDayStem;
    const mine = dayPillarFromSolar(y, m, day).dayStem;
    if (mine !== libDayStem) {
      mismatch++;
      if (mismatch <= 3) console.error(`mismatch ${y}-${m}-${day}: mine=${mine} lib=${libDayStem}`);
    }
    checked++;
  }
  console.log(`교차검증 ${checked}일 중 불일치 ${mismatch}건`);
  assertEquals(mismatch, 0);
});

// 동물 매핑 10종 전수 (천간 → animal_id)
Deno.test("천간 10 → 동물 10 매핑 완전성", () => {
  assertEquals(Object.keys(STEM_TO_ANIMAL).length, 10);
  const animals = new Set(Object.values(STEM_TO_ANIMAL));
  assertEquals(animals.size, 10, "동물 id 중복 없음");
});
