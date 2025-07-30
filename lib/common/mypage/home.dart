import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/mypage/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/login/login_page.dart';
import 'customer_service.dart';  // ✅ 고객센터 페이지 추가
import '../themes.dart';
import '../widgets.dart';
import 'notice.dart';
import 'policy.dart';

class MyPageScreen extends StatefulWidget {
  final String token;
  const MyPageScreen({super.key, required this.token});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  Map<String, dynamic> userInfo = {};
  bool isLoading = true;
  static const Color mediumbackgroundBrown = Color(0xFF4A3429);
  static const Color lightbackgroundBrown = Color(0xFF433228);
  static const Color cardBrown = Color(0xFFEFEBE9);
  static const Color lightBackground = Color(0xFFF8F6F4);

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final response = await ApiService.fetchMap(
      url: '$BASE_URL/auth/api-profile',
      token: widget.token,
    );
    setState(() {
      userInfo = response;
      isLoading = false;
    });
    if (response.isEmpty) {
      print("프로필 불러오기 실패");
      setState(() {
        isLoading = false;
      });
    }
  }

  String getRoleString(String role) {
    if (role == "disposer") return "분리/배출";
    if (role == "transporter") return "유통";
    if (role == 'preprocessor') return "전처리";
    return "관리자";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: lightBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(cardBrown),
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: buildCustomAppBar(
        context: context,
        title: '마이페이지',
        showBackButton: true,
        showActions: false,
      ),
      body: Column(
        children: [
          /// 상단 프로필 정보 카드 - 흰색 배경에 갈색 테두리
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: lightbackgroundBrown,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: mediumbackgroundBrown.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                /// 좌측 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cardBrown,
                                  cardBrown.withOpacity(0.8),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cardBrown.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: mediumbackgroundBrown.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userInfo['company_name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: mediumbackgroundBrown,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBrown.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: cardBrown.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    "${getRoleString(userInfo['role'] ?? '')} ${userInfo['type'] ?? ''}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: mediumbackgroundBrown,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: lightBackground.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: lightbackgroundBrown.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: mediumbackgroundBrown,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${userInfo['addr1'] ?? ''} ${userInfo['addr2'] ?? ''}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mediumbackgroundBrown.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                /// 우측 정보수정 버튼 - 짙은 갈색 배경에 흰색 텍스트
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: mediumbackgroundBrown.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            Info: userInfo,
                            token: widget.token,
                          ),
                        ),
                      ).then((isUpdated) {
                        if (isUpdated == true) {
                          _fetchUserInfo();
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mediumbackgroundBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.white),
                        const SizedBox(height: 4),
                        Text(
                          '정보수정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          /// 메뉴 리스트 - 큰 컨테이너 제거하고 개별 카드들만
          Expanded(
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: '공지사항',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NoticeListPage(token: widget.token)),
                    );
                  },
                ),
                const SizedBox(height: 12), // 카드 간격
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: '약관 및 정책',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PolicyListPage()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.support_agent,
                  title: '고객센터',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerServicePage(),
                      ),
                    );
                  },
                ),
                const Spacer(), // 남은 공간을 채워서 로그아웃 버튼을 아래로 밀어냄
              ],
            ),
          ),
          /// 로그아웃 버튼
          Container(
            margin: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: mediumbackgroundBrown.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: cardBrown,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cardBrown,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), // 좌우 마진 추가
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: mediumbackgroundBrown.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: mediumbackgroundBrown,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cardBrown.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: mediumbackgroundBrown,
            letterSpacing: 0.3,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: mediumbackgroundBrown,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.chevron_right,
            color: Colors.white,
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