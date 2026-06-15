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

async function generateBody(
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
  const text = (data.content?.[0]?.text ?? "").trim();
  const bad = violatesTone(text);
  if (bad) throw new Error(`tone check failed (${bad}): ${text.slice(0, 60)}`);
  return text;
}

Deno.serve(async (req) => {
  // service-role 인증 (cron은 Authorization: Bearer <service_role>)
  const auth = req.headers.get("Authorization") ?? "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (auth !== `Bearer ${serviceKey}`) {
    return json({ error: "forbidden: service role only" }, 403);
  }

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

  if (!apiKey) {
    return json({ error: "ANTHROPIC_API_KEY not set — 배치 보류" }, 503);
  }

  for (const animal of animals as AnimalRow[]) {
    for (const grade of GRADES) {
      if (have.has(`${animal.id}:${grade}`)) continue;
      try {
        const body = await generateBody(apiKey, animal, grade);
        rows.push({ date, animal_id: animal.id, grade, body });
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

  return json({
    date,
    generated: rows.length,
    fallbackCopied,
    errors,
    total: rows.length + fallbackCopied,
  });
});
