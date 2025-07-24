import 'package:flutter/material.dart';

/// 역할별 상태 → 한글 라벨 변환
String getStatusLabelForRole(String role, String status) {
  const common = {
    'pending': '수거 요청',
    'accepted': '수거 대기',
    'transit': '배송중',
    'completed': '배송 완료',
    'denied': '거절',
  };

  const preprocessor = {
    'pending': '입고',
    'accepted': '작업중',
    'completed': '작업 완료',
  };

  if (role == 'preprocessor') {
    return preprocessor[status] ?? status;
  }

  // 기본: 농가, 배송사
  return common[status] ?? status;
}

/// 역할별 상태 → 날짜 라벨 해석
String getDateLabelForRole(String role, String status) {
  if (role == 'preprocessor') {
    if (status == 'pending') return '입고일';
    if (status == 'accepted') return '작업 시작일';
    if (status == 'completed') return '작업 완료일';
  }

  // 농가, 배송사 공통
  else {
    if (status == 'pending' || status == 'accepted') return '수거 요청일';
    if (status == 'transit') return '배송 시작일';
    if (status == 'completed') return '배송 완료일';
    if (status == 'denied') return '거절일';
  }
  return '날짜';
}


/* 농가 */
IconData getStatusIcon(String status) {
  switch (status) {
    case "추가": return Icons.add;
    case "수거": return Icons.local_shipping;
    case "폐기": return Icons.delete;
    default: return Icons.help_outline;
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case "추가": return Colors.green;
    case "폐기": return Colors.red;
    case "수거": return Colors.blue;
    default: return Colors.grey;
  }
}


/// 진행률에 따른 색상 및 상태 관리
Color getProgressColor(double percent) {
  if (percent >= 0.9) return Colors.red.shade600;
  if (percent >= 0.7) return Colors.orange.shade600;
  if (percent >= 0.5) return Colors.yellow.shade700;
  return Colors.green.shade600;
}

Color getBackgroundColor(double percent) {
  if (percent >= 0.9) return Colors.red.shade50;
  if (percent >= 0.7) return Colors.orange.shade50;
  if (percent >= 0.5) return Colors.yellow.shade50;
  return Colors.green.shade50;
}

IconData getStatusIcon_Progress(double percent) {
  if (percent >= 0.9) return Icons.warning_rounded;
  if (percent >= 0.7) return Icons.trending_up_rounded;
  if (percent >= 0.5) return Icons.info_outline_rounded;
  return Icons.check_circle_outline_rounded;
}

String getStatusText(double percent) {
  if (percent >= 0.9) return "위험";
  if (percent >= 0.7) return "주의";
  if (percent >= 0.5) return "보통";
  return "안전";
}

int getStatusPriority(double percent) {
  if (percent >= 0.9) return 4;
  if (percent >= 0.7) return 3;
  if (percent >= 0.5) return 2;
  return 1;
}

