// open-pack — 봉투 개봉(서버 권위, 결정 1). 찢기 완료 시 클라이언트가 호출.
// 원자·멱등: opened_at을 'is null'일 때만 갱신(경쟁/재호출 안전) → 보상·스트릭은 최초 1회만.
// 등급은 ensureDailyFortune(단일 경로)에서 가져오고 새로 뽑지 않는다(③).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";
import { ensureDailyFortune } from "../_shared/fortune.ts";
import { GRADE_REWARD } from "../_shared/reward.ts";
import { nextStreak, type StreakState } from "../_shared/streak.ts";
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

  const rewardItemId = GRADE_REWARD[df.grade];

  // 원자·멱등 개봉: opened_at이 null일 때만 set. 이긴 호출만 보상·스트릭을 처리.
  const nowIso = new Date().toISOString();
  const { data: won } = await admin
    .from("daily_fortunes")
    .update({ opened_at: nowIso, reward_item_id: rewardItemId })
    .eq("user_id", user.id)
    .eq("date", dateKst)
    .is("opened_at", null)
    .select("date")
    .maybeSingle();
  const justOpened = !!won;

  if (justOpened) {
    if (rewardItemId) {
      await admin.from("inventory").upsert(
        { user_id: user.id, item_id: rewardItemId, source: "reward" },
        { onConflict: "user_id,item_id", ignoreDuplicates: true },
      );
    }
    const { data: prev } = await admin
      .from("streaks")
      .select("current, longest, last_opened_date")
      .eq("user_id", user.id)
      .maybeSingle();
    const prevState: StreakState | null = prev
      ? { current: prev.current, longest: prev.longest, lastOpenedDate: prev.last_opened_date }
      : null;
    const ns = nextStreak(prevState, dateKst);
    await admin.from("streaks").upsert({
      user_id: user.id,
      current: ns.current,
      longest: ns.longest,
      last_opened_date: ns.lastOpenedDate,
    }, { onConflict: "user_id" });
  }

  // 최종 스트릭 조회 (멱등: 이미 열린 경우도 현재 값 반환)
  const { data: streakRow } = await admin
    .from("streaks").select("current, longest").eq("user_id", user.id).maybeSingle();

  return json({
    date: dateKst,
    animalId: urow.animal_id,
    grade: df.grade,
    scores: df.scores,
    message: df.message,
    rewardItemId,
    streak: { current: streakRow?.current ?? 1, longest: streakRow?.longest ?? 1 },
    justOpened,
  });
});
