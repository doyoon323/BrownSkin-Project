import 'package:flutter/material.dart';
import '../login/login_page.dart';
import 'package:brownskin_app/common/themes.dart';

class SignUpCompletePage extends StatefulWidget {
  const SignUpCompletePage({super.key});

  @override
  State<SignUpCompletePage> createState() => _SignUpCompletePageState();
}

class _SignUpCompletePageState extends State<SignUpCompletePage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // 애니메이션 시작
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundBrown,
              AppColors.accentBrown.withOpacity(0.3),
              AppColors.backgroundBrown,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 장식적 요소들
                _buildDecorativeElements(),
                
                const SizedBox(height: 40),
                
                // 성공 아이콘
                _buildSuccessIcon(),
                
                const SizedBox(height: 32),
                
                // 메인 메시지
                _buildMainMessage(),
                
                const SizedBox(height: 16),
                
                // 서브 메시지
                _buildSubMessage(),
                
                const SizedBox(height: 48),
                
                // 시작하기 버튼
                _buildStartButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeElements() {
    return Stack(
      children: [
        // 배경 원들
        Positioned(
          top: -20,
          left: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBrown.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          top: 20,
          right: -30,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentBrown.withOpacity(0.2),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          left: 50,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightBrown.withOpacity(0.15),
            ),
          ),
        ),
        // 빈 컨테이너 (공간 확보용)
        Container(height: 120),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBrown,
                  AppColors.darkBrown,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBrown.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        '회원가입이 완료되었습니다',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBrown,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accentBrown.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '이제 로그인하여 브라운스킨의\n다양한 서비스를 이용해보세요',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.primaryBrown.withOpacity(0.8),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [AppColors.primaryBrown, AppColors.darkBrown],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBrown.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.login,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '로그인하고 시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
