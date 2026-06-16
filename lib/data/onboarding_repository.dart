import 'package:supabase_flutter/supabase_flutter.dart';

/// 배정 결과 (calc-saju 응답).
class AssignResult {
  const AssignResult({required this.animalId, required this.alreadyAssigned});
  final String animalId;
  final bool alreadyAssigned;
}

/// 생년월일 입력 → 동물 배정(서버 권위) + 계정 승격 호출을 캡슐화.
class OnboardingRepository {
  OnboardingRepository(this._client);
  final SupabaseClient _client;

  /// calc-saju Edge Function 호출 → users 행 생성(서버) + 동물 반환.
  /// 동물은 서버가 정한다(D7); 이미 배정됐으면 기존 동물 유지(D1).
  Future<AssignResult> assign({
    required String birthDate, // YYYY-MM-DD (입력 달력 기준)
    required String calendarType, // 'solar' | 'lunar'
    bool isLeapMonth = false,
    String? birthTime, // 'HH:MM' 선택
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'birthDate': birthDate,
      'calendarType': calendarType,
      'isLeapMonth': isLeapMonth,
    };
    if (birthTime != null) body['birthTime'] = birthTime;
    if (gender != null) body['gender'] = gender;

    final res = await _client.functions.invoke('calc-saju', body: body);
    final data = res.data;
    if (res.status != 200 || data is! Map || data['animalId'] == null) {
      final msg = (data is Map ? data['error'] : null) ?? 'calc-saju ${res.status}';
      throw Exception('동물 배정 실패: $msg');
    }
    return AssignResult(
      animalId: data['animalId'] as String,
      alreadyAssigned: data['alreadyAssigned'] == true,
    );
  }

  /// 익명 → 이메일 승격: 확인 메일(OTP) 발송. uid는 그대로 유지된다(D1).
  Future<void> sendEmailUpgrade(String email) {
    return _client.auth.updateUser(UserAttributes(email: email));
  }

  /// 이메일 OTP 검증 → 승격 완료.
  Future<void> verifyEmailOtp({required String email, required String token}) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.emailChange,
    );
  }
}
