/// 한국어 조사 자동 선택 — 받침(종성) 유무로 을/를·이/가·은/는·와/과 결정.
/// 'XX을(를)' 같은 노출 방지. v1 아이템명은 한글이라 한글 음절만 판정(비한글은 받침 없음 취급).
bool _hasBatchim(String s) {
  if (s.isEmpty) return false;
  final c = s.codeUnitAt(s.length - 1);
  if (c < 0xAC00 || c > 0xD7A3) return false; // 비한글: 보수적으로 받침 없음
  return (c - 0xAC00) % 28 != 0; // 종성 인덱스 != 0 → 받침 있음
}

String josaEulReul(String w) => _hasBatchim(w) ? '을' : '를';
String josaIGa(String w) => _hasBatchim(w) ? '이' : '가';
String josaEunNeun(String w) => _hasBatchim(w) ? '은' : '는';
String josaWaGwa(String w) => _hasBatchim(w) ? '과' : '와';
