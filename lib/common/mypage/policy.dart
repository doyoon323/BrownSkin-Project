import 'package:flutter/material.dart';

import '../themes.dart';

class PolicyListPage extends StatelessWidget {
  const PolicyListPage({super.key});


  static const Color lightbackgroundBrown = Color(0xFF433228);
  static const Color backgroundBrown = Color(0xFFD7CCC8);
  static const Color cardBrown = Color(0xFFEFEBE9);

  @override
  Widget build(BuildContext context) {
    final policies = [
      {
        'title': '서비스 이용약관',
        'content': _termsOfService,
      },
      {
        'title': '개인정보 처리방침',
        'content': _privacyPolicy,
      },
      {
        'title': '운영정책',
        'content': _operationPolicy,
      },
      {
        'title': '위치기반서비스이용약관',
        'content': _locationTerms,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: backgroundBrown,
        elevation: 0,
        title: const Text('약관 및 정책', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: backgroundBrown,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: policies.length,
        itemBuilder: (_, index) {
          final policy = policies[index];
          return _buildMenuItem(
            icon: Icons.description_outlined,
            title: policy['title']!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PolicyDetailPage(
                    title: policy['title']!,
                    content: policy['content']!,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }



  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: lightbackgroundBrown.withOpacity(0.2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                lightbackgroundBrown.withOpacity(0.2),
                lightbackgroundBrown.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cardBrown.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.description_outlined,
            color: cardBrown,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.black54,
            letterSpacing: 0.3,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightbackgroundBrown.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.chevron_right,
            color: cardBrown,
            size: 20,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hoverColor: lightbackgroundBrown.withOpacity(0.1),
        splashColor: cardBrown.withOpacity(0.1),
      ),
    );
  }
}

class PolicyDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const PolicyDetailPage({
    super.key,
    required this.title,
    required this.content,
  });
  static const Color backgroundBrown = Color(0xFFD7CCC8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBrown,
        foregroundColor: backgroundBrown,
        elevation: 0,
      ),
      backgroundColor: backgroundBrown,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
      ),
    );
  }
}


const String _termsOfService = '''
제1조 (목적)
이 약관은 “브라운스킨 앱”(이하 "서비스")의 이용조건 및 절차, 회원과 회사 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "회사"란 본 서비스를 운영하는 주체를 말합니다.
2. "회원"이란 본 약관에 따라 회사와 이용계약을 체결한 자를 말합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 서비스 화면에 게시함으로써 효력을 발생합니다.
2. 회사는 필요한 경우 약관을 변경할 수 있으며, 변경된 약관은 공지 후 7일 이후부터 효력이 발생합니다.

제4조 (회원가입)
1. 사용자는 서비스가 정한 양식에 따라 정보를 입력하여 회원가입을 신청합니다.
2. 회사는 신청자에게 승낙함으로써 회원가입이 완료됩니다.

제5조 (서비스 이용)
1. 회사는 회원에게 다음과 같은 서비스를 제공합니다:
   - 상품 조회 및 신청
   - 알림 기능
   - 마이페이지 및 정보 수정

제6조 (회원의 의무)
1. 회원은 다음 행위를 해서는 안 됩니다:
   - 타인의 정보 도용
   - 회사의 서비스 운영을 방해하는 행위
   - 법령 및 공서양속에 반하는 행위

제7조 (면책조항)
1. 회사는 천재지변, 불가항력 등으로 인한 서비스 제공 불가에 대해 책임을 지지 않습니다.

제8조 (준거법 및 관할)
1. 본 약관은 대한민국 법령에 따르며, 분쟁 발생 시 회사의 본사 소재지 관할 법원을 제1심 관할 법원으로 합니다.
''';

const String _privacyPolicy = '''
1. 수집하는 개인정보 항목
- 필수 항목: 이름, 이메일, 휴대전화번호, 주소
- 선택 항목: 프로필 사진, 서비스 사용 기록

2. 개인정보 수집 목적
- 회원 식별 및 인증
- 서비스 제공 및 맞춤형 콘텐츠 제공
- 고객 문의 응대 및 공지사항 전달

3. 보유 및 이용기간
- 회원 탈퇴 시까지 또는 관계법령에 따른 보관 기간까지

4. 개인정보 제3자 제공
- 회사는 원칙적으로 이용자의 동의 없이 개인정보를 외부에 제공하지 않습니다.

5. 개인정보 처리 위탁
- 서비스 운영을 위해 다음 업체에 위탁할 수 있습니다:
  예: Amazon Web Services (서버 운영), Google Analytics (통계 분석)

6. 이용자의 권리
- 이용자는 개인정보 열람, 정정, 삭제, 처리 정지를 요구할 수 있습니다.

''';

const String _locationTerms = '''
제1조 (목적)
본 약관은 회사가 제공하는 위치기반서비스의 이용조건 및 절차, 권리·의무를 규정합니다.

제2조 (서비스 내용)
회사는 아래와 같은 위치기반 서비스를 제공합니다:
- 주변 업체 추천
- 위치 기반 알림
- 이용자 위치 분석을 통한 마케팅 제공

제3조 (이용자의 권리)
이용자는 위치정보 수집·이용·제공에 대해 동의하지 않을 수 있으며, 동의는 언제든 철회할 수 있습니다.

제4조 (보유 및 이용기간)
수집된 위치정보는 서비스 제공 목적 달성 후 즉시 파기됩니다.

''';

const String _operationPolicy = '''
1. 커뮤니티 운영 원칙
- 이용자는 타인의 권리를 침해하지 않으며, 허위정보 및 광고를 게재하지 않아야 합니다.

2. 제재 기준
- 욕설, 혐오표현, 음란물: 경고 없이 삭제 및 일정 기간 정지
- 반복적 불법 행위: 영구 이용 제한

3. 신고 절차
- 이용자는 부적절한 콘텐츠를 신고할 수 있으며, 회사는 최대 24시간 내에 조치합니다.

4. 기타
- 운영정책은 서비스 안정성과 사용자 보호를 위해 수시로 변경될 수 있습니다.
''';