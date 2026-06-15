// today-fortune — 오늘(KST)의 운세 등급·점수·메시지.
// daily_fortunes upsert(D4: 첫날부터 기록) + fortune_msgs 조인. JWT 필수.
// 개봉(opened_at)은 Slice 3에서 별도 처리 — 여기선 조회/생성만.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";
import { computeFortune } from "../_shared/grade.ts";
import { kstDateString } from "../_shared/kst.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "missing authorization" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authErr } = await supabase.auth.getUser();
  if (authErr || !user) return json({ error: "invalid token" }, 401);

  // 사용자 사주 (RLS로 본인 행만)
  const { data: urow, error: uerr } = await supabase
    .from("users")
    .select("animal_id, saju_pillars")
    .eq("id", user.id)
    .single();
  if (uerr || !urow) return json({ error: "user profile not found" }, 404);

  const dayPillar = (urow.saju_pillars as { day?: string })?.day;
  if (!dayPillar) return json({ error: "saju_pillars.day missing" }, 422);

  const dateKst = kstDateString();
  const { grade, scores } = await computeFortune(dayPillar, dateKst);

  // 이미 기록된 운세가 있으면 그대로 (결정론이라 동일하지만 opened_at 보존)
  const { data: existing } = await supabase
    .from("daily_fortunes")
    .select("grade, category_scores, message_id, opened_at")
    .eq("user_id", user.id)
    .eq("date", dateKst)
    .maybeSingle();

  // 오늘의 메시지 (동물×등급) — 배치가 채워둔 fortune_msgs
  const { data: msg } = await supabase
    .from("fortune_msgs")
    .select("id, body")
    .eq("date", dateKst)
    .eq("animal_id", urow.animal_id)
    .eq("grade", grade)
    .maybeSingle();

  if (!existing) {
    // D4: 첫 조회 시 기록 생성 (opened_at = null = 미개봉)
    const { error: insErr } = await supabase.from("daily_fortunes").insert({
      user_id: user.id,
      date: dateKst,
      grade,
      category_scores: scores,
      message_id: msg?.id ?? null,
    });
    if (insErr) return json({ error: `record failed: ${insErr.message}` }, 500);
  } else if (!existing.message_id && msg?.id) {
    // 조회 시점엔 배치가 늦었다가 이후 채워진 경우 보강
    await supabase
      .from("daily_fortunes")
      .update({ message_id: msg.id })
      .eq("user_id", user.id)
      .eq("date", dateKst);
  }

  return json({
    date: dateKst,
    animalId: urow.animal_id,
    grade,
    scores,
    message: msg?.body ?? null,
    opened: !!existing?.opened_at,
  });
});
