// 사주 일간 계산 (D7/D10).
//
// 일간(천간)은 양력 날짜만으로 결정되는 60갑자의 연속 순환이다.
// 따라서 일간 계산은 외부 라이브러리 없이 JDN(율리우스 적일) 공식으로 직접 구현한다
// → 순수 함수 = 결정론(동일 입력 동일 출력) + 단위 테스트 용이.
//
// 음력 입력은 양력으로의 "변환"에만 korean-lunar-calendar를 쓴다(절기·윤달 데이터 의존).
// 변환된 양력 날짜로 다시 JDN → 일간을 계산하므로 일간 자체는 라이브러리에 의존하지 않는다.
//
// anchor: 2024-01-01 = 갑자일 (한국천문연구원 만세력 기준, 라이브러리 getGapja와 교차검증).
//   → 천간 index = (JDN + 9) mod 10,  간지 index = (JDN + 49) mod 60.
//   교차검증: 2000-01-01 → 무오일(천간 '무'), 통과.

import KLCDefault from "korean-lunar-calendar";

// korean-lunar-calendar는 CJS default-class. Deno의 CJS interop에서 default가
// 네임스페이스로 잡히는 타입 이슈가 있어, 사용하는 메서드만 인터페이스로 고정 후 1회 캐스팅.
interface LunarCalendar {
  setLunarDate(y: number, m: number, d: number, isIntercalation: boolean): boolean;
  setSolarDate(y: number, m: number, d: number): boolean;
  getSolarCalendar(): { year: number; month: number; day: number };
  getGapja(): { year: string; month: string; day: string };
}
const LunarCalendarCtor = KLCDefault as unknown as { new (): LunarCalendar };

/** 음양력 변환기 인스턴스 (테스트의 교차검증에서도 재사용) */
export function newLunarCalendar(): LunarCalendar {
  return new LunarCalendarCtor();
}

/** 천간 10 (한글) — 인덱스 = 동물 매핑 키 */
export const STEMS = ["갑", "을", "병", "정", "무", "기", "경", "신", "임", "계"] as const;
/** 지지 12 (한글) — 일주 갑자 문자열 구성용 */
export const BRANCHES = ["자", "축", "인", "묘", "진", "사", "오", "미", "신", "유", "술", "해"] as const;

/** 천간(일간) → animal_id (§12, DB animals.id와 동일) */
export const STEM_TO_ANIMAL: Record<string, string> = {
  "갑": "gapmok", // 사슴
  "을": "eulmok", // 토끼
  "병": "byeonghwa", // 사자
  "정": "jeonghwa", // 여우
  "무": "muto", // 곰
  "기": "gito", // 카피바라
  "경": "gyeonggeum", // 호랑이
  "신": "singeum", // 고양이
  "임": "imsu", // 고래
  "계": "gyesu", // 수달
};

export type CalendarType = "solar" | "lunar";

export interface SajuResult {
  /** 일주 갑자 (예: "갑자") — 해시 입력 계약의 일부, 절대 형식 변경 금지 */
  dayPillar: string;
  /** 일간 (천간 한글, 예: "갑") */
  dayStem: string;
  /** 배정 동물 id (불변, D1) */
  animalId: string;
  /** 변환·정규화된 양력 날짜 (YYYY-MM-DD) */
  solarDate: string;
}

/** 양력(proleptic Gregorian) → JDN. Fliegel–Van Flandern. */
export function julianDayNumber(year: number, month: number, day: number): number {
  const a = Math.floor((14 - month) / 12);
  const y = year + 4800 - a;
  const m = month + 12 * a - 3;
  return (
    day +
    Math.floor((153 * m + 2) / 5) +
    365 * y +
    Math.floor(y / 4) -
    Math.floor(y / 100) +
    Math.floor(y / 400) -
    32045
  );
}

/** JDN → 60갑자 인덱스 (0 = 갑자, anchor 2024-01-01) */
export function ganjiIndex(jdn: number): number {
  return (((jdn + 49) % 60) + 60) % 60;
}

/** 양력 날짜 → 일주 정보 (천간/지지/갑자) */
export function dayPillarFromSolar(year: number, month: number, day: number): {
  dayPillar: string;
  dayStem: string;
} {
  const gi = ganjiIndex(julianDayNumber(year, month, day));
  const stem = STEMS[gi % 10];
  const branch = BRANCHES[gi % 12];
  return { dayPillar: stem + branch, dayStem: stem };
}

function pad2(n: number): string {
  return String(n).padStart(2, "0");
}

/**
 * 생년월일(+달력 종류) → 사주 일간 + 동물 배정.
 * @param isLeapMonth 음력 윤달 여부 (양력 입력에서는 무시)
 */
export function computeSaju(
  birthDate: string, // "YYYY-MM-DD" (입력 달력 기준)
  calendarType: CalendarType,
  isLeapMonth = false,
): SajuResult {
  const m = birthDate.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (!m) throw new Error(`invalid birthDate format: ${birthDate}`);
  let year = Number(m[1]);
  let month = Number(m[2]);
  let day = Number(m[3]);

  if (calendarType === "lunar") {
    const cal = newLunarCalendar();
    const ok = cal.setLunarDate(year, month, day, isLeapMonth);
    if (!ok) {
      throw new Error(
        `lunar date out of range or invalid: ${birthDate} (leap=${isLeapMonth})`,
      );
    }
    const s = cal.getSolarCalendar();
    year = s.year;
    month = s.month;
    day = s.day;
  }

  const { dayPillar, dayStem } = dayPillarFromSolar(year, month, day);
  const animalId = STEM_TO_ANIMAL[dayStem];
  if (!animalId) throw new Error(`no animal mapping for stem: ${dayStem}`);

  return {
    dayPillar,
    dayStem,
    animalId,
    solarDate: `${year}-${pad2(month)}-${pad2(day)}`,
  };
}
