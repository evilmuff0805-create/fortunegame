// today-fortune — 오늘(KST) 봉투 상태 + 누설 티어.
// ①: 미개봉이면 등급 전체를 내리지 않고 '누설 티어'(rainbow/radiant/none)만 노출 →
//     비/흐림/갬/맑음은 개봉 전 전부 'none'으로 동일 → "나쁜 날 골라 안 열기" 불가.
// 등급·보상 확정은 open-pack 서버에서만. D4 기록(daily_fortunes)은 여기서 보장.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";
import { ensureDailyFortune } from "../_shared/fortune.ts";
import { leakTier } from "../_shared/reward.ts";
import { kstDateString } from "../_shared/kst.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "missing authorization" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabase = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: authErr } = await supabase.auth.getUser();
  if (authErr || !user) return json({ error: "invalid token" }, 401);

  const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: urow, error: uerr } = await supabase
    .from("users").select("animal_id, saju_pillars").eq("id", user.id).single();
  if (uerr || !urow) return json({ error: "user profile not found" }, 404);

  const dayPillar = (urow.saju_pillars as { day?: string })?.day;
  if (!dayPillar) return json({ error: "saju_pillars.day missing" }, 422);

  const dateKst = kstDateString();
  let df;
  try {
    df = await ensureDailyFortune(admin, user.id, dayPillar, urow.animal_id, dateKst);
  } catch (e) {
    return json({ error: String((e as Error).message ?? e) }, 500);
  }

  const opened = !!df.openedAt;
  // 미개봉: 누설 티어만. 개봉됨: 이미 본 카드라 전체 공개해도 됨(악용 무관).
  return json({
    date: dateKst,
    animalId: urow.animal_id,
    opened,
    leak: leakTier(df.grade),
    ...(opened
      ? { grade: df.grade, scores: df.scores, message: df.message, rewardItemId: df.rewardItemId }
      : {}),
  });
});
