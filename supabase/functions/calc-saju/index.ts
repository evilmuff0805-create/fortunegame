// calc-saju — 생년월일(양/음) → 사주 일간 + 동물 배정 (D7) + 프로필 생성.
// 서버 권위(D1/D7): 동물 계산과 users 행 쓰기를 모두 서버가 한다. 클라이언트는 animal_id를
// 위조할 수 없다(users INSERT는 service-role 전용 RLS). JWT 필수.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";
import { type CalendarType, computeSaju } from "../_shared/saju.ts";

interface Body {
  birthDate: string; // YYYY-MM-DD (입력 달력 기준)
  calendarType?: CalendarType; // default solar
  isLeapMonth?: boolean; // 음력 윤달
  birthTime?: string | null; // "HH:MM" 선택 (상세 운세용, v1 미사용)
  gender?: string | null; // 선택
}

function isValidTime(t: string): boolean {
  return /^([01]\d|2[0-3]):[0-5]\d$/.test(t);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "missing authorization" }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  // JWT 검증 (익명 포함 — 인증된 호출만 허용)
  const supabase = createClient(
    supabaseUrl,
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
  if (body.birthTime && !isValidTime(body.birthTime)) {
    return json({ error: "birthTime must be HH:MM" }, 400);
  }

  let saju;
  try {
    saju = computeSaju(
      body.birthDate,
      body.calendarType ?? "solar",
      body.isLeapMonth ?? false,
    );
  } catch (e) {
    return json({ error: String((e as Error).message ?? e) }, 422);
  }

  const sajuPillars = {
    day: saju.dayPillar, // 일주 갑자 (해시 입력 계약)
    dayStem: saju.dayStem,
    solarDate: saju.solarDate, // 변환된 양력 (음력 입력 시 유용)
  };

  // 서버 권위 쓰기: service-role로 users upsert. animal_id 불변 트리거가 재배정을 막으므로
  // 이미 프로필이 있으면(동물 확정) 동물은 그대로 유지된다 (D1).
  const admin = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: existing } = await admin
    .from("users")
    .select("animal_id")
    .eq("id", user.id)
    .maybeSingle();

  if (existing) {
    // 이미 배정됨 — 동물 불변(D1). 재계산 동물이 달라도 기존 동물을 반환.
    return json({
      animalId: existing.animal_id,
      sajuPillars,
      alreadyAssigned: true,
    });
  }

  const { error: insErr } = await admin.from("users").insert({
    id: user.id,
    birth_date: body.birthDate, // 입력 원본 (calendar_type과 함께 해석). 양력 변환본은 saju_pillars.solarDate
    birth_time: body.birthTime ?? null,
    calendar_type: body.calendarType ?? "solar",
    gender: body.gender ?? null,
    saju_pillars: sajuPillars,
    animal_id: saju.animalId,
    auth_provider: user.is_anonymous ? "anonymous" : (user.app_metadata?.provider ?? null),
  });
  if (insErr) return json({ error: `profile create failed: ${insErr.message}` }, 500);

  return json({ animalId: saju.animalId, sajuPillars, alreadyAssigned: false });
});
