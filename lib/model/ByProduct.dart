/* 서버로부터 받은 부산물 항목을 구조화한 모델 클래스 */
class ByProduct {
  /* 사용자 정보 */
  final String username;
  final String email;
  final String company_name;
  final String address;
  final String role;

  /* 무게 정보 */
  final double weight;
  final bool is_above_threshold; //임계값 초과 여부

  ByProduct({
    required this.username,
    required this.email,
    required this.company_name,
    required this.address,
    required this.role,
    required this.weight,
    required this.is_above_threshold,
  });


  //JSON 데이터 -> ByProduct 객체
  factory ByProduct.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};

    return ByProduct(
      username: user['username'] ?? '',
      email: user['email'] ?? '',
      company_name: user['company_name'] ?? '',
      address: user['address'] ?? '',
      role: user['role'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      is_above_threshold: json['is_above_threshold'] ?? false,
    );
  }
}