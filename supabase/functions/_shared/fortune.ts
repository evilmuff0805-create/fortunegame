// 일일 운세 단일 경로 (③): 등급 계산→저장→재사용을 한 곳에서.
// today-fortune·open-pack 모두 이 함수만 거치므로 두 엔드포인트가 절대 갈리지 않는다.
// 등급 계산은 오직 computeFortune(_shared/grade.ts) 하나, 그리고 한 번만 계산해 저장한다.

import { type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { type CategoryScores, computeFortune, type FortuneGrade } from "./grade.ts";

export interface DailyFortune {
  grade: FortuneGrade;
  scores: CategoryScores;
  messageId: string | null;
  message: string | null;
  openedAt: string | null;
  rewardItemId: string | null;
}

async function findMessage(
  admin: SupabaseClient,
  dateKst: string,
  animalId: string,
  grade: string,
): Promise<{ id: string; body: string } | null> {
  const { data } = await admin
    .from("fortune_msgs")
    .select("id, body")
    .eq("date", dateKst)
    .eq("animal_id", animalId)
    .eq("grade", grade)
    .maybeSingle();
  return data;
}

/**
 * 오늘(KST) 운세 행을 보장한다. 있으면 그대로(등급 불변), 없으면 단일 함수로 계산해 INSERT.
 * 메시지가 비어 있으면(배치 지연) 채워지는 대로 보강.
 */
export async function ensureDailyFortune(
  admin: SupabaseClient,
  userId: string,
  dayPillar: string,
  animalId: string,
  dateKst: string,
): Promise<DailyFortune> {
  const { data: existing } = await admin
    .from("daily_fortunes")
    .select("grade, category_scores, message_id, opened_at, reward_item_id")
    .eq("user_id", userId)
    .eq("date", dateKst)
    .maybeSingle();

  if (existing) {
    let messageId = existing.message_id as string | null;
    let message: string | null = null;
    if (messageId) {
      const { data } = await admin
        .from("fortune_msgs").select("body").eq("id", messageId).maybeSingle();
      message = data?.body ?? null;
    } else {
      const m = await findMessage(admin, dateKst, animalId, existing.grade);
      if (m) {
        messageId = m.id;
        message = m.body;
        await admin.from("daily_fortunes").update({ message_id: m.id })
          .eq("user_id", userId).eq("date", dateKst);
      }
    }
    return {
      grade: existing.grade,
      scores: existing.category_scores,
      messageId,
      message,
      openedAt: existing.opened_at,
      rewardItemId: existing.reward_item_id,
    };
  }

  // 신규 — 등급은 단일 함수로 한 번만 계산(③)
  const { grade, scores } = await computeFortune(dayPillar, dateKst);
  const m = await findMessage(admin, dateKst, animalId, grade);
  const { error } = await admin.from("daily_fortunes").insert({
    user_id: userId,
    date: dateKst,
    grade,
    category_scores: scores,
    message_id: m?.id ?? null,
  });
  if (error) throw new Error(`daily_fortunes insert: ${error.message}`);
  return {
    grade,
    scores,
    messageId: m?.id ?? null,
    message: m?.body ?? null,
    openedAt: null,
    rewardItemId: null,
  };
}
