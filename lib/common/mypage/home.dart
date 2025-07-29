import 'package:brownskin_app/common/api_service.dart';
import 'package:brownskin_app/common/constants.dart';
import 'package:brownskin_app/common/mypage/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/login/login_page.dart';
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
    if (response.isEmpty){
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          /// 상단 프로필 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// 좌측 사용자 정보
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(Icons.person, size: 40, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userInfo['company_name'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${userInfo['addr1'] ?? ''} ${userInfo['addr2'] ?? ''}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "${getRoleString(userInfo['role'] ?? '')} ${userInfo['type'] ?? ''}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                /// 우측 정보수정 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(Info: userInfo, token: widget.token),
                      ),
                    ).then((isUpdated) {
                      if (isUpdated == true) {
                        _fetchUserInfo();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: const Text('정보수정', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          Divider(height: 24, thickness: 7, color: Colors.grey[300]),

          ListTile(
            title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NoticeListPage(token: widget.token),),
              );
            },
          ),
          ListTile(
            title: const Text('약관 및 정책', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PolicyListPage()),
              );
            },
          ),

          const Spacer(),


          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              },
              child: const Text('로그아웃', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}