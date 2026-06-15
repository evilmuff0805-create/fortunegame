// KST(UTC+9) 날짜 경계 (D10: 날짜 경계 = KST 자정).
// 서버는 UTC로 동작하므로 +9h 한 뒤 날짜 부분만 취한다 (KST엔 DST 없음).

export function kstDateString(now: Date = new Date()): string {
  const kst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return kst.toISOString().slice(0, 10); // YYYY-MM-DD
}

/** 어제(KST) — 배치 폴백용 */
export function kstYesterdayString(now: Date = new Date()): string {
  return kstDateString(new Date(now.getTime() - 24 * 60 * 60 * 1000));
}
