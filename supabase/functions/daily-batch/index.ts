// daily-batch — 매일 자정(00:05 KST) 운세 메시지 60개 생성 (동물 10 × 등급 6).
// LLM(Claude Haiku) 1회 호출/조합. 사용자별 생성 금지(원가 고정, D10).
// 실패 폴백: 전일 메시지 복사 + 로그 (사용자에게 빈 화면 금지).
// service-role 전용 — cron 또는 관리자만 호출.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { json } from "../_shared/cors.ts";
import { type FortuneGrade } from "../_shared/grade.ts";
import { kstDateString, kstYesterdayString } from "../_shared/kst.ts";
import { buildSystemPrompt, buildUserPrompt, violatesTone } from "../_shared/prompt.ts";

const GRADES: FortuneGrade[] = ["rainbow", "radiant", "sunny", "calm", "cloudy", "rainy"];
const MODEL = "claude-haiku-4-5";

interface AnimalRow {
  id: string;
  name: string;
  element: string;
  personality: string;
}

// 톤 검증 재시도 횟수. 초과하면 마지막 결과를 그대로 통과(무한 루프·토큰 낭비 방지).
const MAX_TONE_RETRIES = 3;

/** Anthropic 1회 호출 (HTTP 오류는 throw → 상위에서 전일 폴백 처리) */
async function callLLM(
  apiKey: string,
  animal: AnimalRow,
  grade: FortuneGrade,
): Promise<string> {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 300,
      system: buildSystemPrompt(),
      messages: [{
        role: "user",
        content: buildUserPrompt({
          animalName: animal.name,
          element: animal.element,
          personality: animal.personality,
          grade,
        }),
      }],
    }),
  });
  if (!res.ok) {
    throw new Error(`anthropic ${res.status}: ${(await res.text()).slice(0, 200)}`);
  }
  const data = await res.json();
  return (data.content?.[0]?.text ?? "").trim();
}

interface GenResult {
  body: string;
  degraded: boolean; // 톤 검증 통과 못 했지만 폴백으로 통과시킨 경우
  issue: string | null; // degraded일 때 마지막 위반 사유
}

/**
 * 톤 검증을 통과할 때까지 최대 MAX_TONE_RETRIES회 재시도.
 * 초과하면 마지막 결과를 통과시키고 degraded=true로 로그를 남긴다.
 * (단 빈 응답은 통과 불가 → throw → 상위 전일 폴백)
 */
async function generateBody(
  apiKey: string,
  animal: AnimalRow,
  grade: FortuneGrade,
): Promise<GenResult> {
  let last = "";
  let lastIssue: string | null = null;
  for (let attempt = 0; attempt <= MAX_TONE_RETRIES; attempt++) {
    const text = await callLLM(apiKey, animal, grade);
    const bad = violatesTone(text);
    if (!bad) return { body: text, degraded: false, issue: null };
    last = text;
    lastIssue = bad;
  }
  if (!last) throw new Error("empty result after retries");
  console.warn(
    `tone retry exhausted (${animal.id}/${grade}): "${lastIssue}" — 마지막 결과 통과: ${last.slice(0, 60)}`,
  );
  return { body: last, degraded: true, issue: lastIssue };
}

/** Bearer JWT의 role 클레임 추출 (서명 검증은 플랫폼 verify_jwt가 이미 수행) */
function jwtRole(authHeader: string): string | null {
  const m = authHeader.match(/^Bearer\s+(.+)$/);
  if (!m) return null;
  const parts = m[1].split(".");
  if (parts.length !== 3) return null;
  try {
    const payload = JSON.parse(
      atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")),
    );
    return payload.role ?? null;
  } catch {
    return null;
  }
}

Deno.serve(async (req) => {
  // service-role 전용 (cron은 Authorization: Bearer <service_role>).
  // 정확한 키 문자열 대신 role 클레임으로 판정 — legacy/신규 키 포맷 차이에 견고.
  const auth = req.headers.get("Authorization") ?? "";
  if (jwtRole(auth) !== "service_role") {
    return json({ error: "forbidden: service role only" }, 403);
  }

  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey);
  const url = new URL(req.url);
  const date = url.searchParams.get("date") ?? kstDateString();
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");

  const { data: animals, error: aerr } = await supabase
    .from("animals")
    .select("id, name, element, personality");
  if (aerr || !animals) return json({ error: `animals load: ${aerr?.message}` }, 500);

  // 이미 존재하는 (animal,grade) 건너뛰기 (재실행 안전)
  const { data: existing } = await supabase
    .from("fortune_msgs")
    .select("animal_id, grade")
    .eq("date", date);
  const have = new Set((existing ?? []).map((e) => `${e.animal_id}:${e.grade}`));

  const rows: { date: string; animal_id: string; grade: string; body: string }[] = [];
  const errors: string[] = [];
  const degraded: string[] = []; // 톤 재시도 초과로 통과시킨 항목 (검수 우선 대상)

  if (!apiKey) {
    return json({ error: "ANTHROPIC_API_KEY not set — 배치 보류" }, 503);
  }

  for (const animal of animals as AnimalRow[]) {
    for (const grade of GRADES) {
      if (have.has(`${animal.id}:${grade}`)) continue;
      try {
        const r = await generateBody(apiKey, animal, grade);
        rows.push({ date, animal_id: animal.id, grade, body: r.body });
        if (r.degraded) degraded.push(`${animal.id}/${grade}: ${r.issue}`);
      } catch (e) {
        errors.push(`${animal.id}/${grade}: ${(e as Error).message}`);
      }
    }
  }

  if (rows.length > 0) {
    const { error: insErr } = await supabase.from("fortune_msgs").insert(rows);
    if (insErr) return json({ error: `insert: ${insErr.message}`, errors }, 500);
  }

  // 폴백: 생성 실패분은 전일 메시지를 복사해 빈칸 방지
  let fallbackCopied = 0;
  if (errors.length > 0) {
    const yesterday = kstYesterdayString(new Date(`${date}T12:00:00Z`));
    const { data: prev } = await supabase
      .from("fortune_msgs")
      .select("animal_id, grade, body")
      .eq("date", yesterday);
    const stillMissing: typeof rows = [];
    const nowHave = new Set([...have, ...rows.map((r) => `${r.animal_id}:${r.grade}`)]);
    for (const p of prev ?? []) {
      const key = `${p.animal_id}:${p.grade}`;
      if (!nowHave.has(key)) {
        stillMissing.push({ date, animal_id: p.animal_id, grade: p.grade, body: p.body });
      }
    }
    if (stillMissing.length > 0) {
      const { error } = await supabase.from("fortune_msgs").insert(stillMissing);
      if (!error) fallbackCopied = stillMissing.length;
    }
    console.error(`daily-batch ${date}: ${errors.length} errors, ${fallbackCopied} copied from ${yesterday}`);
  }

  if (degraded.length > 0) {
    console.warn(`daily-batch ${date}: ${degraded.length} degraded (톤 재시도 초과): ${degraded.join("; ")}`);
  }

  return json({
    date,
    generated: rows.length,
    fallbackCopied,
    degraded,
    errors,
    total: rows.length + fallbackCopied,
  });
});
