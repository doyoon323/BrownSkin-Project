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
    'accepted': '작업 중',
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
  if (status == 'pending' || status == 'accepted') return '수거 요청일';
  if (status == 'transit') return '배송 시작일';
  if (status == 'completed') return '배송 완료일';
  if (status == 'denied') return '거절일';

  return '날짜';
}
