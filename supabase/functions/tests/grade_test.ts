// 결정론 + 분포 검증 (todo Slice 1, D8/D10).

import { assert, assertEquals } from "std/assert";
import {
  computeFortune,
  type FortuneGrade,
  GRADE_DISTRIBUTION,
  hashInput,
} from "../_shared/grade.ts";

// 결정론: 동일 입력 1,000회 = 동일 출력 (재개봉·기기변경 불변)
Deno.test("결정론: 동일 입력 1000회 동일 등급·점수", async () => {
  const first = await computeFortune("갑자", "2026-06-15");
  for (let i = 0; i < 1000; i++) {
    const r = await computeFortune("갑자", "2026-06-15");
    assertEquals(r.grade, first.grade);
    assertEquals(r.scores, first.scores);
  }
});

// 해시 입력 계약 동결 확인 (형식이 바뀌면 과거 운세가 깨짐)
Deno.test("해시 입력 계약 형식 고정", () => {
  assertEquals(hashInput("갑자", "2026-06-15"), "갑자|2026-06-15");
});

// 분포: 10만 샘플 ≈ §4.1 (1/3/24/32/25/15%)
Deno.test("분포: 10만 샘플이 목표 분포에 수렴 (±0.7%p)", async () => {
  const N = 100_000;
  const counts: Record<FortuneGrade, number> = {
    rainbow: 0, radiant: 0, sunny: 0, calm: 0, cloudy: 0, rainy: 0,
  };
  // 다양한 (일주,날짜) 입력으로 샘플 — 결정론이므로 결과는 고정
  const pillars = ["갑자", "을축", "병인", "정묘", "무진"];
  let n = 0;
  for (let day = 0; n < N; day++) {
    const date = new Date(Date.UTC(2000, 0, 1) + day * 86400000);
    const ds = date.toISOString().slice(0, 10);
    for (const p of pillars) {
      if (n >= N) break;
      const { grade } = await computeFortune(p, ds);
      counts[grade]++;
      n++;
    }
  }
  for (const { grade, p } of GRADE_DISTRIBUTION) {
    const actual = counts[grade] / N;
    const diff = Math.abs(actual - p);
    console.log(`${grade}: 목표 ${(p * 100).toFixed(0)}% 실제 ${(actual * 100).toFixed(2)}% (Δ${(diff * 100).toFixed(2)}%p)`);
    assert(diff < 0.007, `${grade} 분포 이탈: Δ${(diff * 100).toFixed(2)}%p`);
  }
});

// 점수 범위 (1~100 클램프, 등급별 기준선 차등)
Deno.test("카테고리 점수 1~100, 좋은 등급일수록 평균 높음", async () => {
  const sumByGrade: Record<string, { sum: number; n: number }> = {};
  for (let day = 0; day < 2000; day++) {
    const ds = new Date(Date.UTC(2024, 0, 1) + day * 86400000).toISOString().slice(0, 10);
    const r = await computeFortune("갑자", ds);
    for (const v of Object.values(r.scores)) {
      assert(v >= 1 && v <= 100, `점수 범위 이탈: ${v}`);
    }
    const g = r.grade;
    sumByGrade[g] ??= { sum: 0, n: 0 };
    const avg = (r.scores.wealth + r.scores.love + r.scores.health + r.scores.work) / 4;
    sumByGrade[g].sum += avg;
    sumByGrade[g].n += 1;
  }
  const rainyAvg = sumByGrade["rainy"].sum / sumByGrade["rainy"].n;
  const sunnyAvg = sumByGrade["sunny"].sum / sumByGrade["sunny"].n;
  assert(sunnyAvg > rainyAvg, `맑음(${sunnyAvg.toFixed(1)})이 비(${rainyAvg.toFixed(1)})보다 높아야`);
});
