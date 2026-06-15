// calc-saju — 생년월일(양/음) → 사주 일간 + 동물 배정 (D7).
// 순수 계산기. users 행 생성은 클라이언트가 RLS로 직접(Slice 2). JWT 필수.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";
import { type CalendarType, computeSaju } from "../_shared/saju.ts";

interface Body {
  birthDate: string; // YYYY-MM-DD
  calendarType?: CalendarType; // default solar
  isLeapMonth?: boolean; // 음력 윤달
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "missing authorization" }, 401);

  // JWT 검증 (익명 포함 — 인증된 호출만 허용)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authErr } = await supabase.auth.getUser();
  if (authErr || !user) return json({ error: "invalid token" }, 401);

  let body: Body;
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid json" }, 400);
  }
  if (!body.birthDate) return json({ error: "birthDate required" }, 400);

  try {
    const saju = computeSaju(
      body.birthDate,
      body.calendarType ?? "solar",
      body.isLeapMonth ?? false,
    );
    return json({
      animalId: saju.animalId,
      sajuPillars: {
        day: saju.dayPillar, // 일주 갑자 (해시 입력 계약)
        dayStem: saju.dayStem,
        solarDate: saju.solarDate, // 변환된 양력 (음력 입력 시 유용)
      },
    });
  } catch (e) {
    return json({ error: String((e as Error).message ?? e) }, 422);
  }
});
