//공통테마(색상과 텍스트스타일)를 정의해놓은 파일입니다
//색상은 적용해놨고 텍스트스타일은 아직 각 페이지에 적용은 하지 않았습니다. 

import 'package:flutter/material.dart';

/// 공통 색상 정의
class AppColors {
  static const Color primaryBrown = Color(0xFF5C4B3C);
  static const Color lightBrown = Color(0xFFBCAAA4);
  static const Color darkBrown = Color(0xFF5D4037);
  static const Color accentBrown = Color(0xFFD7CCC8);
  static const Color backgroundBrown = Color(0xFFF5F5F5);
}

/// 공통 텍스트 스타일 정의
class AppTextStyles {
  /// 1. 홈 화면 최상단 제목 ('전처리사 홈' 같은 큰 흰 글씨)
  static const TextStyle homeTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// 2. 탭 제목 ('입고', '작업중', '작업완료')
  static const TextStyle tabLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.lightBrown,
  );

  /// 선택된 탭 제목 스타일 (선택 시 흰색)
  static const TextStyle tabLabelSelected = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// 3. 카드 제목 ('배추 (수확) 30kg')
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );

  /// 4. 카드 내부 작은 정보 텍스트 (입고일, 상태 등)
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    height: 1.4,
    color: AppColors.darkBrown,
  );

  /// 5. 버튼 텍스트 (흰색, bold)
  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}