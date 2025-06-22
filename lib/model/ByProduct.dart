class ByProduct {
  final String username;
  final String email;
  final String company_name;
  final String address;
  final String role;

  final double weight;
  final bool is_above_threshold;

  ByProduct({
    required this.username,
    required this.email,
    required this.company_name,
    required this.address,
    required this.role,
    required this.weight,
    required this.is_above_threshold,
  });

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