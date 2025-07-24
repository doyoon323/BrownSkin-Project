import 'package:brownskin_app/common/mypage/profile.dart';
import 'package:flutter/material.dart';

import '../../pages/login/login_page.dart';
import 'announcement.dart';
import 'policy.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('분리/배출', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    const Text('홍길동', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),

                /// 우측: 정보수정 버튼
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0))
                  ),
                  child: const Text('정보수정', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          Divider(height: 24, thickness: 7,color: Colors.grey[300]),

          /// 메뉴 리스트
          ListTile(
            title: const Text('공지사항', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NoticeListPage()),
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

          /// 로그아웃
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>  LoginPage()),
                  );
                },
                child: const Text('로그아웃', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}